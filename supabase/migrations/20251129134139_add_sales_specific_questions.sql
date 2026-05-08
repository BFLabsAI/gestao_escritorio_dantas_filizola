-- Add sales-specific questions
-- Get SDR/BDR job
DO $$
DECLARE
    vaga_sdr UUID;
    vaga_closer UUID;
BEGIN
    -- Find SDR job
    SELECT id INTO vaga_sdr FROM vagas_banco_talentos_execut WHERE titulo_vaga = 'SDR/BDR' LIMIT 1;
    SELECT id INTO vaga_closer FROM vagas_banco_talentos_execut WHERE titulo_vaga = 'Closer' LIMIT 1;
    
    IF vaga_sdr IS NOT NULL THEN
        -- SDR Specific Questions
        INSERT INTO perguntas_vagas_banco_talentos_execut (
            vaga_id, titulo, descricao, tipo_pergunta, obrigatorio, ordem, opcoes
        ) VALUES
        (
            vaga_sdr,
            'CRMs Utilizados',
            'Quais CRMs você já utilizou?',
            'checkbox',
            false,
            10,
            '["Pipedrive", "Kommo", "RD Station CRM", "HubSpot", "Outros"]'::jsonb
        ),
        (
            vaga_sdr,
            'Ferramentas de Prospecção',
            'Quais ferramentas de prospecção (cadência, inteligência) você já usou?',
            'checkbox',
            false,
            11,
            '["Meetime", "Reev", "Apollo.io", "Snov.io", "LinkedIn Sales Navigator", "Planilhas", "Outros"]'::jsonb
        ),
        (
            vaga_sdr,
            'Principais Metas',
            'Quais eram suas principais metas?',
            'texto_curto',
            false,
            12,
            NULL
        ),
        (
            vaga_sdr,
            'Canal de Prospecção',
            'Qual canal de prospecção você mais domina?',
            'select',
            false,
            13,
            '["LinkedIn (Social Selling)", "Cold E-mail", "Cold Call"]'::jsonb
        ),
        (
            vaga_sdr,
            'Lidando com "Não"',
            'Como você lida com um "não"?',
            'texto_longo',
            false,
            14,
            NULL
        );
    END IF;
    
    IF vaga_closer IS NOT NULL THEN
        -- Closer Specific Questions
        INSERT INTO perguntas_vagas_banco_talentos_execut (
            vaga_id, titulo, descricao, tipo_pergunta, obrigatorio, ordem, opcoes
        ) VALUES
        (
            vaga_closer,
            'CRMs Dominados',
            'Quais CRMs você domina para gerenciar seu funil?',
            'checkbox',
            false,
            10,
            '["Pipedrive", "Kommo", "RD Station CRM", "HubSpot", "Salesforce", "Outros"]'::jsonb
        ),
        (
            vaga_closer,
            'Tipo de Vendedor',
            'Que tipo de vendedor você se considera?',
            'select',
            false,
            11,
            '["Relacionador e empático", "Técnico e especialista no produto", "Negociador e focado em conversão"]'::jsonb
        ),
        (
            vaga_closer,
            'Maior Deal',
            'Qual foi o seu maior deal (contrato) fechado? E qual o seu ciclo médio de vendas?',
            'texto_longo',
            false,
            12,
            NULL
        ),
        (
            vaga_closer,
            'Perfil de Cliente',
            'Descreva o perfil de cliente (porte, segmento) com quem você está mais acostumado a negociar.',
            'texto_longo',
            false,
            13,
            NULL
        );
    END IF;
END $$;;
