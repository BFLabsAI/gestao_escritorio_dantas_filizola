-- Popular tabela vendedores_rastreia_prospect com dados das instâncias
-- Cada vendedor terá uma instância com nome contendo '_R7_TREINAMENTOS_COMERCIAL' ou 'R7_TREINAMENTOS'

INSERT INTO vendedores_rastreia_prospect (nome, whatsapp, status)
SELECT 
  CASE 
    WHEN name LIKE '%_comercial_r7%' THEN 
      REPLACE(REPLACE(name, '_comercial_r7', ''), '_', ' ')
    WHEN name LIKE '%_R7_TREINAMENTOS%' THEN 
      REPLACE(REPLACE(name, '_R7_TREINAMENTOS', ''), '_', ' ')
    ELSE name
  END as nome,
  REPLACE(owner_jid, '@s.whatsapp.net', '') as whatsapp,
  CASE 
    WHEN connection_status = 'open' THEN 'Ativo'
    ELSE 'Inativo'
  END as status
FROM instancias_rastreialead
WHERE name LIKE '%_comercial_r7%' OR name LIKE '%_R7_TREINAMENTOS%'
ON CONFLICT DO NOTHING;

-- Verificar se os dados foram inseridos
SELECT * FROM vendedores_rastreia_prospect;;
