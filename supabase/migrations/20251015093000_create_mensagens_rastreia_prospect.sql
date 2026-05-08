-- Migration: Criar tabela de mensagens do WhatsApp
-- Descrição: Armazena todas as mensagens do WhatsApp incluindo mídia
-- Timestamp: 2025-10-15

-- Criar tabela principal de mensagens
CREATE TABLE IF NOT EXISTS mensagens_rastreia_prospect (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Relacionamento
  lead_id UUID NOT NULL REFERENCES leads_rastreia_prospect(id) ON DELETE CASCADE,

  -- Informações da instância
  instance_name VARCHAR(100) NOT NULL,
  remote_jid VARCHAR(50) NOT NULL,
  telefone_normalizado VARCHAR(20) NOT NULL,

  -- Direção e conteúdo
  from_me BOOLEAN NOT NULL DEFAULT false,
  message_text TEXT,

  -- Informações de mídia
  message_type VARCHAR(50), -- conversation, imageMessage, videoMessage, audioMessage, documentMessage, extendedTextMessage, contactMessage, locationMessage, etc.
  media_type VARCHAR(20), -- image, video, audio, document
  media_caption TEXT,
  media_filename VARCHAR(255),
  media_mimetype VARCHAR(100),
  media_filesize BIGINT,
  media_url TEXT,
  media_base64 TEXT,
  media_thumbnail TEXT,

  -- Metadados
  message_timestamp BIGINT NOT NULL,
  message_date TIMESTAMP WITH TIME ZONE NOT NULL,
  status VARCHAR(50) DEFAULT 'DELIVERY_ACK',
  push_name VARCHAR(100),
  webhook_data JSONB,

  -- Controle e validação
  processed BOOLEAN DEFAULT false,
  touchpoint_id UUID REFERENCES execucoes_touchpoints_rastreia_prospect(id),
  touchpoint_realizado BOOLEAN DEFAULT false,

  -- Auditoria
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_mensagens_rastreia_prospect_lead_id ON mensagens_rastreia_prospect(lead_id);
CREATE INDEX IF NOT EXISTS idx_mensagens_rastreia_prospect_telefone ON mensagens_rastreia_prospect(telefone_normalizado);
CREATE INDEX IF NOT EXISTS idx_mensagens_rastreia_prospect_message_date ON mensagens_rastreia_prospect(message_date DESC);
CREATE INDEX IF NOT EXISTS idx_mensagens_rastreia_prospect_from_me ON mensagens_rastreia_prospect(from_me);
CREATE INDEX IF NOT EXISTS idx_mensagens_rastreia_prospect_instance ON mensagens_rastreia_prospect(instance_name);
CREATE INDEX IF NOT EXISTS idx_mensagens_rastreia_prospect_touchpoint_id ON mensagens_rastreia_prospect(touchpoint_id);
-- Adicionar comments para documentação
COMMENT ON TABLE mensagens_rastreia_prospect IS 'Armazena todas as mensagens do Evolution API com mídia, texto e metadados';
COMMENT ON COLUMN mensagens_rastreia_prospect.lead_id IS 'Referência ao lead que enviou/recebeu a mensagem';
COMMENT ON COLUMN mensagens_rastreia_prospect.instance_name IS 'Nome da instância do Evolution API';
COMMENT ON COLUMN mensagens_rastreia_prospect.remote_jid IS 'ID completo do WhatsApp (inclui @s.whatsapp.net)';
COMMENT ON COLUMN mensagens_rastreia_prospect.telefone_normalizado IS 'Telefone formatado (DDD + número)';
COMMENT ON COLUMN mensagens_rastreia_prospect.from_me IS 'True se mensagem foi enviada pelo vendedor';
COMMENT ON COLUMN mensagens_rastreia_prospect.message_text IS 'Conteúdo textual da mensagem';
COMMENT ON COLUMN mensagens_rastreia_prospect.message_type IS 'Tipo da mensagem no Evolution API';
COMMENT ON COLUMN mensagens_rastreia_prospect.media_type IS 'Tipo de mídia: image, video, audio, document';
COMMENT ON COLUMN mensagens_rastreia_prospect.media_caption IS 'Legenda/descrição da mídia';
COMMENT ON COLUMN mensagens_rastreia_prospect.media_filename IS 'Nome do arquivo de mídia';
COMMENT ON COLUMN mensagens_rastreia_prospect.media_mimetype IS 'MIME type do arquivo';
COMMENT ON COLUMN mensagens_rastreia_prospect.media_filesize IS 'Tamanho do arquivo em bytes';
COMMENT ON COLUMN mensagens_rastreia_prospect.media_url IS 'URL do arquivo (se disponível)';
COMMENT ON mensagens_rastreia_prospect.media_base64 IS 'Conteúdo em base64 para armazenamento local';
COMMENT ON COLUMN mensagens_rastreia_prospect.media_thumbnail IS 'Miniatura em base64 (para imagens/vídeos)';
COMMENT ON COLUMN mensagens_rastreia_prospect.message_timestamp IS 'Timestamp em formato Unix';
COMMENT ON COLUMN mensagens_rastreia_prospect.message_date IS 'Data/hora da mensagem em UTC';
COMMENT ON COLUMN mensagens_rastreia_prospect.status IS 'Status da mensagem (DELIVERY_ACK, READ, etc.)';
COMMENT ON COLUMN mensagens_rastreia_prospect.push_name IS 'Nome do contato no WhatsApp';
COMMENT ON COLUMN mensagens_rastreia_prospect.webhook_data IS 'Dados completos do webhook em formato JSON';
COMMENT ON COLUMN mensagens_rastreia_prospect.processed IS 'Indica se a mensagem foi processada';
COMMENT ON COLUMN mensagens_rastreia_prospect.touchpoint_id IS 'ID do touchpoint relacionado (se aplicável)';
COMMENT ON COLUMN mensagens_rastreia_prospect.touchpoint_realizado IS 'Indica se esta mensagem realizou um touchpoint';
