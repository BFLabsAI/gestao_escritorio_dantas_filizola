-- First, let's add existing jobs to the new vagas table
INSERT INTO vagas_banco_talentos_execut (
    titulo_vaga,
    setor_id,
    descricao_responsabilidades,
    descricao_requisitos,
    salario_min,
    salario_max,
    modalidade_trabalho,
    tipo_contrato,
    status,
    criado_por,
    created_at,
    updated_at
)
SELECT 
    c.nome_cargo,
    c.setor_id,
    c.descricao,
    c.requisitos,
    c.salario_min,
    c.salario_max,
    c.localizacao,
    c.tipo_contrato,
    c.status,
    'migration',
    c.created_at,
    c.updated_at
FROM cargos_banco_talentos_execut c;

-- Now create basic questions for all jobs (common questions)
INSERT INTO perguntas_vagas_banco_talentos_execut (
    vaga_id, titulo, descricao, tipo_pergunta, obrigatorio, ordem
)
SELECT 
    v.id,
    'Nome Completo',
    'Informe seu nome completo',
    'texto_curto',
    true,
    1
FROM vagas_banco_talentos_execut v;

INSERT INTO perguntas_vagas_banco_talentos_execut (
    vaga_id, titulo, descricao, tipo_pergunta, obrigatorio, ordem, placeholder
)
SELECT 
    v.id,
    'E-mail',
    'Informe seu melhor e-mail',
    'email',
    true,
    2,
    'exemplo@email.com'
FROM vagas_banco_talentos_execut v;

INSERT INTO perguntas_vagas_banco_talentos_execut (
    vaga_id, titulo, descricao, tipo_pergunta, obrigatorio, ordem, mascara, placeholder
)
SELECT 
    v.id,
    'Telefone (WhatsApp)',
    'Seu telefone com DDD',
    'telefone',
    true,
    3,
    '(XX) XXXXX-XXXX',
    '(11) 98765-4321'
FROM vagas_banco_talentos_execut v;

INSERT INTO perguntas_vagas_banco_talentos_execut (
    vaga_id, titulo, descricao, tipo_pergunta, obrigatorio, ordem, placeholder
)
SELECT 
    v.id,
    'Link do LinkedIn',
    'Seu perfil no LinkedIn (opcional)',
    'url',
    false,
    4,
    'https://linkedin.com/in/seuperfil'
FROM vagas_banco_talentos_execut v;

INSERT INTO perguntas_vagas_banco_talentos_execut (
    vaga_id, titulo, descricao, tipo_pergunta, obrigatorio, ordem, mascara, placeholder
)
SELECT 
    v.id,
    'Pretensão Salarial (CLT)',
    'Sua pretensão salarial mensal',
    'monetary',
    true,
    5,
    'R$ 0.000,00',
    'R$ 5.000,00'
FROM vagas_banco_talentos_execut v;

INSERT INTO perguntas_vagas_banco_talentos_execut (
    vaga_id, titulo, descricao, tipo_pergunta, obrigatorio, ordem, opcoes
)
SELECT 
    v.id,
    'Tempo de Experiência',
    'Quanto tempo de experiência você possui na área?',
    'select',
    true,
    6,
    '["Estou começando / Buscando 1ª oportunidade", "Menos de 1 ano", "1 a 3 anos", "3 a 5 anos", "Mais de 5 anos"]'::jsonb
FROM vagas_banco_talentos_execut v;;
