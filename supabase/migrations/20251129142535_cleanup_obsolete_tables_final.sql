-- Remover tabelas completamente obsoletas e vazias sem impacto algum

-- 1. Primeiro remover as tabelas que dependem de outras
DROP TABLE IF EXISTS respostas_especificas_vagas_banco_talentos_execut CASCADE;

-- 2. Remover tabelas completamente vazias
DROP TABLE IF EXISTS candidato_aplicacoes_banco_talentos_execut;
DROP TABLE IF EXISTS respostas_especificas_banco_talentos_execut;
DROP TABLE IF EXISTS social_posts_vagas_enhanced_banco_talentos_execut;
DROP TABLE IF EXISTS notas_internas_banco_talentos_execut;

-- 3. Remover tabela antiga cargos (dados já migrados para vagas e dependências removidas)
DROP TABLE IF EXISTS cargos_banco_talentos_execut;

-- 4. Remover tabela perguntas_vagas (não referenciada no frontend)
DROP TABLE IF EXISTS perguntas_vagas_banco_talentos_execut;;
