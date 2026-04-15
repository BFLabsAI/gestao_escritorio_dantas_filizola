-- =============================================
-- Migration: Desabilitar RLS em todas as tabelas
-- =============================================
-- MVP sem autenticacao - remover restricoes de RLS

alter table public.perfis_gestao_escritorio_filizola disable row level security;
alter table public.clientes_gestao_escritorio_filizola disable row level security;
alter table public.processos_gestao_escritorio_filizola disable row level security;
alter table public.documentos_gestao_escritorio_filizola disable row level security;
alter table public.historico_inss_gestao_escritorio_filizola disable row level security;
alter table public.exigencias_doc_gestao_escritorio_filizola disable row level security;
alter table public.notificacoes_gestao_escritorio_filizola disable row level security;
