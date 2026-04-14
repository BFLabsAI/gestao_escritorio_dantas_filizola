create extension if not exists pgcrypto with schema extensions;
create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron with schema extensions;

create type public.tipo_beneficio as enum (
    'BPC_LOAS_DEFICIENTE',
    'BPC_LOAS_IDOSO',
    'AUXILIO_DOENCA',
    'APOSENTADORIA_INVALIDEZ',
    'APOSENTADORIA_IDADE',
    'APOSENTADORIA_ESPECIAL',
    'SALARIO_MATERNIDADE',
    'REVISIONAL',
    'PENSAO_MORTE'
);

create type public.fase_kanban as enum (
    'NOVO_PROCESSO',
    'DOCUMENTACAO',
    'DOC_PENDENTE',
    'APROVACAO_GESTOR',
    'PRONTO_PROTOCOLO',
    'PETICIONADO',
    'PENDENCIA',
    'PROCESSO_FINALIZADO'
);

create type public.tipo_documento as enum (
    'RG',
    'CNH',
    'CPF',
    'COMPROVANTE_RESIDENCIA',
    'TITULO_ELEITOR',
    'CTPS',
    'CADUNICO',
    'NIS_NIT',
    'LAUDO_MEDICO',
    'EXAME',
    'ATESTADO',
    'RECEITA',
    'CERTIDAO_NASCIMENTO',
    'CERTIDAO_CASAMENTO',
    'CERTIDAO_OBITO',
    'RG_FALECIDO',
    'CPF_FALECIDO',
    'PROCURACAO',
    'CONTRATO',
    'OUTRO'
);

create type public.categoria_documento as enum (
    'DADOS_PESSOAIS',
    'DOCUMENTOS_FAMILIA',
    'DOCUMENTOS_FALECIDO',
    'COMPROVANTE_RENDA',
    'DOCUMENTOS_MEDICOS',
    'DOCUMENTOS_TRABALHISTAS',
    'CONTRATOS',
    'OUTROS'
);

create type public.qualidade_documento as enum (
    'LEGIVEL',
    'ILEGIVEL',
    'PENDENTE_ANALISE'
);

create type public.evento_inss as enum (
    'EXIGENCIA',
    'PERICIA_AGENDADA',
    'PERICIA_REALIZADA',
    'DEFERIDO',
    'INDEFERIDO',
    'JUNTADA_INDEFERIMENTO',
    'RECURSO_JUNTADO'
);

create or replace function public.set_atualizado_em()
returns trigger
language plpgsql
as $$
begin
    new.atualizado_em = now();
    return new;
end;
$$;

create table public.perfis_gestao_escritorio_filizola (
    id uuid primary key default extensions.gen_random_uuid(),
    user_id uuid not null unique references auth.users(id) on delete cascade,
    nome_completo varchar(200) not null,
    email varchar(255) not null unique,
    telefone varchar(20),
    cargo varchar(50) not null default 'convidado',
    ativo boolean not null default true,
    criado_em timestamptz not null default now(),
    atualizado_em timestamptz not null default now()
);

create or replace function public.current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
    select id
    from public.perfis_gestao_escritorio_filizola
    where user_id = auth.uid()
    limit 1
$$;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.perfis_gestao_escritorio_filizola (
        user_id,
        nome_completo,
        email,
        telefone,
        cargo
    )
    values (
        new.id,
        coalesce(new.raw_user_meta_data ->> 'nome_completo', split_part(coalesce(new.email, ''), '@', 1), 'Usuário'),
        coalesce(new.email, ''),
        new.raw_user_meta_data ->> 'telefone',
        coalesce(new.raw_user_meta_data ->> 'cargo', 'convidado')
    )
    on conflict (user_id) do update
    set
        nome_completo = excluded.nome_completo,
        email = excluded.email,
        telefone = coalesce(excluded.telefone, public.perfis_gestao_escritorio_filizola.telefone),
        cargo = coalesce(excluded.cargo, public.perfis_gestao_escritorio_filizola.cargo),
        atualizado_em = now();

    return new;
