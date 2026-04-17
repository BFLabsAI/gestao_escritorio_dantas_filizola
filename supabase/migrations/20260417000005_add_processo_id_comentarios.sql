-- Adicionar coluna processo_id na tabela de comentarios de cliente
ALTER TABLE public.comentarios_clientes_gestao_escritorio_filizola
ADD COLUMN IF NOT EXISTS processo_id UUID REFERENCES processos_gestao_escritorio_filizola(id) ON DELETE CASCADE;

CREATE INDEX idx_comentarios_cliente_processo ON comentarios_clientes_gestao_escritorio_filizola(processo_id);
