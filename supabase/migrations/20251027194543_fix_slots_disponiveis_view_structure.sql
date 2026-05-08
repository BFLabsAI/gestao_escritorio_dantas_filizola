-- Primeiro, remover a view existente
DROP VIEW IF EXISTS vw_slots_disponiveis_agenda_inteligente_orus;

-- Recriar a view com a estrutura exata que o frontend precisa
CREATE OR REPLACE VIEW vw_slots_disponiveis_agenda_inteligente_orus AS
WITH 
-- Gera slots de 30 minutos para cada profissional disponível no dia
slots_profissionais AS (
    SELECT 
        d.id as disponibilidade_id,
        d.profissional_id,
        d.data_especifica,
        -- Converte para timestamp para usar generate_series
        (d.data_especifica || ' ' || d.hora_inicio)::timestamp as slot_timestamp_inicio,
        (d.data_especifica || ' ' || COALESCE(d.hora_fim::text, 
            CASE 
                WHEN d.hora_inicio::time < '12:00:00' THEN '12:00:00'::text
                WHEN d.hora_inicio::time < '18:00:00' THEN '18:00:00'::text
                ELSE '20:00:00'::text
            END))::timestamp as slot_timestamp_fim
    FROM disponibilidades_agenda_inteligente_orus d
    WHERE d.ativo = true
      AND d.data_especifica >= CURRENT_DATE
      AND d.hora_inicio IS NOT NULL
),

-- Expande os slots em intervalos de 30 minutos
slots_expandidos AS (
    SELECT 
        sp.disponibilidade_id,
        sp.profissional_id,
        sp.data_especifica,
        sp.slot_timestamp_inicio,
        sp.slot_timestamp_fim,
        -- Gera série de 30 em 30 minutos
        generate_series(
            sp.slot_timestamp_inicio,
            sp.slot_timestamp_fim - interval '30 minutes',
            interval '30 minutes'
        ) as hora_slot
    FROM slots_profissionais sp
),

-- Formata os horários
slots_formatados AS (
    SELECT 
        se.disponibilidade_id,
        se.profissional_id,
        se.data_especifica,
        se.hora_slot::time as hora_inicio,
        (se.hora_slot + interval '30 minutes')::time as hora_fim
    FROM slots_expandidos se
),

-- Verifica conflitos com agendamentos existentes
conflitos_existentes AS (
    SELECT 
        a.professional_id,
        a.date as data_especifica,
        a.start_time as hora_inicio,
        a.end_time as hora_fim,
        -- Tenta usar consultorio_id primeiro, depois office_id
        COALESCE(a.consultorio_id, a.office_id) as appointment_consultorio_id
    FROM appointments_agenda_inteligente_orus a
    WHERE a.status NOT IN ('cancelado_paciente', 'cancelado_clinica')
      AND a.date >= CURRENT_DATE
),

-- Combina slots com profissionais e verifica disponibilidade
slots_com_profissionais AS (
    SELECT 
        sf.disponibilidade_id,
        sf.profissional_id,
        sf.data_especifica,
        sf.hora_inicio,
        sf.hora_fim,
        p.nome_completo,
        p.apelido,
        p.cor_identificacao,
        p.clinicorp_id,
        p.ativo as profissional_ativo,
        p.category_description,
        -- Flag para indicar se profissional está livre neste slot
        NOT EXISTS (
            SELECT 1 
            FROM conflitos_existentes ce
            WHERE ce.professional_id = sf.profissional_id
              AND ce.data_especifica = sf.data_especifica
              AND (
                  -- Verifica sobreposição de horários
                  (ce.hora_inicio < sf.hora_fim AND ce.hora_fim > sf.hora_inicio)
              )
        ) as horario_livre_profissional
    FROM slots_formatados sf
    INNER JOIN profissionais_agenda_inteligente_orus p ON p.id = sf.profissional_id
)

-- Query final com junção com consultórios
SELECT 
    scp.disponibilidade_id,
    scp.profissional_id,
    scp.data_especifica,
    scp.hora_inicio,
    scp.hora_fim,
    scp.nome_completo,
    scp.apelido,
    scp.cor_identificacao,
    scp.clinicorp_id,
    scp.profissional_ativo,
    scp.horario_livre_profissional,
    scp.category_description as especialidade,
    
    -- Adiciona todos os consultórios ativos via CROSS JOIN
    o.id as consultorio_id,
    o.name as consultorio_nome,
    o.ativo as consultorio_ativo,
    
    -- Verifica se consultório está livre neste horário
    NOT EXISTS (
        SELECT 1 
        FROM conflitos_existentes ce
        WHERE ce.appointment_consultorio_id = o.id
          AND ce.data_especifica = scp.data_especifica
          AND (
              -- Verifica sobreposição de horários
              (ce.hora_inicio < scp.hora_fim AND ce.hora_fim > scp.hora_inicio)
          )
    ) as consultorio_livre,
    
    -- Mapeamentos para compatibilidade com frontend
    scp.hora_inicio as slot_inicio,  -- Para compatibilidade
    scp.hora_fim as slot_fim,       -- Para compatibilidade
    scp.nome_completo as profissional_nome,  -- Mapeamento: nome_completo -> profissional_nome
    scp.apelido as profissional_apelido,     -- Mapeamento: apelido -> profissional_apelido
    
    -- Coluna de disponibilidade geral
    (scp.horario_livre_profissional AND o.ativo AND scp.profissional_ativo AND 
     NOT EXISTS (
        SELECT 1 
        FROM conflitos_existentes ce
        WHERE ce.appointment_consultorio_id = o.id
          AND ce.data_especifica = scp.data_especifica
          AND (ce.hora_inicio < scp.hora_fim AND ce.hora_fim > scp.hora_inicio)
     )) as disponivel,
    
    -- Determina o turno com base no horário
    CASE 
        WHEN scp.hora_inicio < '12:00:00' THEN 'manhã'
        WHEN scp.hora_inicio < '18:00:00' THEN 'tarde'
        ELSE 'noite'
    END as turno
    
FROM slots_com_profissionais scp
CROSS JOIN offices_agenda_inteligente_orus o

-- Filtra apenas combinações que estão realmente disponíveis
WHERE scp.horario_livre_profissional = true
  AND o.ativo = true
  AND scp.profissional_ativo = true
  AND NOT EXISTS (
    SELECT 1 
    FROM conflitos_existentes ce
    WHERE ce.appointment_consultorio_id = o.id
      AND ce.data_especifica = scp.data_especifica
      AND (ce.hora_inicio < scp.hora_fim AND ce.hora_fim > scp.hora_inicio)
  );

-- Adicionar comentários para documentação
COMMENT ON VIEW vw_slots_disponiveis_agenda_inteligente_orus IS 'View consolidada de slots disponíveis para agendamento. Gera slots de 30min e verifica disponibilidade de profissionais e consultórios, considerando conflitos com agendamentos existentes.';;
