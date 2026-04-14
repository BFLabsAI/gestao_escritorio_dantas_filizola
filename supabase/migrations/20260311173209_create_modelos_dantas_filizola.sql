create extension if not exists pgcrypto;

do $$
begin
  create type public.categoria_modelo_dantas_filizola as enum (
    'documentos',
    'contratos',
    'peticoes'
  );
exception
  when duplicate_object then null;
end $$;

insert into storage.buckets (id, name, public)
values ('modelos_dantas_filizola', 'modelos_dantas_filizola', true)
on conflict (id) do update
set public = excluded.public;

create table if not exists public.modelos_dantas_filizola (
  id uuid primary key default gen_random_uuid(),
  categoria public.categoria_modelo_dantas_filizola not null,
  nome_arquivo text not null,
  nome_original text not null,
  bucket_name text not null default 'modelos_dantas_filizola',
  storage_path text not null unique,
  public_url text not null,
  mime_type text,
  tamanho_bytes bigint,
  extensao text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.modelos_dantas_filizola disable row level security;

create index if not exists modelos_dantas_filizola_categoria_idx
  on public.modelos_dantas_filizola (categoria, created_at desc);

create or replace function public.touch_modelos_dantas_filizola_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_touch_modelos_dantas_filizola_updated_at
  on public.modelos_dantas_filizola;

create trigger trg_touch_modelos_dantas_filizola_updated_at
before update on public.modelos_dantas_filizola
for each row execute function public.touch_modelos_dantas_filizola_updated_at();;
