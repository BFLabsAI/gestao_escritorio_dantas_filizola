-- Popular tabela vendedores_rastreia_prospect com dados das instâncias
-- Cada vendedor terá uma instância com nome contendo '_R7_TREINAMENTOS_COMERCIAL'

INSERT INTO vendedores_rastreia_prospect (nome, whatsapp, status)
SELECT 
  CASE 
    WHEN name LIKE '%_R7_TREINAMENTOS_COMERCIAL%' THEN 
      REPLACE(REPLACE(name, '_R7_TREINAMENTOS_COMERCIAL', ''), '_', ' ')
    ELSE name
  END as nome,
  number as whatsapp,
  CASE 
    WHEN connection_status = 'open' THEN 'Ativo'
    ELSE 'Inativo'
  END as status
FROM instancias_rastreialead
WHERE name LIKE '%_R7_TREINAMENTOS_COMERCIAL%'
ON CONFLICT DO NOTHING;

-- Verificar se os dados foram inseridos
SELECT * FROM vendedores_rastreia_prospect;;
