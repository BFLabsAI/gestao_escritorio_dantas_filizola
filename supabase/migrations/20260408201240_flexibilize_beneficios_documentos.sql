alter table public.processos_gestao_escritorio_filizola
    alter column tipo_beneficio drop default,
    alter column tipo_beneficio type text using tipo_beneficio::text;

alter table public.exigencias_doc_gestao_escritorio_filizola
    alter column tipo_beneficio type text using tipo_beneficio::text,
    alter column tipo_documento type text using tipo_documento::text;

alter table public.documentos_gestao_escritorio_filizola
    alter column tipo_documento type text using tipo_documento::text;
