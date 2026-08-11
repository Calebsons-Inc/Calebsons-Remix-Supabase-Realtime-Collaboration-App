-- Enable Postgres changes for live document + membership updates.

alter table public.spaces replica identity full;
alter table public.memberships replica identity full;

do $$
begin
  begin
    alter publication supabase_realtime add table public.spaces;
  exception
    when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime add table public.memberships;
  exception
    when duplicate_object then null;
  end;
end $$;
