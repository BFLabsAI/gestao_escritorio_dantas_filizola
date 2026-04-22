-- Adiciona coluna ativo na tabela de clientes
ALTER TABLE public.clientes_gestao_escritorio_filizola
ADD COLUMN ativo boolean NOT NULL DEFAULT true;

-- Comentário na coluna
COMMENT ON COLUMN public.clientes_gestao_escritorio_filizola.ativo IS 'Status do cliente (true = ativo, false = inativo)';
