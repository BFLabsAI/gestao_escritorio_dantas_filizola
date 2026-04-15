-- Permitir que anon leia dados extraídos (necessário para o app funcionar)
CREATE POLICY "Anon pode ver dados extraídos"
    ON dados_extraidos_gestao_escritorio_filizola
    FOR SELECT TO anon
    USING (true);
