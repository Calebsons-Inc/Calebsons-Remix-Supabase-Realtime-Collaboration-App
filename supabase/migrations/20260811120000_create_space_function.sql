-- Allow space creators to see the row they just inserted (INSERT ... RETURNING),
-- and create spaces + owner membership in one SECURITY DEFINER call.

drop policy if exists "Members can select spaces" on public.spaces;

create policy "Members can select spaces"
  on public.spaces
  for select
  to authenticated
  using (
    created_by = auth.uid()
    or public.is_space_member(id)
  );

create or replace function public.create_space(space_name text, doc text default '')
returns public.spaces
language plpgsql
security definer
set search_path = public
as $$
declare
  created public.spaces;
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  if length(trim(space_name)) = 0 then
    raise exception 'Space name is required';
  end if;

  insert into public.spaces (name, document_body, created_by)
  values (trim(space_name), coalesce(doc, ''), uid)
  returning * into created;

  insert into public.memberships (space_id, user_id, role)
  values (created.id, uid, 'Owner')
  on conflict (space_id, user_id) do nothing;

  return created;
end;
$$;

grant execute on function public.create_space(text, text) to authenticated;
