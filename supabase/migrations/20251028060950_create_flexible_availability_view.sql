-- View para períodos de disponibilidade dos profissionais (sistema flexível)
CREATE OR REPLACE VIEW vw_profissional_disponibilidade_flexivel_agenda_inteligente_orus AS
WITH professional_periods AS (
  SELECT 
    d.profissional_id,
    d.data_especifica,
    d.hora_inicio,
    d.hora_fim,
    -- Converte para minutos do dia para cálculo flexível
    (EXTRACT(HOUR FROM d.hora_inicio) * 60 + EXTRACT(MINUTE FROM d.hora_inicio)) as inicio_minutos,
    (EXTRACT(HOUR FROM d.hora_fim) * 60 + EXTRACT(MINUTE FROM d.hora_fim)) as fim_minutos,
    d.id as disponibilidade_id
  FROM disponibilidades_agenda_inteligente_orus d
  WHERE d.ativo = true
)
SELECT 
  pp.profissional_id,
  pp.data_especifica,
  pp.hora_inicio as periodo_inicio,
  pp.hora_fim as periodo_fim,
  pp.inicio_minutos,
  pp.fim_minutos,
  pp.disponibilidade_id,
  p.nome_completo as profissional_nome,
  p.apelido as profissional_apelido,
  p.category_description as profissional_categoria,
  p.cor_identificacao as profissional_cor,
  p.ativo as profissional_ativo,
  o.id as consultorio_id,
  o.name as consultorio_nome,
  o.description as consultorio_descricao,
  o.ativo as consultorio_ativo
FROM professional_periods pp
JOIN profissionais_agenda_inteligente_orus p ON pp.profissional_id = p.id
LEFT JOIN offices_agenda_inteligente_orus o ON o.ativo = true
WHERE p.ativo = true;

-- Adicionar comentários
COMMENT ON VIEW vw_profissional_disponibilidade_flexivel_agenda_inteligente_orus IS 'View para verificação flexível de disponibilidade com períodos em minutos para cálculo dinâmico';
COMMENT ON COLUMN vw_profissional_disponibilidade_flexivel_agenda_inteligente_orus.inicio_minutos IS 'Início do período em minutos desde 00:00';
COMMENT ON COLUMN vw_profissional_disponibilidade_flexivel_agenda_inteligente_orus.fim_minutos IS 'Fim do período em minutos desde 00:00';;
