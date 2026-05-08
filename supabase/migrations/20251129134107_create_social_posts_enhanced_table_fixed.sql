-- Create enhanced social media posts table
CREATE TABLE social_posts_vagas_enhanced_banco_talentos_execut (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Job relationship
    vaga_id UUID REFERENCES vagas_banco_talentos_execut(id) ON DELETE CASCADE,
    
    -- Post content
    plataforma VARCHAR(50) NOT NULL, -- LinkedIn, Instagram, Facebook, Twitter
    tipo_post VARCHAR(50) DEFAULT 'organic', -- organic, promoted, story
    
    -- Content fields
    titulo VARCHAR(255),
    conteudo TEXT NOT NULL,
    hashtags TEXT[],
    
    -- Media content
    imagem_url VARCHAR(1000),
    imagem_prompt TEXT, -- AI prompt for image generation
    video_url VARCHAR(1000),
    
    -- Post configuration
    call_to_action VARCHAR(255),
    link_aplicacao VARCHAR(1000), -- Application link for this post
    
    -- Scheduling
    status VARCHAR(50) DEFAULT 'rascunho', -- rascunho, agendado, publicado, pausado, falha
    data_agendamento TIMESTAMPTZ,
    data_publicacao TIMESTAMPTZ,
    
    -- Performance tracking
    visualizacoes INTEGER DEFAULT 0,
    cliques INTEGER DEFAULT 0,
    compartilhamentos INTEGER DEFAULT 0,
    candidaturas_geradas INTEGER DEFAULT 0,
    
    -- Integration info
    post_id_plataforma VARCHAR(255), -- ID from social media platform
    criado_por VARCHAR(255),
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create indexes
CREATE INDEX idx_social_posts_enhanced_vaga ON social_posts_vagas_enhanced_banco_talentos_execut(vaga_id);
CREATE INDEX idx_social_posts_enhanced_plataforma ON social_posts_vagas_enhanced_banco_talentos_execut(plataforma);
CREATE INDEX idx_social_posts_enhanced_status ON social_posts_vagas_enhanced_banco_talentos_execut(status);
CREATE INDEX idx_social_posts_enhanced_agendamento ON social_posts_vagas_enhanced_banco_talentos_execut(data_agendamento);

-- Add RLS policies
ALTER TABLE social_posts_vagas_enhanced_banco_talentos_execut ENABLE ROW LEVEL SECURITY;;
