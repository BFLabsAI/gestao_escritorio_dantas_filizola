-- Fase 0.1: Adicionar coluna status_lead em leads_rastreialead
ALTER TABLE leads_rastreialead 
ADD COLUMN status_lead text NOT NULL DEFAULT 'pendente';

-- Constraint para valores válidos
ALTER TABLE leads_rastreialead
ADD CONSTRAINT status_lead_check 
CHECK (
  status_lead IN (
    'pendente',
    'em_andamento',
    'reuniao_agendada',
    'ganho',
    'perdido',
    'abandonado'
  )
);

-- Atualizar registros existentes baseado no histórico de mensagens
UPDATE leads_rastreialead
SET status_lead = CASE
  WHEN EXISTS (
    SELECT 1 
    FROM mensagens_rastreialead m
    WHERE '55' || regexp_replace(leads_rastreialead.telefone, '[^0-9]', '', 'g') || '@s.whatsapp.net' = m.remote_jid
      AND m.from_me = true
  )
  THEN 'em_andamento'
  ELSE 'pendente'
END;

-- Fase 0.2: Criar tabela cadencias_dias_rastreialead
CREATE TABLE cadencias_dias_rastreialead (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cadencia_id uuid NOT NULL REFERENCES cadencias_rastreialead(id) ON DELETE CASCADE,
  dia_numero integer NOT NULL,
  tentativas_esperadas integer NOT NULL,
  descricao text,
  created_at timestamp DEFAULT now(),
  
  CONSTRAINT unique_cadencia_dia UNIQUE(cadencia_id, dia_numero),
  CONSTRAINT dia_numero_positivo CHECK (dia_numero > 0),
  CONSTRAINT tentativas_positivas CHECK (tentativas_esperadas > 0)
);

-- Índice para performance
CREATE INDEX idx_cadencias_dias_cadencia_id 
  ON cadencias_dias_rastreialead(cadencia_id);

-- Fase 0.3: Popular dados das cadências existentes
-- Cadência "4d4x" (4 dias, 4 tentativas por dia)
INSERT INTO cadencias_dias_rastreialead (cadencia_id, dia_numero, tentativas_esperadas, descricao)
SELECT 
  id,
  dia,
  4,
  'Dia ' || dia || ' - 4 tentativas'
FROM cadencias_rastreialead
CROSS JOIN generate_series(1, 4) AS dia
WHERE nome = '4d4x';

-- Cadência "Padrão Comercial" (7 dias, 3 tentativas por dia)
INSERT INTO cadencias_dias_rastreialead (cadencia_id, dia_numero, tentativas_esperadas, descricao)
SELECT 
  id,
  dia,
  3,
  'Dia ' || dia || ' - 3 tentativas'
FROM cadencias_rastreialead
CROSS JOIN generate_series(1, 7) AS dia
WHERE nome = 'Padrão Comercial';

-- Popular automaticamente para outras cadências baseado em dias_total e tentativas_por_dia
INSERT INTO cadencias_dias_rastreialead (cadencia_id, dia_numero, tentativas_esperadas, descricao)
SELECT 
  c.id,
  dia,
  c.tentativas_por_dia,
  'Dia ' || dia || ' - ' || c.tentativas_por_dia || ' tentativas'
FROM cadencias_rastreialead c
CROSS JOIN generate_series(1, c.dias_total) AS dia
WHERE c.nome NOT IN ('4d4x', 'Padrão Comercial')
ON CONFLICT (cadencia_id, dia_numero) DO NOTHING;;