end;
$$;

create trigger on_auth_user_created_gestao_escritorio_filizola
    after insert or update on auth.users
    for each row
    execute function public.handle_new_auth_user();

create table public.clientes_gestao_escritorio_filizola (
    id uuid primary key default extensions.gen_random_uuid(),
    nome_completo varchar(200) not null,
    cpf varchar(14) not null unique,
    data_nascimento date,
    telefone varchar(20),
    email varchar(255),
    endereco jsonb,
    criado_em timestamptz not null default now(),
    atualizado_em timestamptz not null default now(),
    criado_por uuid references public.perfis_gestao_escritorio_filizola(id) default public.current_profile_id()
);

create table public.processos_gestao_escritorio_filizola (
    id uuid primary key default extensions.gen_random_uuid(),
    numero_processo varchar(50) unique,
    cliente_id uuid not null references public.clientes_gestao_escritorio_filizola(id) on delete cascade,
    tipo_beneficio public.tipo_beneficio not null,
    fase_kanban public.fase_kanban not null default 'NOVO_PROCESSO',
    numero_beneficio varchar(30),
    der date,
    data_protocolo date,
    observacoes text,
    urgencia boolean not null default false,
    dias_na_fase integer not null default 0,
    ultima_movimentacao_fase timestamptz not null default now(),
    criado_em timestamptz not null default now(),
    atualizado_em timestamptz not null default now(),
    criado_por uuid references public.perfis_gestao_escritorio_filizola(id) default public.current_profile_id(),
    pasta_documentos_url text
);

create table public.documentos_gestao_escritorio_filizola (
    id uuid primary key default extensions.gen_random_uuid(),
    processo_id uuid not null references public.processos_gestao_escritorio_filizola(id) on delete cascade,
    tipo_documento public.tipo_documento not null,
    categoria_documento public.categoria_documento not null,
    storage_path text not null unique,
    nome_arquivo_original varchar(255),
    tamanho_bytes integer,
    mimetype varchar(100),
    qualidade_documento public.qualidade_documento not null default 'PENDENTE_ANALISE',
    metadados_ia jsonb,
    classificado_por_ia boolean not null default false,
    criado_em timestamptz not null default now()
);

create table public.historico_inss_gestao_escritorio_filizola (
    id uuid primary key default extensions.gen_random_uuid(),
    processo_id uuid not null references public.processos_gestao_escritorio_filizola(id) on delete cascade,
    evento public.evento_inss not null,
    conteudo_texto text,
    data_evento_portal timestamptz,
    prazo_fatal date,
    storage_print_path text,
    criado_em timestamptz not null default now()
);

create table public.exigencias_doc_gestao_escritorio_filizola (
    id uuid primary key default extensions.gen_random_uuid(),
    tipo_beneficio public.tipo_beneficio not null,
    tipo_documento public.tipo_documento not null,
    obrigatorio boolean not null default true,
    descricao text,
    ordem_exibicao integer not null default 0,
    ativo boolean not null default true,
    criado_em timestamptz not null default now(),
    unique (tipo_beneficio, tipo_documento)
);

create table public.notificacoes_gestao_escritorio_filizola (
    id uuid primary key default extensions.gen_random_uuid(),
    processo_id uuid references public.processos_gestao_escritorio_filizola(id) on delete set null,
    telefone_destino varchar(20) not null,
    mensagem text not null,
    tipo_notificacao varchar(50) not null,
    status_envio varchar(20) not null default 'PENDENTE',
    resposta_uazapi jsonb,
    agendado_para timestamptz,
    enviado_em timestamptz,
    criado_em timestamptz not null default now()
);

create index idx_clientes_gef_cpf on public.clientes_gestao_escritorio_filizola(cpf);
create index idx_clientes_gef_nome on public.clientes_gestao_escritorio_filizola
    using gin (to_tsvector('portuguese', nome_completo));
