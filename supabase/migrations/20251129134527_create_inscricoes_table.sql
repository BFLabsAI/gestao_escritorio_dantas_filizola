-- Create inscricoes table to manage applications
DROP TABLE IF EXISTS inscricoes_banco_talentos_execut CASCADE;

CREATE TABLE inscricoes_banco_talentos_execut (
    id SERIAL PRIMARY KEY,
    vaga_id INTEGER REFERENCES vagas_banco_talentos_execut(id) ON DELETE CASCADE,
    candidato_id INTEGER REFERENCES candidatos_banco_talentos_execut(id) ON DELETE CASCADE,
    
    -- Respostas às perguntas específicas da vaga (JSON)
    respostas_especificas JSONB, -- Respostas dinâmicas baseadas nas perguntas da vaga
    
    -- Portfólio/projetos (para vagas de design, tech, etc)
    portfolio_tipo VARCHAR(20), -- 'arquivo' ou 'link'
    portfolio_url VARCHAR(500),
    portfolio_arquivo_path VARCHAR(500),
    
    -- Status da inscrição
    status_inscricao VARCHAR(20) DEFAULT 'recebida', -- 'recebida', 'em_analise', 'entrevista', 'aprovado', 'reprovado', 'desistente'
    feedback TEXT,
    
    -- Pontuação (se houver sistema de pontos)
    pontuacao_total INTEGER DEFAULT 0,
    
    -- Controle
    data_inscricao TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Prevent duplicate applications
    UNIQUE(vaga_id, candidato_id)
);

-- Create indexes
CREATE INDEX idx_inscricoes_vaga ON inscricoes_banco_talentos_execut(vaga_id);
CREATE INDEX idx_inscricoes_candidato ON inscricoes_banco_talentos_execut(candidato_id);
CREATE INDEX idx_inscricoes_status ON inscricoes_banco_talentos_execut(status_inscricao);
CREATE INDEX idx_inscricoes_data ON inscricoes_banco_talentos_execut(data_inscricao);;
