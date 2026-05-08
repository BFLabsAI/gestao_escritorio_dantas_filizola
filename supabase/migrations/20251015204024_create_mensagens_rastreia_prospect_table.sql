-- Criar tabela de mensagens do WhatsApp com suporte a mídia
CREATE TABLE IF NOT EXISTS mensagens_rastreia_prospect (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instancia_id UUID REFERENCES instancias_rastreialead("instanceId") ON DELETE CASCADE,
    lead_id UUID REFERENCES leads_rastreia_prospect(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (event_type IN ('incoming', 'outgoing')),
    payload JSONB NOT NULL,
    remote_jid TEXT NOT NULL,
    from_me BOOLEAN NOT NULL,
    message_text TEXT,
    message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'video', 'audio', 'document', 'extendedText', 'contact', 'location', 'poll', 'buttons', 'list')),
    received_at TIMESTAMPTZ NOT NULL,
    processed_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_mensagens_rastreia_prospect_lead_id ON mensagens_rastreia_prospect(lead_id);
CREATE INDEX IF NOT EXISTS idx_mensagens_rastreia_prospect_instancia_id ON mensagens_rastreia_prospect(instancia_id);
CREATE INDEX IF NOT EXISTS idx_mensagens_rastreia_prospect_remote_jid ON mensagens_rastreia_prospect(remote_jid);
CREATE INDEX IF NOT EXISTS idx_mensagens_rastreia_prospect_received_at ON mensagens_rastreia_prospect(received_at DESC);
CREATE INDEX IF NOT EXISTS idx_mensagens_rastreia_prospect_from_me ON mensagens_rastreia_prospect(from_me);
CREATE INDEX IF NOT EXISTS idx_mensagens_rastreia_prospect_event_type ON mensagens_rastreia_prospect(event_type);

-- Criar tabela de mídia das mensagens
CREATE TABLE IF NOT EXISTS mensagem_midia_rastreia_prospect (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mensagem_id UUID REFERENCES mensagens_rastreia_prospect(id) ON DELETE CASCADE,
    message_type TEXT NOT NULL CHECK (message_type IN ('image', 'video', 'audio', 'document')),
    base64_content TEXT,
    file_name TEXT,
    file_size INTEGER,
    mime_type TEXT,
    caption TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Criar índices para tabela de mídia
CREATE INDEX IF NOT EXISTS idx_mensagem_midia_rastreia_prospect_mensagem_id ON mensagem_midia_rastreia_prospect(mensagem_id);
CREATE INDEX IF NOT EXISTS idx_mensagem_midia_rastreia_prospect_message_type ON mensagem_midia_rastreia_prospect(message_type);

-- Habilitar RLS
ALTER TABLE mensagens_rastreia_prospect ENABLE ROW LEVEL SECURITY;
ALTER TABLE mensagem_midia_rastreia_prospect ENABLE ROW LEVEL SECURITY;

-- Políticas de RLS (acesso total para usuários autenticados)
CREATE POLICY "Enable all operations for authenticated users" ON mensagens_rastreia_prospect
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all operations for authenticated users" ON mensagem_midia_rastreia_prospect
    FOR ALL USING (auth.role() = 'authenticated');

-- Adicionar comentários
COMMENT ON TABLE mensagens_rastreia_prospect IS 'Tabela de mensagens do WhatsApp para o sistema Rastreia Prospect';
COMMENT ON TABLE mensagem_midia_rastreia_prospect IS 'Tabela de mídia anexada às mensagens do WhatsApp';;
