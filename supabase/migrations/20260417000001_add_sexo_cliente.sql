-- Adicionar campo sexo ao cadastro de cliente
ALTER TABLE public.clientes_gestao_escritorio_filizola
ADD COLUMN IF NOT EXISTS sexo TEXT NOT NULL DEFAULT 'nao_informado'
CHECK (sexo IN ('masculino', 'feminino', 'nao_informado'));
