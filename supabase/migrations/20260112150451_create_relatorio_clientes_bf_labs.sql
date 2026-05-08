create table if not exists relatorio_clientes_bf_labs (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  id_conta_meta text unique,
  id_conta_google text unique,
  telefone text,
  enviar_relatorio_meta boolean default false,
  checar_saldo_meta boolean default false,
  valor_base text,
  ultimo_envio_diario_saldo text,
  saldo_atual_meta text,
  enviar_relatorio_google boolean default false,
  ultimo_envio_diario_google text,
  tipo_pagamento text check (tipo_pagamento in ('Boleto', 'Cartão')),
  status text check (status in ('Ativo', 'Inativo')),
  created_at timestamp with time zone default now()
);

alter table relatorio_clientes_bf_labs enable row level security;

create policy "Enable read access for authenticated users"
on relatorio_clientes_bf_labs
for select
to authenticated
using (true);

create policy "Enable insert for authenticated users"
on relatorio_clientes_bf_labs
for insert
to authenticated
with check (true);

create policy "Enable update for authenticated users"
on relatorio_clientes_bf_labs
for update
to authenticated
using (true);;
