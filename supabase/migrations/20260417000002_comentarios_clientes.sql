-- Tabela de comentários por cliente
CREATE TABLE IF NOT EXISTS comentarios_clientes_gestao_escritorio_filizola (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cliente_id UUID NOT NULL REFERENCES clientes_gestao_escritorio_filizola(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    conteudo TEXT NOT NULL,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_comentarios_cliente ON comentarios_clientes_gestao_escritorio_filizola(cliente_id);
CREATE INDEX IF NOT EXISTS idx_comentarios_criado_em ON comentarios_clientes_gestao_escritorio_filizola(criado_em DESC);

-- RLS
ALTER TABLE comentarios_clientes_gestao_escritorio_filizola ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated pode ver comentarios"
    ON comentarios_clientes_gestao_escritorio_filizola FOR SELECT
    TO authenticated USING (true);

CREATE POLICY "Authenticated pode inserir comentarios"
    ON comentarios_clientes_gestao_escritorio_filizola FOR INSERT
    TO authenticated WITH CHECK (true);

CREATE POLICY "Authenticated pode atualizar comentarios"
    ON comentarios_clientes_gestao_escritorio_filizola FOR UPDATE
    TO authenticated USING (true);

CREATE POLICY "Authenticated pode deletar comentarios"
    ON comentarios_clientes_gestao_escritorio_filizola FOR DELETE
    TO authenticated USING (true);