create index idx_processos_gef_cliente on public.processos_gestao_escritorio_filizola(cliente_id);
create index idx_processos_gef_fase on public.processos_gestao_escritorio_filizola(fase_kanban);
create index idx_processos_gef_numero on public.processos_gestao_escritorio_filizola(numero_processo);
create index idx_processos_gef_urgencia on public.processos_gestao_escritorio_filizola(urgencia)
    where urgencia = true;
create index idx_processos_gef_notificacao on public.processos_gestao_escritorio_filizola(fase_kanban)
    where fase_kanban in ('DOC_PENDENTE', 'APROVACAO_GESTOR', 'PENDENCIA');
create index idx_documentos_gef_processo on public.documentos_gestao_escritorio_filizola(processo_id);
create index idx_documentos_gef_tipo on public.documentos_gestao_escritorio_filizola(tipo_documento);
create index idx_documentos_gef_pendente on public.documentos_gestao_escritorio_filizola(classificado_por_ia)
    where classificado_por_ia = false;
create index idx_historico_gef_processo on public.historico_inss_gestao_escritorio_filizola(processo_id);
create index idx_historico_gef_evento on public.historico_inss_gestao_escritorio_filizola(evento);
create index idx_historico_gef_prazo on public.historico_inss_gestao_escritorio_filizola(prazo_fatal)
    where prazo_fatal is not null;
create index idx_exigencias_gef_beneficio on public.exigencias_doc_gestao_escritorio_filizola(tipo_beneficio);
create index idx_notificacoes_gef_status on public.notificacoes_gestao_escritorio_filizola(status_envio);
create index idx_notificacoes_gef_agendamento on public.notificacoes_gestao_escritorio_filizola(agendado_para);

create or replace function public.set_processo_defaults()
returns trigger
language plpgsql
as $$
begin
    if new.id is null then
        new.id = extensions.gen_random_uuid();
    end if;

    if new.pasta_documentos_url is null or btrim(new.pasta_documentos_url) = '' then
        new.pasta_documentos_url = format('clientes/%s/processos/%s/', new.cliente_id, new.id);
    end if;

    if new.ultima_movimentacao_fase is null then
        new.ultima_movimentacao_fase = now();
    end if;

    return new;
end;
$$;

create or replace function public.atualizar_dias_fase()
returns trigger
language plpgsql
as $$
begin
    if new.fase_kanban <> old.fase_kanban then
        new.ultima_movimentacao_fase = now();
        new.dias_na_fase = 0;
    else
        new.dias_na_fase = greatest(
            0,
            floor(extract(epoch from (now() - old.ultima_movimentacao_fase)) / 86400)::integer
        );
    end if;

    new.atualizado_em = now();
    return new;
end;
$$;

create or replace function public.mover_para_pendencia_exigencia()
returns trigger
language plpgsql
as $$
begin
    if new.evento = 'EXIGENCIA' then
        update public.processos_gestao_escritorio_filizola
        set
            fase_kanban = 'PENDENCIA',
            urgencia = true
        where id = new.processo_id;
    end if;

    return new;
end;
$$;

create trigger trigger_clientes_atualizado_em
    before update on public.clientes_gestao_escritorio_filizola
    for each row
    execute function public.set_atualizado_em();

create trigger trigger_perfis_atualizado_em
    before update on public.perfis_gestao_escritorio_filizola
    for each row
    execute function public.set_atualizado_em();

create trigger trigger_processos_defaults
    before insert on public.processos_gestao_escritorio_filizola
    for each row
    execute function public.set_processo_defaults();

create trigger trigger_atualizar_dias_fase
    before update on public.processos_gestao_escritorio_filizola
    for each row
    execute function public.atualizar_dias_fase();

create trigger trigger_mover_pendencia_exigencia
    after insert on public.historico_inss_gestao_escritorio_filizola
    for each row
    execute function public.mover_para_pendencia_exigencia();

