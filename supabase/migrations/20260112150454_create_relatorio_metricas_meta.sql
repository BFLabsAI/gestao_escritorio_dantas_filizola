create table if not exists relatorio_metricas_meta (
  id bigint generated always as identity primary key,
  created_at timestamp with time zone default now(),
  cliente_id uuid references relatorio_clientes_bf_labs(id) on delete cascade,
  data_referencia date,
  investimento numeric,
  cliques text,
  conversas text,
  leads text,
  total_page_engagements text,
  total_post_engagements text,
  total_video_views text,
  campanhas_ativas jsonb,
  analise_ia text,
  dados_brutos jsonb
);

alter table relatorio_metricas_meta enable row level security;

create policy "Enable read access for authenticated users"
on relatorio_metricas_meta
for select
to authenticated
using (true);

create policy "Enable insert for authenticated users"
on relatorio_metricas_meta
for insert
to authenticated
with check (true);;
