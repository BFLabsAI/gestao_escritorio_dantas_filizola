-- Remover FK de auth.users no usuario_id para funcionar no MVP (sem login)
-- Tabela comentarios_clientes
ALTER TABLE public.comentarios_clientes_gestao_escritorio_filizola
DROP CONSTRAINT IF EXISTS comentarios_clientes_gestao_escritorio_filizola_usuario_id_fkey;

ALTER TABLE public.comentarios_clientes_gestao_escritorio_filizola
ALTER COLUMN usuario_id TYPE TEXT USING usuario_id::TEXT;

-- Tabela comentarios_processos ja esta como TEXT, apenas garantir
ALTER TABLE public.comentarios_processos_gestao_escritorio_filizola
ALTER COLUMN usuario_id TYPE TEXT USING usuario_id::TEXT;
