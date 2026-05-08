
-- Adicionar coluna para link de conexao
ALTER TABLE instances_clientes_bf_labs 
ADD COLUMN IF NOT EXISTS link_conexao TEXT;

-- Adicionar comentarioário
COMMENT ON COLUMN instances_clientes_bf_labs.link_conexao IS 'Link direto para conectar a instância no painel Rastreia Lead';
;
