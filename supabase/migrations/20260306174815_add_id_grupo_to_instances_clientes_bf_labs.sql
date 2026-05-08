
-- Adicionar coluna id_grupo na tabela instances_clientes_bf_labs
ALTER TABLE instances_clientes_bf_labs 
ADD COLUMN IF NOT EXISTS id_grupo TEXT;

-- Adicionar comentário para documentação
COMMENT ON COLUMN instances_clientes_bf_labs.id_grupo IS 'ID do grupo WhatsApp do cliente (formato: 120363362888514288@g.us) para enviar alertas de desconexão';
;
