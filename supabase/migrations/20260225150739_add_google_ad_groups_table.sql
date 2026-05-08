
-- Criar tabela de dimensão de Ad Groups
CREATE TABLE IF NOT EXISTS relatorio_google_dim_ad_groups (
    id BIGSERIAL PRIMARY KEY,
    cliente_id UUID NOT NULL REFERENCES relatorio_clientes_bf_labs(id) ON DELETE CASCADE,
    campaign_id BIGINT NOT NULL REFERENCES relatorio_google_dim_campaigns(id) ON DELETE CASCADE,
    google_ad_group_id VARCHAR(50),
    ad_group_name VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'ENABLED',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(cliente_id, google_ad_group_id)
);

-- Adicionar coluna ad_group_id na tabela de keywords
ALTER TABLE relatorio_google_dim_keywords 
ADD COLUMN IF NOT EXISTS ad_group_id BIGINT REFERENCES relatorio_google_dim_ad_groups(id) ON DELETE SET NULL;

-- Adicionar coluna ad_group_id na tabela de fatos
ALTER TABLE relatorio_google_fact_search_term_performance 
ADD COLUMN IF NOT EXISTS ad_group_id BIGINT REFERENCES relatorio_google_dim_ad_groups(id) ON DELETE SET NULL;

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_dim_ad_groups_cliente_id ON relatorio_google_dim_ad_groups(cliente_id);
CREATE INDEX IF NOT EXISTS idx_dim_ad_groups_campaign_id ON relatorio_google_dim_ad_groups(campaign_id);
CREATE INDEX IF NOT EXISTS idx_dim_keywords_ad_group_id ON relatorio_google_dim_keywords(ad_group_id);
CREATE INDEX IF NOT EXISTS idx_fact_ad_group_id ON relatorio_google_fact_search_term_performance(ad_group_id);

-- Comentários nas tabelas
COMMENT ON TABLE relatorio_google_dim_ad_groups IS 'Dimensão de Grupos de Anúncios do Google Ads';
COMMENT ON COLUMN relatorio_google_dim_ad_groups.google_ad_group_id IS 'ID do ad group no Google Ads';
COMMENT ON COLUMN relatorio_google_dim_ad_groups.ad_group_name IS 'Nome do grupo de anúncios';
;
