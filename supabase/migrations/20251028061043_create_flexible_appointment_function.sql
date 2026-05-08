-- Function para criar agendamento com verificação automática
CREATE OR REPLACE FUNCTION criar_agendamento_flexivel_agenda_inteligente_orus(
  p_profissional_id UUID,
  p_patient_id UUID,
  p_procedure_id UUID,
  p_office_id UUID,
  p_date DATE,
  p_start_time TIME,
  p_channel TEXT DEFAULT 'web',
  p_notes TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_procedimento RECORD;
  v_duracao_minutos INTEGER;
  v_disponibilidade JSON;
  v_end_time TIME;
  v_appointment_id UUID;
  v_result JSON;
BEGIN
  -- 1. Buscar dados do procedimento
  SELECT * INTO v_procedimento
  FROM procedimentos_agenda_inteligente_orus
  WHERE id = p_procedure_id AND ativo = true;
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false, 
      'error', 'Procedimento não encontrado ou inativo',
      'procedure_id', p_procedure_id
    );
  END IF;
  
  v_duracao_minutos := COALESCE(v_procedimento.duracao_minutos, 30);
  
  -- 2. Verificar disponibilidade
  v_disponibilidade := verificar_disponibilidade_horario_flexivel_agenda_inteligente_orus(
    p_profissional_id,
    p_date,
    p_start_time,
    v_duracao_minutos
  );
  
  IF NOT (v_disponibilidade->>'disponivel')::BOOLEAN THEN
    RETURN json_build_object(
      'success', false, 
      'error', 'Horário não disponível',
      'motivo', CASE 
        WHEN NOT (v_disponibilidade->>'profissional_disponivel')::BOOLEAN 
          THEN 'Profissional não está disponível neste horário'
        WHEN (v_disponibilidade->>'tem_conflitos')::BOOLEAN
          THEN 'Já existe agendamento neste período'
        ELSE 'Horário fora do período de disponibilidade'
      END,
      'disponibilidade', v_disponibilidade,
      'requested_time', p_start_time,
      'duration_minutes', v_duracao_minutos
    );
  END IF;
  
  -- 3. Calcular hora final
  v_end_time := (p_start_time + (v_duracao_minutos || ' minutes')::INTERVAL)::TIME;
  
  -- 4. Criar agendamento
  INSERT INTO appointments_agenda_inteligente_orus (
    professional_id,
    patient_id,
    procedure_id,
    office_id,
    date,
    start_time,
    end_time,
    status,
    channel,
    notes,
    created_at
  )
  VALUES (
    p_profissional_id,
    p_patient_id,
    p_procedure_id,
    p_office_id,
    p_date,
    p_start_time,
    v_end_time,
    'agendado',
    p_channel,
    p_notes,
    NOW()
  )
  RETURNING id INTO v_appointment_id;
  
  -- 5. Buscar dados completos do agendamento criado
  SELECT json_build_object(
    'success', true,
    'appointment_id', v_appointment_id,
    'procedure_nome', v_procedimento.nome,
    'duracao_minutos', v_duracao_minutos,
    'preco', v_procedimento.price_list_name,
    'horario', p_start_time || ' - ' || v_end_time,
    'data', p_date,
    'paciente_id', p_patient_id,
    'profissional_id', p_profissional_id,
    'consultorio_id', p_office_id,
    'canal', p_channel,
    'status', 'agendado'
  )
  INTO v_result;
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Adicionar comentário
COMMENT ON FUNCTION criar_agendamento_flexivel_agenda_inteligente_orus IS 'Cria agendamento com verificação automática de disponibilidade e duração variável';;
