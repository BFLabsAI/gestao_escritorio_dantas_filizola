-- Corrigir RLS: permitir acesso anon durante MVP (sem login)
-- Drop das politicas antigas que so permitem authenticated
DROP POLICY IF EXISTS "Authenticated pode ver comentarios" ON public.comentarios_clientes_gestao_escritorio_filizola;
DROP POLICY IF EXISTS "Authenticated pode inserir comentarios" ON public.comentarios_clientes_gestao_escritorio_filizola;
DROP POLICY IF EXISTS "Authenticated pode atualizar comentarios" ON public.comentarios_clientes_gestao_escritorio_filizola;
DROP POLICY IF EXISTS "Authenticated pode deletar comentarios" ON public.comentarios_clientes_gestao_escritorio_filizola;

-- Politica unica permitindo tudo para anon e authenticated (MVP)
CREATE POLICY "Permitir tudo comentarios_clientes MVP"
    ON public.comentarios_clientes_gestao_escritorio_filizola
    FOR ALL
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);
