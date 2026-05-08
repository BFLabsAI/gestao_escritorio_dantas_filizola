
-- Criar tabela de logs para o cron de monitoramento de instâncias
CREATE TABLE IF NOT EXISTS cron_monitor_instancias_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    total_verificadas INTEGER DEFAULT 0,
    total_desconectadas INTEGER DEFAULT 0,
    total_alertas_enviados INTEGER DEFAULT 0,
    instancias_desconectadas JSONB DEFAULT '[]'::jsonb,
    erros JSONB DEFAULT '[]'::jsonb,
    sucesso BOOLEAN DEFAULT true,
    mensagem TEXT
);

-- Adicionar comentário
COMMENT ON TABLE cron_monitor_instancias_logs IS 'Logs de execução do cron que monitora instâncias desconectadas';
;
