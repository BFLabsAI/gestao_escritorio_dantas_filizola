-- =============================================
-- Migration: RLS + Storage para peticoes_geradas
-- =============================================

-- 1. Desabilitar RLS na tabela de petições geradas
alter table public.peticoes_geradas_gestao_escritorio_filizola disable row level security;

-- 2. Criar bucket dedicado para petições geradas (se não existir)
insert into storage.buckets (id, name, public, file_size_limit)
values ('peticoes_geradas', 'peticoes_geradas', false, 52428800)
on conflict (id) do nothing;

-- 3. Políticas de storage para o bucket de petições geradas
create policy "Usuarios autenticados podem upload de peticoes geradas"
on storage.objects for insert
to authenticated
with check (bucket_id = 'peticoes_geradas' and auth.role() = 'authenticated');

create policy "Usuarios autenticados podem atualizar peticoes geradas"
on storage.objects for update
to authenticated
using (bucket_id = 'peticoes_geradas' and auth.role() = 'authenticated')
with check (bucket_id = 'peticoes_geradas' and auth.role() = 'authenticated');

create policy "Usuarios autenticados podem baixar peticoes geradas"
on storage.objects for select
to authenticated
using (bucket_id = 'peticoes_geradas' and auth.role() = 'authenticated');

create policy "Usuarios autenticados podem deletar peticoes geradas"
on storage.objects for delete
to authenticated
using (bucket_id = 'peticoes_geradas' and auth.role() = 'authenticated');
