-- First, let's create a mapping of specific questions for each role based on cargos.md
-- This will be stored as JSONB in the perguntas_especificas field

-- Migration from cargos to vagas with enhanced data
INSERT INTO vagas_banco_talentos_execut (
    setor_id,
    nome_cargo,
    tipo_contrato,
    modalidade,
    localizacao,
    salario_min,
    salario_max,
    descricao,
    requisitos,
    status,
    experiencia_minima,
    data_publicacao,
    perguntas_especificas,
    ferramentas_requeridas
)
SELECT 
    c.setor_id,
    c.nome_cargo,
    c.tipo_contrato,
    'Híbrido' as modalidade, -- Default based on existing data
    c.localizacao,
    c.salario_min,
    c.salario_max,
    CASE 
        WHEN c.nome_cargo = 'SDR/BDR' THEN 'Buscamos SDR/BDR para prospecção de novos clientes, qualificação de leads e agendamento de reuniões. Você será responsável pela primeira etapa do funil de vendas.'
        WHEN c.nome_cargo = 'Closer' THEN 'Buscamos Closer para negociação e fechamento de contratos. Você será responsável pela etapa final do funil de vendas, conduzindo negociações complexas.'
        WHEN c.nome_cargo = 'Social Media' THEN 'Buscamos Social Media para gestão e estratégia de redes sociais para nossos clientes. Você criará conteúdo, engagement e analytics.'
        WHEN c.nome_cargo = 'Designer' THEN 'Buscamos Designer para criação de identidade visual, posts para redes sociais, anúncios e layouts digitais.'
        WHEN c.nome_cargo = 'Filmmaker' THEN 'Buscamos Filmmaker para produção e edição de vídeos institucionais, anúncios e conteúdo para redes sociais.'
        ELSE 'Vaga em aberto para profissional talentoso.'
    END as descricao,
    'Experiência comprovada na área, boas habilidades de comunicação e proatividade.' as requisitos,
    c.status,
    '1' as experiencia_minima, -- Default
    c.created_at as data_publicacao,
    CASE 
        WHEN c.nome_cargo = 'SDR/BDR' THEN '[
            {"id": 1, "pergunta": "Quais CRMs você já utilizou?", "tipo": "checkbox", "opcoes": ["Pipedrive", "Kommo", "RD Station CRM", "HubSpot", "Outros"]},
            {"id": 2, "pergunta": "Quais ferramentas de prospecção você já usou?", "tipo": "checkbox", "opcoes": ["Meetime", "Reev", "Apollo.io", "Snov.io", "LinkedIn Sales Navigator", "Planilhas"]},
            {"id": 3, "pergunta": "Quais eram suas principais metas?", "tipo": "texto"},
            {"id": 4, "pergunta": "Qual canal de prospecção você mais domina?", "tipo": "select", "opcoes": ["LinkedIn (Social Selling)", "Cold E-mail", "Cold Call"]},
            {"id": 5, "pergunta": "Como você lida com um \"não\"?", "tipo": "texto"}
        ]'::jsonb
        
        WHEN c.nome_cargo = 'Designer' THEN '[
            {"id": 1, "pergunta": "Quais ferramentas de design você domina?", "tipo": "checkbox", "opcoes": ["Figma", "Adobe Illustrator", "Adobe Photoshop", "Adobe XD", "Canva Pro"]},
            {"id": 2, "pergunta": "Qual é o seu ponto forte?", "tipo": "checkbox", "opcoes": ["Posts para social media", "Identidade visual/Branding", "Layouts para sites/UI", "Anúncios estáticos", "Impressos"]},
            {"id": 3, "pergunta": "Como prefere enviar seu Portfólio?", "tipo": "radio", "opcoes": ["Anexar Arquivo", "Inserir Link"]},
            {"id": 4, "pergunta": "Link do Portfólio", "tipo": "url"},
            {"id": 5, "pergunta": "Anexe seus 2-3 melhores projetos", "tipo": "arquivo_multiplo"}
        ]'::jsonb
        
        WHEN c.nome_cargo = 'Social Media' THEN '[
            {"id": 1, "pergunta": "Quais ferramentas de gestão e agendamento você já usou?", "tipo": "checkbox", "opcoes": ["mLabs", "Etus", "Hootsuite", "Buffer", "Meta Business Suite"]},
            {"id": 2, "pergunta": "Quais redes você domina?", "tipo": "checkbox", "opcoes": ["Instagram", "TikTok", "LinkedIn", "YouTube", "Twitter (X)", "Pinterest"]},
            {"id": 3, "pergunta": "Descreva brevemente como você planeja um calendário de conteúdo para um cliente.", "tipo": "texto_longo"},
            {"id": 4, "pergunta": "Envie o @ (username) de 2 ou 3 perfis que você já gerenciou ou um link para seu portfólio.", "tipo": "texto"}
        ]'::jsonb
        
        WHEN c.nome_cargo = 'Front-end' THEN '[
            {"id": 1, "pergunta": "Quais são suas principais tecnologias?", "tipo": "checkbox", "opcoes": ["React", "Angular", "Vue.js", "JavaScript (Puro)", "TypeScript", "HTML5", "CSS3 (Sass/Less)", "Next.js"]},
            {"id": 2, "pergunta": "Como você garante que um site ou app seja responsivo e rápido?", "tipo": "texto_longo"},
            {"id": 3, "pergunta": "Link do seu GitHub", "tipo": "url", "obrigatorio": true},
            {"id": 4, "pergunta": "Link de um projeto/site que você construiu e está no ar.", "tipo": "url"}
        ]'::jsonb
        
        ELSE '[]'::jsonb
    END as perguntas_especificas,
    CASE 
        WHEN c.nome_cargo = 'SDR/BDR' THEN '["Pipedrive", "Kommo", "RD Station CRM", "HubSpot", "Meetime", "Reev", "Apollo.io"]'::jsonb
        WHEN c.nome_cargo = 'Designer' THEN '["Figma", "Adobe Illustrator", "Adobe Photoshop", "Adobe XD", "Canva Pro"]'::jsonb
        WHEN c.nome_cargo = 'Social Media' THEN '["mLabs", "Etus", "Hootsuite", "Buffer", "Meta Business Suite", "Instagram", "TikTok", "LinkedIn"]'::jsonb
        WHEN c.nome_cargo = 'Front-end' THEN '["React", "TypeScript", "HTML5", "CSS3", "Next.js"]'::jsonb
        ELSE '[]'::jsonb
    END as ferramentas_requeridas
FROM cargos_banco_talentos_execut c;;
