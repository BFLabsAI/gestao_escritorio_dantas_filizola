CREATE OR REPLACE FUNCTION verificar_disponibilidade_horario_flexivel_agenda_inteligente_orus(
  p_profissional_id UUID,
  p_data DATE,
  p_hora_inicio TIME,
  p_duracao_minutos INTEGER
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSON;
  v_profissional_disponivel BOOLEAN := false;
  v_tem_conflitos BOOLEAN := false;
  v_hora_fim TIME;
  v_conflitos JSON := '[]'::JSON;
BEGIN
  -- Calcular hora final
  v_hora_fim := (p_hora_inicio + (p_duracao_minutos || ' minutes')::INTERVAL)::TIME;
  
  -- 1. Verificar se profissional está disponível no horário
  SELECT COUNT(*) > 0 INTO v_profissional_disponivel
  FROM disponibilidades_agenda_inteligente_orus
  WHERE profissional_id = p_profissional_id
    AND data_especifica = p_data
    AND ativo = true
    AND (
      (hora_inicio IS NULL AND hora_fim IS NULL) -- Disponível o dia todo
      OR (hora_inicio <= p_hora_inicio AND hora_fim >= v_hora_fim) -- Contém o período completo
      OR (hora_inicio <= p_hora_inicio AND (hora_inicio + INTERVAL '1 hour') > p_hora_inicio) -- Começa antes e cobre início
      OR (hora_fim >= v_hora_fim AND (hora_fim - INTERVAL '1 hour') < v_hora_fim) -- Termina depois e cobre fim
    );
  
  -- 2. Verificar conflitos com agendamentos existentes
  SELECT COUNT(*) > 0 INTO v_tem_conflitos
  FROM appointments_agenda_inteligente_orus
  WHERE professional_id = p_profissional_id
    AND date = p_data
    AND status NOT IN ('cancelado_paciente', 'cancelado_clinica')
    AND (
      -- Conflito se: (A.início < B.fim) AND (A.fim > B.início)
      (p_hora_inicio < end_time) AND (v_hora_fim > start_time)
    );
  
  -- 3. Buscar detalhes dos conflitos se existirem
  IF v_tem_conflitos THEN
    SELECT json_agg(
      json_build_object(
        'appointment_id', id,
        'start_time', start_time,
        'end_time', end_time,
        'status', status
      )
    ) INTO v_conflitos
    FROM appointments_agenda_inteligente_orus
    WHERE professional_id = p_profissional_id
      AND date = p_data
      AND status NOT IN ('cancelado_paciente', 'cancelado_clinica')
      AND (
        (p_hora_inicio < end_time) AND (v_hora_fim > start_time)
      );
  END IF;
  
  -- Construir resultado
  v_result := json_build_object(
    'disponivel', v_profissional_disponivel AND NOT v_tem_conflitos,
    'profissional_disponivel', v_profissional_disponivel,
    'tem_conflitos', v_tem_conflitos,
    'conflitos', v_conflitos,
    'periodo_solicitado', json_build_object(
      'data', p_data,
      'hora_inicio', p_hora_inicio,
      'hora_fim', v_hora_fim,
      'duracao_minutos', p_duracao_minutos
    )
  );
  
  RETURN v_result;
END;
$$;;
