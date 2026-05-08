-- Insert mock candidates for testing

-- 1. Insert Ana Silva (SDR/BDR candidate)
INSERT INTO candidatos_banco_talentos_execut (
    nome_completo,
    email,
    telefone,
    linkedin_url,
    pretensao_salarial,
    experiencia_anos,
    setor_interesse_id,
    motivacao_trabalho,
    maior_qualidade,
    habilidade_melhorar,
    desafio_resolvido,
    curriculo_tipo,
    curriculo_url,
    github_url,
    nivel_educacao,
    created_at
) VALUES (
    'Ana Silva',
    'ana.silva@exemplo.com',
    '(11) 99999-9999',
    'https://linkedin.com/in/ana-silva',
    2500.00,
    2,
    1, -- Vendas
    'Busco oportunidade para crescer na área de vendas e desenvolver minhas habilidades de negociação e prospecção.',
    'Comunicação assertiva e facilidade em criar rapport com clientes.',
    'Gestão de tempo e organização do funil de vendas.',
    'Fui desafiada a reativar contatos frios e conseguir agendar 5 reuniões em uma semana, superando a meta.',
    'link',
    '#',
    NULL,
    'Ensino Superior Completo',
    NOW()
);

-- 2. Insert Carlos Oliveira (Front-end Developer)
INSERT INTO candidatos_banco_talentos_execut (
    nome_completo,
    email,
    telefone,
    linkedin_url,
    pretensao_salarial,
    experiencia_anos,
    setor_interesse_id,
    motivacao_trabalho,
    maior_qualidade,
    habilidade_melhorar,
    desafio_resolvido,
    curriculo_tipo,
    curriculo_url,
    github_url,
    nivel_educacao,
    created_at
) VALUES (
    'Carlos Oliveira',
    'carlos.o@exemplo.com',
    '(21) 98888-8888',
    'https://linkedin.com/in/carlos-oliveira',
    6000.00,
    4,
    5, -- Tecnologia
    'Apaixonado por criar experiências digitais incríveis e resolver problemas complexos com código limpo.',
    'Domínio de React, TypeScript e responsive design.',
    'Back-end e arquitetura de sistemas escaláveis.',
    'Precisei otimizar uma aplicação que carregava em 8s, implementei lazy loading e code splitting reduzindo para 1.2s.',
    'link',
    '#',
    'https://github.com/carlosoliveira',
    'Ensino Superior Completo',
    NOW()
);;
