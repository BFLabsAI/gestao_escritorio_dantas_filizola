-- Create table for job-specific questions
CREATE TABLE perguntas_vagas_banco_talentos_execut (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Question information
    vaga_id UUID REFERENCES vagas_banco_talentos_execut(id) ON DELETE CASCADE,
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT NOT NULL,
    
    -- Question type and configuration
    tipo_pergunta VARCHAR(50) NOT NULL, -- texto_curto, texto_longo, email, telefone, url, select, checkbox, radio, file, monetary
    obrigatorio BOOLEAN DEFAULT false,
    ordem INTEGER DEFAULT 0,
    
    -- For select/multiple choice questions
    opcoes JSONB, -- Array of options for select/checkbox/radio
    placeholder VARCHAR(500),
    mascara VARCHAR(100), -- For phone, monetary fields
    
    -- Conditional logic
    pergunta_condicional UUID REFERENCES perguntas_vagas_banco_talentos_execut(id),
    condicao_resposta TEXT, -- What answer triggers this question
    
    -- Validation rules
    validacao_min_length INTEGER,
    validacao_max_length INTEGER,
    validacao_regex VARCHAR(255),
    
    -- Metadata
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create indexes
CREATE INDEX idx_perguntas_vaga ON perguntas_vagas_banco_talentos_execut(vaga_id);
CREATE INDEX idx_perguntas_ordem ON perguntas_vagas_banco_talentos_execut(vaga_id, ordem);
CREATE INDEX idx_perguntas_condicional ON perguntas_vagas_banco_talentos_execut(pergunta_condicional);

-- Add RLS policies
ALTER TABLE perguntas_vagas_banco_talentos_execut ENABLE ROW LEVEL SECURITY;;
