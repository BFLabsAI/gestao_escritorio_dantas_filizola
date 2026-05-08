-- Corrigir problema com to_char
CREATE OR REPLACE FUNCTION verificar_disponibilidade_horario_flexivel_agenda_inteligente_orus(
  p_profissional_id UUID,
  p_data DATE,
  p_hora_inicio TIME,
  p_duracao_minutos INTEGER
)
RETURNS JSON AS $$
DECLARE
  profissional_disponivel BOOLEAN;
  consultorios_disponiveis JSON;
  conflitos_encontrados JSON;
  v_hora_fim TIME;
  v_inicio_minutos INTEGER;
  v_fim_minutos INTEGER;
  v_profissional_info JSON;
  v_dia_semana TEXT;
BEGIN
  -- Calcular hora final
  v_hora_fim := (p_hora_inicio + (p_duracao_minutos || ' minutes')::INTERVAL)::TIME;
  v_inicio_minutos := (EXTRACT(HOUR FROM p_hora_inicio) * 60 + EXTRACT(MINUTE FROM p_hora_inicio));
  v_fim_minutos := (EXTRACT(HOUR FROM v_hora_fim) * 60 + EXTRACT(MINUTE FROM v_hora_fim));
  
  -- Buscar dia da semana
  v_dia_semana := CASE 
    WHEN EXTRACT(ISODOW FROM p_data) = 1 THEN 'Segunda'
    WHEN EXTRACT(ISODOW FROM p_data) = 2 THEN 'Terça'
    WHEN EXTRACT(ISODOW FROM p_data) = 3 THEN 'Quarta'
    WHEN EXTRACT(ISODOW FROM p_data) = 4 THEN 'Quinta'
    WHEN EXTRACT(ISODOW FROM p_data) = 5 THEN 'Sexta'
    WHEN EXTRACT(ISODOW FROM p_data) = 6 THEN 'Sábado'
    WHEN EXTRACT(ISODOW FROM p_data) = 7 THEN 'Domingo'
    ELSE 'Desconhecido'
  END;
  
  -- Buscar informações do profissional
  SELECT json_build_object(
    'nome', apelido,
    'categoria', category_description,
    'cor', cor_identificacao
  )
  INTO v_profissional_info
  FROM profissionais_agenda_inteligente_orus
  WHERE id = p_profissional_id AND ativo = true;
  
  -- 1. Verificar se está dentro do período de disponibilidade
  SELECT EXISTS(
    SELECT 1 FROM vw_profissional_disponibilidade_flexivel_agenda_inteligente_orus v
    WHERE v.profissional_id = p_profissional_id
      AND v.data_especifica = p_data
      AND v.inicio_minutos <= v_inicio_minutos
      AND v.fim_minutos >= v_fim_minutos
      AND v.profissional_ativo = true
  ) INTO profissional_disponivel;
  
  -- 2. Verificar conflitos com agendamentos existentes
  SELECT json_agg(
    json_build_object(
      'start_time', a.start_time,
      'end_time', a.end_time,
      'status', a.status,
      'patient_name', COALESCE(l.name, 'Paciente'),
      'procedure_name', proc.nome
    )
  )
  INTO conflitos_encontrados
  FROM appointments_agenda_inteligente_orus a
  LEFT JOIN (
    SELECT id, name FROM leads_agenda_inteligente_orus WHERE status = 'convertido'
  ) l ON a.patient_id = l.id
  LEFT JOIN procedimentos_agenda_inteligente_orus proc ON a.procedure_id = proc.id
  WHERE a.professional_id = p_profissional_id
    AND a.date = p_data
    AND a.status NOT IN ('cancelado_paciente', 'cancelado_clinica')
    AND (
      -- Verificar overlap (lógica robusta)
      (a.start_time <= p_hora_inicio AND a.end_time > p_hora_inicio) OR
      (a.start_time < v_hora_fim AND a.end_time >= v_hora_fim) OR
      (a.start_time >= p_hora_inicio AND a.end_time <= v_hora_fim)
    );
  
  -- 3. Buscar consultórios disponíveis
  SELECT json_agg(
    json_build_object(
      'id', o.id, 
      'name', o.name,
      'description', o.description
    )
  )
  INTO consultorios_disponiveis
  FROM offices_agenda_inteligente_orus o
  WHERE o.ativo = true;
  
  RETURN json_build_object(
    'disponivel', profissional_disponivel AND conflitos_encontrados IS NULL,
    'profissional_disponivel', profissional_disponivel,
    'tem_conflitos', conflitos_encontrados IS NOT NULL,
    'conflitos', conflitos_encontrados,
    'consultorios_disponiveis', consultorios_disponiveis,
    'profissional', v_profissional_info,
    'hora_inicio', p_hora_inicio,
    'hora_fim', v_hora_fim,
    'duracao_minutos', p_duracao_minutos,
    'inicio_minutos', v_inicio_minutos,
    'fim_minutos', v_fim_minutos,
    'dia_semana', v_dia_semana
  );
END;
$$ LANGUAGE plpgsql;;
