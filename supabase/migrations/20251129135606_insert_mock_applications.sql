-- Insert mock applications/inscriptions for testing

-- 1. Ana Silva application for SDR/BDR position (vaga_id = 1, candidato_id = 1)
INSERT INTO inscricoes_banco_talentos_execut (
    vaga_id,
    candidato_id,
    respostas_especificas,
    status_inscricao,
    feedback,
    pontuacao_total,
    data_inscricao
) VALUES (
    1, -- SDR/BDR
    1, -- Ana Silva
    '[
        {
            "pergunta_id": 1,
            "pergunta_texto": "Quais CRMs você já utilizou?",
            "resposta_array": ["Pipedrive", "HubSpot", "RD Station CRM"],
            "tipo_resposta": "checkbox"
        },
        {
            "pergunta_id": 2,
            "pergunta_texto": "Quais ferramentas de prospecção você já usou?",
            "resposta_array": ["LinkedIn Sales Navigator", "Apollo.io", "Planilhas"],
            "tipo_resposta": "checkbox"
        },
        {
            "pergunta_id": 3,
            "pergunta_texto": "Quais eram suas principais metas?",
            "resposta_texto": "Agendar 20 reuniões qualificadas por mês, com taxa de conversão de 15%",
            "tipo_resposta": "texto"
        },
        {
            "pergunta_id": 4,
            "pergunta_texto": "Qual canal de prospecção você mais domina?",
            "resposta_texto": "LinkedIn (Social Selling)",
            "tipo_resposta": "select"
        },
        {
            "pergunta_id": 5,
            "pergunta_texto": "Como você lida com um \"não\"?",
            "resposta_texto": "Vejo como oportunidade de entender melhor as necessidades do cliente e qualificar meu discurso.",
            "tipo_resposta": "texto"
        }
    ]'::jsonb,
    'recebida',
    'Candidata com bom potencial, experiência com CRMs e boa postura de aprendizado.',
    75,
    NOW() - INTERVAL '2 days'
);

-- 2. Carlos Oliveira application for Front-end position (vaga_id = 12, candidato_id = 2)
INSERT INTO inscricoes_banco_talentos_execut (
    vaga_id,
    candidato_id,
    respostas_especificas,
    portfolio_tipo,
    portfolio_url,
    status_inscricao,
    feedback,
    pontuacao_total,
    data_inscricao
) VALUES (
    12, -- Desenvolvedor Front-end
    2, -- Carlos Oliveira
    '[
        {
            "pergunta_id": 1,
            "pergunta_texto": "Quais são suas principais tecnologias?",
            "resposta_array": ["React", "TypeScript", "Next.js", "HTML5", "CSS3"],
            "tipo_resposta": "checkbox"
        },
        {
            "pergunta_id": 2,
            "pergunta_texto": "Como você garante que um site ou app seja responsivo e rápido?",
            "resposta_texto": "Uso mobile-first design, CSS Grid/Flexbox, lazy loading, code splitting e otimização de imagens. Faço testes de performance com Lighthouse e monitoro Core Web Vitals.",
            "tipo_resposta": "texto_longo"
        },
        {
            "pergunta_id": 3,
            "pergunta_texto": "Link do seu GitHub",
            "resposta_texto": "https://github.com/carlosoliveira",
            "tipo_resposta": "url"
        },
        {
            "pergunta_id": 4,
            "pergunta_texto": "Link de um projeto/site que você construiu e está no ar",
            "resposta_texto": "https://meu-portfolio-react.vercel.app",
            "tipo_resposta": "url"
        }
    ]'::jsonb,
    'link',
    'https://meu-portfolio-react.vercel.app',
    'qualificado',
    'Desenvolvedor sólido com bons projetos no portfólio e domínio das tecnologias requisitadas.',
    85,
    NOW() - INTERVAL '5 days'
);;
