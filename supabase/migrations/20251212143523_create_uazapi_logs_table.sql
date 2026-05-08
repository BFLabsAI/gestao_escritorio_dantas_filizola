create table if not exists uazapi_logs_audita_lead (
  id uuid default gen_random_uuid() primary key,
  tenant_id uuid references tenants_audita_lead(id) on delete cascade not null,
  instance_id uuid references instances_audita_lead(id) on delete set null,
  action text not null,
  request_payload jsonb,
  response_payload jsonb,
  status_code integer,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table uazapi_logs_audita_lead enable row level security;

create policy "Users can view logs for their tenant"
  on uazapi_logs_audita_lead for select
  using (
    exists (
      select 1 from user_tenants_audita_lead
      where user_tenants_audita_lead.tenant_id = uazapi_logs_audita_lead.tenant_id
      and user_tenants_audita_lead.user_id = auth.uid()
    )
    or
    exists (
      select 1 from users_audita_lead
      where users_audita_lead.auth_user_id = auth.uid()
      and users_audita_lead.role = 'superadmin'
    )
  );

-- Allow the service role (Edge Functions) to insert logs
create policy "Service role can insert logs"
  on uazapi_logs_audita_lead for insert
  with check (true);
;
