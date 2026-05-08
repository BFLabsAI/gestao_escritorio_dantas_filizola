CREATE OR REPLACE FUNCTION process_queue_bf_tickets()
RETURNS TRIGGER AS $$
DECLARE
  queue_record RECORD;
  contact_id UUID;
  group_id UUID;
  ticket_id UUID;
  normalized_phone TEXT;
  remote_jid TEXT;
BEGIN
  -- Obter registro da fila
  SELECT * INTO queue_record 
  FROM message_queue_bf_tickets 
  WHERE id = NEW.id;
  
  -- Extrair remoteJid do payload
  remote_jid := queue_record.payload->>'key'->>'remoteJid';
  
  -- Verificar se é mensagem de grupo (termina com @g.us)
  IF remote_jid LIKE '%@g.us' THEN
    -- Cenário Grupo: buscar grupo configurado
    SELECT id INTO group_id
    FROM groups_bf_tickets
    WHERE group_id_wa = remote_jid;
    
    -- Se grupo não encontrado ou não tem tags, ignorar
    IF group_id IS NULL THEN
      UPDATE message_queue_bf_tickets
      SET status = 'ignorado'
      WHERE id = NEW.id;
      RETURN NEW;
    END IF;
    
    -- Verificar se grupo tem tags (não é nulo e não está vazio)
    IF NOT EXISTS (
      SELECT 1 FROM groups_bf_tickets 
      WHERE id = group_id 
      AND tags IS NOT NULL 
      AND array_length(tags, 1) > 0
    ) THEN
      UPDATE message_queue_bf_tickets
      SET status = 'ignorado'
      WHERE id = NEW.id;
      RETURN NEW;
    END IF;
    
  ELSE
    -- Cenário Pessoal: normalizar telefone
    normalized_phone := REGEXP_REPLACE(
      remote_jid, 
      '[^0-9]', 
      '', 
      'g'
    );
    
    -- Remover sufixos (@s.whatsapp.net, @lid)
    normalized_phone := REGEXP_REPLACE(
      normalized_phone, 
      '(s\.whatsapp\.net|lid)$', 
      '', 
      'g'
    );
    
    -- Adicionar 55 se não tiver e tiver 11 dígitos (Brasil)
    IF normalized_phone NOT LIKE '55%' AND length(normalized_phone) = 11 THEN
      normalized_phone := '55' || normalized_phone;
    END IF;
    
    -- Buscar ou criar contato
    SELECT id INTO contact_id
    FROM leads_bf_tickets
    WHERE phone = normalized_phone;
    
    IF contact_id IS NULL THEN
      INSERT INTO leads_bf_tickets (phone, name, company)
      VALUES (
        normalized_phone,
        COALESCE(queue_record.payload->>'pushName', 'Contato WhatsApp'),
        NULL
      )
      RETURNING id INTO contact_id;
    END IF;
  END IF;
  
  -- Inserir mensagem
  INSERT INTO messages_bf_tickets (
    contact_id,
    group_id,
    direction,
    content,
    media_url,
    media_type,
    timestamp
  ) VALUES (
    contact_id,
    group_id,
    CASE 
      WHEN queue_record.payload->>'key'->>'fromMe' = 'true' THEN 'outbound'
      ELSE 'inbound'
    END,
    COALESCE(queue_record.payload->>'message', ''),
    NULL, -- TODO: Processar mídia se houver
    NULL, -- TODO: Determinar tipo de mídia
    CASE 
      WHEN queue_record.payload->>'messageTimestamp' IS NOT NULL THEN
        to_timestamp(CAST(queue_record.payload->>'messageTimestamp' AS BIGINT))
      ELSE
        NOW()
    END
  );
  
  -- Buscar ou criar ticket
  IF group_id IS NOT NULL THEN
    -- Ticket de grupo
    SELECT id INTO ticket_id
    FROM tickets_bf_tickets
    WHERE group_id = group_id 
    AND source_type = 'group'
    AND status != 'Resolvido';
    
    IF ticket_id IS NULL THEN
      INSERT INTO tickets_bf_tickets (
        status,
        source_type,
        contact_id,
        group_id,
        last_message_at
      ) VALUES (
        'Aberto',
        'group',
        contact_id,
        group_id,
        NOW()
      )
      RETURNING id INTO ticket_id;
    ELSE
      UPDATE tickets_bf_tickets
      SET last_message_at = NOW()
      WHERE id = ticket_id;
    END IF;
  ELSE
    -- Ticket pessoal
    SELECT id INTO ticket_id
    FROM tickets_bf_tickets
    WHERE contact_id = contact_id 
    AND source_type = 'personal'
    AND status != 'Resolvido';
    
    IF ticket_id IS NULL THEN
      INSERT INTO tickets_bf_tickets (
        status,
        source_type,
        contact_id,
        group_id,
        last_message_at
      ) VALUES (
        'Aberto',
        'personal',
        contact_id,
        NULL,
        NOW()
      )
      RETURNING id INTO ticket_id;
    ELSE
      UPDATE tickets_bf_tickets
      SET last_message_at = NOW()
      WHERE id = ticket_id;
    END IF;
  END IF;
  
  -- Marcar como processado
  UPDATE message_queue_bf_tickets
  SET 
    status = 'processado',
    processed_at = NOW()
  WHERE id = NEW.id;
  
  RETURN NEW;
  
EXCEPTION WHEN OTHERS THEN
  -- Em caso de erro, registrar e marcar como erro
  UPDATE message_queue_bf_tickets
  SET 
    status = 'erro',
    processed_at = NOW(),
    error_log = SQLERRM
  WHERE id = NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;;
