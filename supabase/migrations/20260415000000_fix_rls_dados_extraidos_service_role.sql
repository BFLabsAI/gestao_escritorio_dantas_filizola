-- Corrigir RLS: permitir que service_role (edge functions) operem na tabela
CREATE POLICY "Service role pode gerenciar dados extraídos"
    ON dados_extraidos_gestao_escritorio_filizola
    FOR ALL TO service_role
    USING (true)
    WITH CHECK (true);
