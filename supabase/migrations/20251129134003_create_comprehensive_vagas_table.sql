-- Create comprehensive vagas table with all necessary fields
CREATE TABLE vagas_banco_talentos_execut (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Basic job information
    titulo_vaga VARCHAR(255) NOT NULL,
    codigo_vaga VARCHAR(50) UNIQUE, -- e.g., "VEND-001", "MKT-002"
    
    -- Department relationship
    setor_id INTEGER REFERENCES setores_banco_talentos_execut(id),
    
    -- Detailed job description
    descricao_responsabilidades TEXT, -- What the person will do
    descricao_requisitos TEXT, -- Required qualifications
    descricao_diferenciais TEXT, -- Nice-to-have qualifications
    descricao_beneficios TEXT, -- Company benefits
    
    -- Compensation and logistics
    salario_min DECIMAL(12,2),
    salario_max DECIMAL(12,2),
    faixa_salarial VARCHAR(100), -- e.g., "R$ 3.000 - R$ 5.000",
    tipo_contrato VARCHAR(50) DEFAULT 'CLT',
    modalidade_trabalho VARCHAR(50) DEFAULT 'Híbrido', -- Remoto, Híbrido, Presencial
    localizacao VARCHAR(255),
    
    -- Status and metadata
    status VARCHAR(50) DEFAULT 'aberta', -- aberta, pausada, fechada
    prioridade VARCHAR(20) DEFAULT 'normal', -- baixa, normal, alta, urgente
    data_limite DATE, -- Application deadline
    
    -- Application settings
    aceita_portfolio BOOLEAN DEFAULT false,
    portifolio_obrigatorio BOOLEAN DEFAULT false,
    tempo_experiencia_minima INTEGER DEFAULT 0, -- in months
    
    -- Social media content
    descricao_redes_sociais TEXT, -- Pre-formatted content for social media
    hashtags_padrao TEXT[], -- Default hashtags for social media
    
    -- Metadata
    criado_por VARCHAR(255),
    atualizado_por VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create index for search performance
CREATE INDEX idx_vagas_titulo ON vagas_banco_talentos_execut(titulo_vaga);
CREATE INDEX idx_vagas_setor ON vagas_banco_talentos_execut(setor_id);
CREATE INDEX idx_vagas_status ON vagas_banco_talentos_execut(status);

-- Add RLS policies
ALTER TABLE vagas_banco_talentos_execut ENABLE ROW LEVEL SECURITY;;
