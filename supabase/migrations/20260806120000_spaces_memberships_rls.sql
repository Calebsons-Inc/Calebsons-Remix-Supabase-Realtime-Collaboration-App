-- Week 1 Day 3 baseline: spaces + memberships + RLS
-- Applied automatically by `npm run supabase:start` / `npm run db:reset`

create extension if not exists "pgcrypto";

create table if not exists public.spaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  document_body text not null default '',
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.memberships (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references public.spaces (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in ('Owner', 'Editor', 'Viewer')),
  created_at timestamptz not null default now(),
  unique (space_id, user_id)
);

create index if not exists memberships_user_id_idx on public.memberships (user_id);
create index if not exists memberships_space_id_idx on public.memberships (space_id);

alter table public.spaces enable row level security;
alter table public.memberships enable row level security;

-- SECURITY DEFINER helpers avoid infinite recursion when policies
-- need to inspect memberships while memberships RLS is active.
create or replace function public.is_space_member(check_space_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.memberships
    where space_id = check_space_id
      and user_id = auth.uid()
  );
$$;

create or replace function public.is_space_editor(check_space_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.memberships
    where space_id = check_space_id
      and user_id = auth.uid()
      and role in ('Owner', 'Editor')
  );
$$;

create or replace function public.is_space_owner(check_space_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.memberships
    where space_id = check_space_id
      and user_id = auth.uid()
      and role = 'Owner'
  );
$$;

grant execute on function public.is_space_member(uuid) to authenticated;
grant execute on function public.is_space_editor(uuid) to authenticated;
grant execute on function public.is_space_owner(uuid) to authenticated;

create policy "Members can select spaces"
  on public.spaces
  for select
  to authenticated
  using (
    created_by = auth.uid()
    or public.is_space_member(id)
  );

create policy "Authenticated users can insert spaces"
  on public.spaces
  for insert
  to authenticated
  with check (auth.uid() = created_by);

create policy "Owners and Editors can update spaces"
  on public.spaces
  for update
  to authenticated
  using (public.is_space_editor(id))
  with check (public.is_space_editor(id));

create policy "Members can select memberships"
  on public.memberships
  for select
  to authenticated
  using (public.is_space_member(space_id));

create policy "Owners can insert memberships"
  on public.memberships
  for insert
  to authenticated
  with check (
    public.is_space_owner(space_id)
    or user_id = auth.uid()
  );

create policy "Owners can update memberships"
  on public.memberships
  for update
  to authenticated
  using (public.is_space_owner(space_id));

create policy "Owners can delete memberships"
  on public.memberships
  for delete
  to authenticated
  using (public.is_space_owner(space_id));