alter table public.perfis_gestao_escritorio_filizola enable row level security;
alter table public.clientes_gestao_escritorio_filizola enable row level security;
alter table public.processos_gestao_escritorio_filizola enable row level security;
alter table public.documentos_gestao_escritorio_filizola enable row level security;
alter table public.historico_inss_gestao_escritorio_filizola enable row level security;
alter table public.exigencias_doc_gestao_escritorio_filizola enable row level security;
alter table public.notificacoes_gestao_escritorio_filizola enable row level security;

create policy "Usuarios podem ver proprio perfil"
    on public.perfis_gestao_escritorio_filizola
    for select
    to authenticated
    using (auth.uid() = user_id);

create policy "Usuarios podem atualizar proprio perfil"
    on public.perfis_gestao_escritorio_filizola
    for update
    to authenticated
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create policy "Usuarios autenticados podem ver clientes"
    on public.clientes_gestao_escritorio_filizola
    for select
    to authenticated
    using (true);

create policy "Usuarios autenticados podem inserir clientes"
    on public.clientes_gestao_escritorio_filizola
    for insert
    to authenticated
    with check (true);

create policy "Usuarios autenticados podem atualizar clientes"
    on public.clientes_gestao_escritorio_filizola
    for update
    to authenticated
    using (true)
    with check (true);

create policy "Usuarios autenticados podem deletar clientes"
    on public.clientes_gestao_escritorio_filizola
    for delete
    to authenticated
    using (true);

create policy "Usuarios autenticados podem ver processos"
    on public.processos_gestao_escritorio_filizola
    for select
    to authenticated
    using (true);

create policy "Usuarios autenticados podem inserir processos"
    on public.processos_gestao_escritorio_filizola
    for insert
    to authenticated
    with check (true);

create policy "Usuarios autenticados podem atualizar processos"
    on public.processos_gestao_escritorio_filizola
    for update
    to authenticated
    using (true)
    with check (true);

create policy "Usuarios autenticados podem deletar processos"
    on public.processos_gestao_escritorio_filizola
    for delete
    to authenticated
    using (true);

create policy "Usuarios autenticados podem ver documentos"
    on public.documentos_gestao_escritorio_filizola
    for select
    to authenticated
    using (true);

create policy "Usuarios autenticados podem inserir documentos"
    on public.documentos_gestao_escritorio_filizola
    for insert
    to authenticated
    with check (true);

create policy "Usuarios autenticados podem atualizar documentos"
    on public.documentos_gestao_escritorio_filizola
    for update
    to authenticated
    using (true)
    with check (true);

create policy "Usuarios autenticados podem deletar documentos"
    on public.documentos_gestao_escritorio_filizola
    for delete
    to authenticated
    using (true);

create policy "Usuarios autenticados podem ver historico INSS"
    on public.historico_inss_gestao_escritorio_filizola
    for select
    to authenticated
    using (true);

create policy "Usuarios autenticados podem inserir historico INSS"
    on public.historico_inss_gestao_escritorio_filizola
    for insert
    to authenticated
    with check (true);

create policy "Usuarios autenticados podem atualizar historico INSS"
    on public.historico_inss_gestao_escritorio_filizola
    for update
    to authenticated
    using (true)
    with check (true);

create policy "Usuarios autenticados podem deletar historico INSS"
    on public.historico_inss_gestao_escritorio_filizola
    for delete
    to authenticated
    using (true);

create policy "Usuarios autenticados podem ver exigencias"
    on public.exigencias_doc_gestao_escritorio_filizola
    for select
    to authenticated
    using (true);

create policy "Usuarios autenticados podem inserir exigencias"
    on public.exigencias_doc_gestao_escritorio_filizola
    for insert
    to authenticated
    with check (true);

create policy "Usuarios autenticados podem atualizar exigencias"
    on public.exigencias_doc_gestao_escritorio_filizola
    for update
    to authenticated
    using (true)
    with check (true);

