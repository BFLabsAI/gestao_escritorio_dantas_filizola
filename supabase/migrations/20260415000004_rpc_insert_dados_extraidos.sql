-- Função RPC para inserir dados extraídos (bypassa RLS via SECURITY DEFINER)
CREATE OR REPLACE FUNCTION insert_dados_extraidos(
  p_processo_id UUID,
  p_cliente_id UUID,
  p_documento_origem_id UUID,
  p_tipo_documento_origem TEXT,
  p_campos JSONB -- array de objetos: [{"campo":"nome","valor":"João","confianca":0.9}]
) RETURNS JSON AS $$
DECLARE
  inserted_count INTEGER := 0;
  campo_rec RECORD;
BEGIN
  -- Deletar dados anteriores deste documento
  DELETE FROM dados_extraidos_gestao_escritorio_filizola
  WHERE documento_origem_id = p_documento_origem_id;

  -- Inserir novos dados
  FOR campo_rec IN SELECT * FROM jsonb_array_elements(p_campos)
  LOOP
    INSERT INTO dados_extraidos_gestao_escritorio_filizola (
      processo_id, cliente_id, documento_origem_id,
      tipo_documento_origem, campo, valor, confianca, status
    ) VALUES (
      p_processo_id,
      p_cliente_id,
      p_documento_origem_id,
      p_tipo_documento_origem,
      campo_rec.value->>'campo',
      campo_rec.value->>'valor',
      (campo_rec.value->>'confianca')::NUMERIC(3,2),
      'extraido'
    );
    inserted_count := inserted_count + 1;
  END LOOP;

  RETURN json_build_object('success', true, 'inserted_count', inserted_count);
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object('success', false, 'error', SQLERRM, 'sqlstate', SQLSTATE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
