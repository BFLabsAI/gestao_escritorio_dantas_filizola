-- Adicionar coluna webhook_url à tabela de instâncias
ALTER TABLE instancias_rastreialead ADD COLUMN IF NOT EXISTS webhook_url TEXT;

-- Adicionar comentário
COMMENT ON COLUMN instancias_rastreialead.webhook_url IS 'URL do webhook configurado para esta instância da Evolution API';;