create policy "Usuarios autenticados podem deletar exigencias"
    on public.exigencias_doc_gestao_escritorio_filizola
    for delete
    to authenticated
    using (true);

create policy "Usuarios autenticados podem ver notificacoes"
    on public.notificacoes_gestao_escritorio_filizola
    for select
    to authenticated
    using (true);

create policy "Usuarios autenticados podem inserir notificacoes"
    on public.notificacoes_gestao_escritorio_filizola
    for insert
    to authenticated
    with check (true);

create policy "Usuarios autenticados podem atualizar notificacoes"
    on public.notificacoes_gestao_escritorio_filizola
    for update
    to authenticated
    using (true)
    with check (true);

create policy "Usuarios autenticados podem deletar notificacoes"
    on public.notificacoes_gestao_escritorio_filizola
    for delete
    to authenticated
    using (true);

insert into storage.buckets (id, name, public, file_size_limit)
values ('documentos_processuais', 'documentos_processuais', false, 52428800)
on conflict (id) do nothing;

create policy "Usuarios autenticados podem fazer upload de documentos processuais"
    on storage.objects
    for insert
    to authenticated
    with check (
        bucket_id = 'documentos_processuais'
        and auth.role() = 'authenticated'
    );

create policy "Usuarios autenticados podem baixar documentos processuais"
    on storage.objects
    for select
    to authenticated
    using (
        bucket_id = 'documentos_processuais'
        and auth.role() = 'authenticated'
    );

create policy "Usuarios autenticados podem deletar documentos processuais"
    on storage.objects
    for delete
    to authenticated
    using (
        bucket_id = 'documentos_processuais'
        and auth.role() = 'authenticated'
    );

create or replace function public.agendar_notificacoes_processos_criticos(
    project_url text,
    cron_secret text,
    cron_expression text default '0 7 * * *'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    existing_job record;
    headers jsonb;
    request_sql text;
begin
    if project_url is null or btrim(project_url) = '' then
        raise exception 'project_url é obrigatório';
    end if;

    if cron_secret is null or btrim(cron_secret) = '' then
        raise exception 'cron_secret é obrigatório';
    end if;

    for existing_job in
        select jobid
        from cron.job
        where jobname = 'notificar-processos-criticos-7h'
    loop
        perform cron.unschedule(existing_job.jobid);
    end loop;

    headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', format('Bearer %s', cron_secret)
    );

    request_sql := format(
        $fmt$
        select net.http_post(
            url := %L,
            headers := %L::jsonb,
            body := '{}'::jsonb
        );
        $fmt$,
        rtrim(project_url, '/') || '/functions/v1/notificar-processos-criticos',
        headers::text
    );

    perform cron.schedule(
        'notificar-processos-criticos-7h',
        cron_expression,
        request_sql
    );
end;
$$;

