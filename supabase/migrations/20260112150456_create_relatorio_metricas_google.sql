create table if not exists relatorio_metricas_google (
  id bigint generated always as identity primary key,
  created_at timestamp with time zone default now(),
  cliente_id uuid references relatorio_clientes_bf_labs(id) on delete cascade,
  data_referencia date,
  investimento numeric,
  cliques text,
  impressoes text,
  conversoes text,
  share_impressao text,
  perda_ranking text,
  perda_orcamento text,
  campanhas_ativas jsonb,
  termos_pesquisa jsonb,
  analise_ia text,
  dados_brutos jsonb
);

alter table relatorio_metricas_google enable row level security;

create policy "Enable read access for authenticated users"
on relatorio_metricas_google
for select
to authenticated
using (true);

create policy "Enable insert for authenticated users"
on relatorio_metricas_google
for insert
to authenticated
with check (true);;
