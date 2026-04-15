-- =============================================
-- Migration: Remover exigencia de auth nas storage policies
-- =============================================
-- Como o MVP nao tem autenticacao, permitir acesso anonimo ao storage

-- Drop policies antigas que exigem authenticated
drop policy "Usuarios autenticados podem fazer upload de documentos processuais" on storage.objects;
drop policy "Usuarios autenticados podem baixar documentos processuais" on storage.objects;
drop policy "Usuarios autenticados podem deletar documentos processuais" on storage.objects;

-- Recriar sem exigencia de authenticated (anon tem acesso)
create policy "Upload de documentos processuais"
    on storage.objects
    for insert
    with check (bucket_id = 'documentos_processuais');

create policy "Download de documentos processuais"
    on storage.objects
    for select
    using (bucket_id = 'documentos_processuais');

create policy "Delete de documentos processuais"
    on storage.objects
    for delete
    using (bucket_id = 'documentos_processuais');
