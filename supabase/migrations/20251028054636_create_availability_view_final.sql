-- View principal para substituir vw_slots_disponiveis_agenda_inteligente_orus (INEXISTENTE)
CREATE VIEW vw_slots_disponiveis_agenda_inteligente_orus AS
SELECT 
  d.id as disponibilidade_id,
  d.profissional_id,
  d.data_especifica,
  d.hora_inicio,
  d.hora_fim,
  p.nome_completo as profissional_nome,
  p.apelido as profissional_apelido,
  p.category_description as profissional_categoria,
  p.cor_identificacao as profissional_cor,
  p.ativo as profissional_ativo,
  o.id as consultorio_id,
  o.name as consultorio_nome,
  o.ativo as consultorio_ativo,
  -- Lógica para verificar se profissional está livre nesse horário
  CASE 
    WHEN NOT EXISTS (
      SELECT 1 FROM appointments_agenda_inteligente_orus a
      WHERE a.professional_id = d.profissional_id
        AND a.date = d.data_especifica
        AND a.status NOT IN ('cancelado_paciente', 'cancelado_clinica')
        AND (
          (a.start_time <= d.hora_inicio AND a.end_time > d.hora_inicio) OR
          (a.start_time < d.hora_fim AND a.end_time >= d.hora_fim) OR
          (a.start_time >= d.hora_inicio AND a.end_time <= d.hora_fim)
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
FROM disponibilidades_agenda_inteligente_orus d
JOIN profissionais_agenda_inteligente_orus p ON d.profissional_id = p.id
LEFT JOIN offices_agenda_inteligente_orus o ON o.ativo = true
WHERE d.ativo = true;

-- Adicionar comentários
COMMENT ON VIEW vw_slots_disponiveis_agenda_inteligente_orus IS 'View consolidada de slots disponíveis para agendamento';
COMMENT ON COLUMN vw_slots_disponiveis_agenda_inteligente_orus.horario_livre_profissional IS 'Indica se o profissional está livre neste horário';
COMMENT ON COLUMN vw_slots_disponiveis_agenda_inteligente_orus.consultorio_livre IS 'Indica se existe consultório disponível';;
