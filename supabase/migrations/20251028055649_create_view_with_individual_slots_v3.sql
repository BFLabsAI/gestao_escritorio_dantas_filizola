-- Criar view com slots individuais de 30 minutos
CREATE VIEW vw_slots_disponiveis_agenda_inteligente_orus AS
WITH generate_slots AS (
  -- Gerar todos os slots de 30 minutos dentro dos períodos de disponibilidade
  SELECT 
    d.profissional_id,
    d.data_especifica,
    -- Converter para timestamp para usar generate_series
    generate_series(
      (d.data_especifica || ' ' || d.hora_inicio)::timestamp,
      (d.data_especifica || ' ' || d.hora_fim)::timestamp - interval '30 minutes',
      interval '30 minutes'
    ) as slot_timestamp,
    d.id as disponibilidade_id
  FROM disponibilidades_agenda_inteligente_orus d
  WHERE d.ativo = true
)
SELECT 
  gs.disponibilidade_id,
  gs.profissional_id,
  gs.data_especifica,
  gs.slot_timestamp::time as hora_inicio,
  (gs.slot_timestamp + interval '30 minutes')::time as hora_fim,
  p.nome_completo as profissional_nome,
  p.apelido as profissional_apelido,
  p.category_description as profissional_categoria,
  p.cor_identificacao as profissional_cor,
  p.ativo as profissional_ativo,
  o.id as consultorio_id,
  o.name as consultorio_nome,
  o.ativo as consultorio_ativo,
  -- Lógica para verificar se profissional está livre neste slot específico
  CASE 
    WHEN NOT EXISTS (
      SELECT 1 FROM appointments_agenda_inteligente_orus a
      WHERE a.professional_id = gs.profissional_id
        AND a.date = gs.data_especifica
        AND a.status NOT IN ('cancelado_paciente', 'cancelado_clinica')
        AND (
          -- Verificar overlap com appointments existentes
          (a.start_time <= gs.slot_timestamp::time AND a.end_time > gs.slot_timestamp::time) OR
          (a.start_time < (gs.slot_timestamp + interval '30 minutes')::time AND a.end_time >= (gs.slot_timestamp + interval '30 minutes')::time) OR
          (a.start_time >= gs.slot_timestamp::time AND a.end_time <= (gs.slot_timestamp + interval '30 minutes')::time)
        )
    )
    THEN true 
    ELSE false 
  END as horario_livre_profissional,
  -- Lógica para verificar se existe consultório disponível
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM offices_agenda_inteligente_orus o2
      WHERE o2.ativo = true
      LIMIT 1
    )
    THEN true 
    ELSE false 
  END as consultorio_livre
FROM generate_slots gs
JOIN profissionais_agenda_inteligente_orus p ON gs.profissional_id = p.id
LEFT JOIN offices_agenda_inteligente_orus o ON o.ativo = true
WHERE p.ativo = true;

-- Adicionar comentários
COMMENT ON VIEW vw_slots_disponiveis_agenda_inteligente_orus IS 'View com slots individuais de 30 minutos gerados automaticamente';;
