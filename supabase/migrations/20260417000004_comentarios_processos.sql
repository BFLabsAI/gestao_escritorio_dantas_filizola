-- Tabela de comentarios por processo (chat da equipe)
CREATE TABLE IF NOT EXISTS comentarios_processos_gestao_escritorio_filizola (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    processo_id UUID NOT NULL REFERENCES processos_gestao_escritorio_filizola(id) ON DELETE CASCADE,
    usuario_id TEXT NOT NULL,
    conteudo TEXT NOT NULL,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_comentarios_processo ON comentarios_processos_gestao_escritorio_filizola(processo_id);
CREATE INDEX idx_comentarios_processo_criado_em ON comentarios_processos_gestao_escritorio_filizola(criado_em DESC);

-- RLS desabilitado para MVP
ALTER TABLE comentarios_processos_gestao_escritorio_filizola ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Permitir tudo comentarios_processos MVP"
    ON comentarios_processos_gestao_escritorio_filizola FOR ALL
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);
