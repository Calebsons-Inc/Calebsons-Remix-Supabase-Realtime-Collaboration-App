-- Fix infinite recursion in memberships/spaces RLS policies.
-- Policies that query memberships from within memberships (or via spaces→memberships)
-- must use SECURITY DEFINER helpers so the check does not re-enter RLS.

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

drop policy if exists "Members can select spaces" on public.spaces;
drop policy if exists "Owners and Editors can update spaces" on public.spaces;
drop policy if exists "Members can select memberships" on public.memberships;
drop policy if exists "Owners can insert memberships" on public.memberships;
drop policy if exists "Owners can update memberships" on public.memberships;
drop policy if exists "Owners can delete memberships" on public.memberships;

create policy "Members can select spaces"
  on public.spaces
  for select
  to authenticated
  using (
    created_by = auth.uid()
    or public.is_space_member(id)
  );

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
