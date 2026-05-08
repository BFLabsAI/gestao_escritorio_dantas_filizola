create table if not exists public.project_task_attachments_falconcrm (
  id uuid primary key default gen_random_uuid(),
  task_id text not null references public.project_tasks_falconcrm(id) on delete cascade,
  uploaded_by_user_id uuid references public.app_user_falconcrm(id) on delete set null,
  file_name text not null,
  file_path text not null unique,
  file_size bigint,
  mime_type text,
  created_at timestamp with time zone not null default now()
);

create index if not exists idx_project_task_attachments_falconcrm_task_id
  on public.project_task_attachments_falconcrm(task_id);

insert into storage.buckets (id, name, public)
values ('task-attachments-falconcrm', 'task-attachments-falconcrm', true)
on conflict (id) do nothing;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'task_attachments_falconcrm_public_read'
  ) then
    create policy task_attachments_falconcrm_public_read
      on storage.objects
      for select
      to public
      using (bucket_id = 'task-attachments-falconcrm');
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'task_attachments_falconcrm_public_insert'
  ) then
    create policy task_attachments_falconcrm_public_insert
      on storage.objects
      for insert
      to public
      with check (bucket_id = 'task-attachments-falconcrm');
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'task_attachments_falconcrm_public_delete'
  ) then
    create policy task_attachments_falconcrm_public_delete
      on storage.objects
      for delete
      to public
      using (bucket_id = 'task-attachments-falconcrm');
  end if;
end
$$;;
