-- =============================================
-- Migration: Remover exigencia de auth no bucket peticoes_geradas
-- =============================================

drop policy "Usuarios autenticados podem upload de peticoes geradas" on storage.objects;
drop policy "Usuarios autenticados podem atualizar peticoes geradas" on storage.objects;
drop policy "Usuarios autenticados podem baixar peticoes geradas" on storage.objects;
drop policy "Usuarios autenticados podem deletar peticoes geradas" on storage.objects;

create policy "Upload de peticoes geradas"
    on storage.objects for insert
    with check (bucket_id = 'peticoes_geradas');

create policy "Update de peticoes geradas"
    on storage.objects for update
    using (bucket_id = 'peticoes_geradas')
    with check (bucket_id = 'peticoes_geradas');

create policy "Download de peticoes geradas"
    on storage.objects for select
    using (bucket_id = 'peticoes_geradas');

create policy "Delete de peticoes geradas"
    on storage.objects for delete
    using (bucket_id = 'peticoes_geradas');
