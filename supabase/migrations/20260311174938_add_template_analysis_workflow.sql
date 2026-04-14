alter table public.modelos_dantas_filizola
  add column if not exists analysis_status text not null default 'uploaded' check (analysis_status in ('uploaded', 'analyzing', 'review_pending', 'template_generated', 'error')),
  add column if not exists texto_extraido text,
  add column if not exists texto_template text,
  add column if not exists template_storage_path text,
  add column if not exists template_public_url text,
  add column if not exists analise_resumo text,
  add column if not exists instrucoes_gerais text,
  add column if not exists ultima_analise_em timestamptz,
  add column if not exists analysis_model text,
  add column if not exists ultimo_erro text;

create table if not exists public.modelos_dantas_filizola_campos (
  id uuid primary key default gen_random_uuid(),
  modelo_id uuid not null references public.modelos_dantas_filizola(id) on delete cascade,
  field_key text not null,
  label text not null,
  excerpt text not null,
  reasoning text not null,
  placeholder text not null,
  confidence numeric(4,3),
  status text not null default 'suggested' check (status in ('suggested', 'approved', 'rejected')),
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.modelos_dantas_filizola_campos disable row level security;

create index if not exists modelos_dantas_filizola_campos_modelo_idx
  on public.modelos_dantas_filizola_campos (modelo_id, sort_order);

drop trigger if exists trg_touch_modelos_dantas_filizola_campos_updated_at
  on public.modelos_dantas_filizola_campos;

create trigger trg_touch_modelos_dantas_filizola_campos_updated_at
before update on public.modelos_dantas_filizola_campos
for each row execute function public.touch_modelos_dantas_filizola_updated_at();;
