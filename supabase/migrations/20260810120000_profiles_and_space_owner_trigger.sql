-- Week 1: profiles + auto owner membership on space create

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique,
  display_name text not null,
  color text not null default '#0b9f8c',
  initials text not null default '??',
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Profiles are viewable by authenticated users"
  on public.profiles
  for select
  to authenticated
  using (true);

create policy "Users can update their own profile"
  on public.profiles
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  uname text;
  dname text;
  seed int;
  colors text[] := array[
    '#0b9f8c', '#3b6fd9', '#c8841a', '#d45d3a',
    '#2f6f5e', '#5a6fd4', '#b85c38', '#1f7a8c'
  ];
begin
  uname := lower(coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)));
  dname := coalesce(nullif(new.raw_user_meta_data->>'display_name', ''), uname);
  seed := abs(hashtext(uname)) % array_length(colors, 1) + 1;

  insert into public.profiles (id, username, display_name, color, initials)
  values (
    new.id,
    uname,
    dname,
    colors[seed],
    upper(left(dname, 2))
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.handle_new_space()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.memberships (space_id, user_id, role)
  values (new.id, new.created_by, 'Owner')
  on conflict (space_id, user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_space_created on public.spaces;
create trigger on_space_created
  after insert on public.spaces
  for each row
  when (new.created_by is not null)
  execute function public.handle_new_space();

create or replace function public.set_space_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_space_updated on public.spaces;
create trigger on_space_updated
  before update on public.spaces
  for each row execute function public.set_space_updated_at();

-- Help PostgREST join memberships -> profiles
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'memberships_user_id_profiles_fkey'
  ) then
    alter table public.memberships
      add constraint memberships_user_id_profiles_fkey
      foreign key (user_id) references public.profiles (id) on delete cascade;
  end if;
end $$;

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.spaces to authenticated;
grant select, insert, update, delete on public.memberships to authenticated;
grant select, update, insert on public.profiles to authenticated;

create policy "Users can insert their own profile"
  on public.profiles
  for insert
  to authenticated
  with check (auth.uid() = id);
