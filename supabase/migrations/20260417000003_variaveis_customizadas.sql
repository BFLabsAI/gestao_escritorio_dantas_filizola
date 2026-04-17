-- Adicionar coluna de variáveis customizadas aos modelos de petição
ALTER TABLE public.modelos_dantas_filizola
ADD COLUMN IF NOT EXISTS variaveis_customizadas JSONB DEFAULT '[]';
