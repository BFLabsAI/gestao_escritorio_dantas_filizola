-- Corrigir function para evitar ambiguidade
CREATE OR REPLACE FUNCTION categorizar_procedimentos_por_profissional()
RETURNS TABLE(
  profissional_id UUID,
  profissional_nome TEXT,
  procedimento_id UUID,
  procedimento_nome TEXT,
  categoria_profissional TEXT,
  status_vinculo TEXT
) AS $$
DECLARE
  prof_record RECORD;
  proc_record RECORD;
  vinculo_existente BOOLEAN;
BEGIN
  -- Para cada profissional ativo
  FOR prof_record IN 
    SELECT id, nome_completo, apelido, category_description 
    FROM profissionais_agenda_inteligente_orus 
    WHERE ativo = true AND category_description IS NOT NULL
  LOOP
    -- Buscar procedimentos que correspondem à categoria do profissional
    FOR proc_record IN
      SELECT id, nome 
      FROM procedimentos_agenda_inteligente_orus 
      WHERE ativo = true AND nome IS NOT NULL
    LOOP
      -- Verificar se já existe vínculo (usando nomes de coluna explícitos)
      SELECT EXISTS(
        SELECT 1 FROM profissional_procedimento_agenda_inteligente_orus pp 
        WHERE pp.profissional_id = prof_record.id 
          AND pp.procedimento_id = proc_record.id
      ) INTO vinculo_existente;
      
      -- Se não existe, criar vínculo baseado em matching de categoria/nome
      IF NOT vinculo_existente THEN
        -- Lógica de matching: palavras-chave no nome do procedimento
        IF (
          -- Dentista geral / Clínico geral
          (prof_record.category_description ILIKE '%dentista%' OR 
           prof_record.category_description ILIKE '%clínico geral%' OR
           prof_record.category_description ILIKE '%cd%' OR
           prof_record.category_description ILIKE '%cirurgião dentista%') AND
          (proc_record.nome ILIKE '%limpeza%' OR 
           proc_record.nome ILIKE '%restauração%' OR 
           proc_record.nome ILIKE '%extração%' OR
           proc_record.nome ILIKE '%profilaxia%' OR
           proc_record.nome ILIKE '%restaurações%' OR
           proc_record.nome ILIKE '%cárie%' OR
           proc_record.nome ILIKE '%obturação%')
        ) OR (
          -- Ortodontista
          prof_record.category_description ILIKE '%ortodontista%' AND
          (proc_record.nome ILIKE '%aparelho%' OR 
           proc_record.nome ILIKE '%contenção%' OR 
           proc_record.nome ILIKE '%ortodontia%' OR
           proc_record.nome ILIKE '%alinhador%' OR
           proc_record.nome ILIKE '%movimentação dentária%')
        ) OR (
          -- Implantodontista
          prof_record.category_description ILIKE '%implante%' AND
          (proc_record.nome ILIKE '%implante%' OR 
           proc_record.nome ILIKE '%enxerto%' OR
           proc_record.nome ILIKE '%cirurgia implante%')
        ) OR (
          -- Periodontista
          prof_record.category_description ILIKE '%periodont%' AND
          (proc_record.nome ILIKE '%raspagem%' OR 
           proc_record.nome ILIKE '%gengiva%' OR
           proc_record.nome ILIKE '%periodontia%' OR
           proc_record.nome ILIKE '%tratamento gengival%')
        ) OR (
          -- Endodontista
          prof_record.category_description ILIKE '%endodont%' AND
          (proc_record.nome ILIKE '%canal%' OR 
           proc_record.nome ILIKE '%endodontia%' OR
           proc_record.nome ILIKE '%tratamento radicular%')
        ) OR (
          -- Clareamento (vários profissionais podem fazer)
          proc_record.nome ILIKE '%clareamento%' OR 
          proc_record.nome ILIKE '%clareamento dental%'
        ) OR (
          -- Procedimentos gerais (todos profissionais)
          proc_record.nome ILIKE '%avaliação%' OR 
          proc_record.nome ILIKE '%consulta%' OR 
          proc_record.nome ILIKE '%avaliação inicial%' OR
          proc_record.nome ILIKE '%triagem%' OR
          proc_record.nome ILIKE '%primeira consulta%'
        ) OR (
          -- Procedimentos de diagnóstico (todos profissionais)
          proc_record.nome ILIKE '%radiografia%' OR 
          proc_record.nome ILIKE '%rx%' OR
          proc_record.nome ILIKE '%exame%' OR
          proc_record.nome ILIKE '%diagnóstico%'
        ) THEN
          -- Inserir vínculo
          INSERT INTO profissional_procedimento_agenda_inteligente_orus 
          (profissional_id, procedimento_id)
          VALUES (prof_record.id, proc_record.id);
          
          profissional_id := prof_record.id;
          profissional_nome := COALESCE(prof_record.apelido, prof_record.nome_completo, 'Profissional sem nome');
          procedimento_id := proc_record.id;
          procedimento_nome := proc_record.nome;
          categoria_profissional := prof_record.category_description;
          status_vinculo := 'CRIADO';
          
          RETURN NEXT;
        END IF;
      END IF;
    END LOOP;
  END LOOP;
  
  RETURN;
END;
$$ LANGUAGE plpgsql;;