insert into public.exigencias_doc_gestao_escritorio_filizola (
    tipo_beneficio,
    tipo_documento,
    obrigatorio,
    descricao,
    ordem_exibicao
)
values
    ('AUXILIO_DOENCA', 'RG', true, 'Identidade do requerente', 1),
    ('AUXILIO_DOENCA', 'CPF', true, 'CPF do requerente', 2),
    ('AUXILIO_DOENCA', 'COMPROVANTE_RESIDENCIA', true, 'Comprovante de endereço atualizado', 3),
    ('AUXILIO_DOENCA', 'CTPS', true, 'Carteira de trabalho', 4),
    ('AUXILIO_DOENCA', 'TITULO_ELEITOR', true, 'Título de eleitor', 5),
    ('AUXILIO_DOENCA', 'LAUDO_MEDICO', true, 'Laudo de incapacidade', 6),
    ('PENSAO_MORTE', 'RG', true, 'Identidade do requerente', 1),
    ('PENSAO_MORTE', 'CPF', true, 'CPF do requerente', 2),
    ('PENSAO_MORTE', 'COMPROVANTE_RESIDENCIA', true, 'Comprovante de endereço atualizado', 3),
    ('PENSAO_MORTE', 'NIS_NIT', true, 'Número do NIS/NIT', 4),
    ('PENSAO_MORTE', 'CERTIDAO_CASAMENTO', true, 'Certidão de casamento', 5),
    ('PENSAO_MORTE', 'RG_FALECIDO', true, 'Identidade do falecido', 6),
    ('PENSAO_MORTE', 'CPF_FALECIDO', true, 'CPF do falecido', 7),
    ('PENSAO_MORTE', 'TITULO_ELEITOR', true, 'Título de eleitor', 8),
    ('PENSAO_MORTE', 'CERTIDAO_OBITO', true, 'Certidão de óbito', 9),
    ('PENSAO_MORTE', 'CERTIDAO_NASCIMENTO', false, 'Certidão de nascimento dos filhos (se tiver)', 10),
    ('BPC_LOAS_DEFICIENTE', 'RG', true, 'Identidade de todos os integrantes da casa', 1),
    ('BPC_LOAS_DEFICIENTE', 'CPF', true, 'CPF do requerente', 2),
    ('BPC_LOAS_DEFICIENTE', 'COMPROVANTE_RESIDENCIA', true, 'Comprovante de endereço atualizado', 3),
    ('BPC_LOAS_DEFICIENTE', 'CADUNICO', true, 'Cadastro único (CadÚnico)', 4),
    ('BPC_LOAS_DEFICIENTE', 'CTPS', false, 'Carteira de trabalho (se tiver)', 5),
    ('BPC_LOAS_DEFICIENTE', 'TITULO_ELEITOR', true, 'Título de eleitor', 6),
    ('BPC_LOAS_DEFICIENTE', 'LAUDO_MEDICO', true, 'Laudos, receitas, atestados (tudo sobre a doença)', 7),
    ('BPC_LOAS_DEFICIENTE', 'ATESTADO', false, 'Atestados médicos complementares (se tiver)', 8),
    ('BPC_LOAS_DEFICIENTE', 'RECEITA', false, 'Receitas médicas (se tiver)', 9),
    ('BPC_LOAS_DEFICIENTE', 'CERTIDAO_NASCIMENTO', false, 'Certidão de nascimento (se o benefício for para filho menor de idade)', 10),
    ('BPC_LOAS_IDOSO', 'RG', true, 'Identidade do requerente', 1),
    ('BPC_LOAS_IDOSO', 'CPF', true, 'CPF do requerente', 2),
    ('BPC_LOAS_IDOSO', 'COMPROVANTE_RESIDENCIA', true, 'Comprovante de endereço atualizado', 3),
    ('BPC_LOAS_IDOSO', 'CERTIDAO_OBITO', false, 'Certidão de óbito (se aplicável)', 4),
    ('BPC_LOAS_IDOSO', 'TITULO_ELEITOR', true, 'Título de eleitor', 5),
    ('APOSENTADORIA_IDADE', 'RG', true, 'Identidade do requerente', 1),
    ('APOSENTADORIA_IDADE', 'CPF', true, 'CPF do requerente', 2),
    ('APOSENTADORIA_IDADE', 'COMPROVANTE_RESIDENCIA', true, 'Comprovante de endereço atualizado', 3),
    ('APOSENTADORIA_IDADE', 'CTPS', true, 'Carteira de trabalho', 4),
    ('APOSENTADORIA_IDADE', 'TITULO_ELEITOR', true, 'Título de eleitor', 5),
    ('APOSENTADORIA_IDADE', 'NIS_NIT', true, 'Número do NIS/NIT (PIS/PASEP)', 6)
on conflict (tipo_beneficio, tipo_documento) do update
set
    obrigatorio = excluded.obrigatorio,
    descricao = excluded.descricao,
    ordem_exibicao = excluded.ordem_exibicao,
    ativo = true;
