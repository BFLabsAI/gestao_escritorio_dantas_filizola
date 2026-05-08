-- Índices avançados para performance otimizada

-- Índice composto para filtros combinados
CREATE INDEX idx_disparador_dashboard_filters 
ON disparador_r7_treinamentos (created_at DESC, instancia, tipo_envio, nome_campanha);

-- Índice para coluna usaria (IA)
CREATE INDEX idx_disparador_usaria_created_at 
ON disparador_r7_treinamentos (usaria, created_at DESC);;
