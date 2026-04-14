-- =============================================
-- Migration: Adicionar UPDATE policy no storage
-- =============================================

create policy "Usuarios autenticados podem atualizar peticoes geradas"
on storage.objects for update
to authenticated
using (bucket_id = 'peticoes_geradas' and auth.role() = 'authenticated')
with check (bucket_id = 'peticoes_geradas' and auth.role() = 'authenticated');
