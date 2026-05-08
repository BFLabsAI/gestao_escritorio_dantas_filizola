-- Create table to store environment variables for Edge Functions
CREATE TABLE IF NOT EXISTS dispara_lead_production_config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default configuration values
INSERT INTO dispara_lead_production_config (key, value, description) VALUES
('DISPARA_LEAD_PRODUCTION_EVOLUTION_API_URL', 'https://your-evolution-api-url.com', 'Evolution API base URL for WhatsApp integration'),
('DISPARA_LEAD_PRODUCTION_EVOLUTION_API_KEY', 'your-evolution-api-key', 'Evolution API instance key'),
('DISPARA_LEAD_PRODUCTION_OPENAI_API_KEY', 'your-openai-api-key', 'OpenAI API key for message optimization'),
('DISPARA_LEAD_PRODUCTION_MAX_RETRIES', '3', 'Maximum retry attempts for failed messages'),
('DISPARA_LEAD_PRODUCTION_RETRY_DELAY', '60', 'Base delay for retry attempts in seconds'),
('DISPARA_LEAD_PRODUCTION_BATCH_SIZE', '10', 'Number of messages to process in each batch')
ON CONFLICT (key) DO NOTHING;

-- Create function to get config value
CREATE OR REPLACE FUNCTION get_dispara_lead_config(config_key TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN value FROM dispara_lead_production_config WHERE key = config_key;
END;
$$ LANGUAGE plpgsql;

-- Grant necessary permissions
GRANT SELECT ON dispara_lead_production_config TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_dispara_lead_config TO authenticated, anon;;
