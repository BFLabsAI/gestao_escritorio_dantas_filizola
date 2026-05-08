create table if not exists leads (
  id bigint generated always as identity primary key,
  created_at timestamp with time zone default now(),
  cliente_id uuid references relatorio_clientes_bf_labs(id) on delete cascade,
  nome text not null,
  telefone text,
  origem text check (origem in ('Google', 'Meta', 'Indicação', 'Outros')),
  status text default 'Novo' check (status in ('Novo', 'Agendado', 'Em Andamento', 'Concluído', 'Perdido')),
  observacao text
);

alter table leads enable row level security;

create policy "Enable read access for authenticated users"
on leads
for select
to authenticated
using (true);

create policy "Enable insert for authenticated users"
on leads
for insert
to authenticated
with check (true);

create policy "Enable update for authenticated users"
on leads
for update
to authenticated
using (true);;
