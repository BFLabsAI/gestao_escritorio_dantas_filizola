-- Índices principais para performance do dashboard

-- Índice principal para ordenação por data
CREATE INDEX idx_disparador_created_at_desc 
ON disparador_r7_treinamentos (created_at DESC);

-- Índices compostos para filtros comuns
CREATE INDEX idx_disparador_instancia_created_at 
ON disparador_r7_treinamentos (instancia, created_at DESC);

CREATE INDEX idx_disparador_tipo_envio_created_at 
ON disparador_r7_treinamentos (tipo_envio, created_at DESC);

CREATE INDEX idx_disparador_campaign_created_at 
ON disparador_r7_treinamentos (nome_campanha, created_at DESC);;
