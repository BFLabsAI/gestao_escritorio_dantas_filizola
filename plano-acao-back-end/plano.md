# Plano de Ação - Backend Supabase para Sistema D&F Gestão

## Contexto

Este plano define a arquitetura de backend completa para o Sistema de Gestão Previdenciária Dantas & Filizola, utilizando **Supabase (PostgreSQL + Storage + Edge Functions)**. O backend precisa suportar o frontend já desenvolvido (Kanban, Clientes, Processos, Dashboard) e implementar funcionalidades críticas de automação.

## Requisitos Principais

1. **Banco de dados relacional** com tabelas correlacionadas
2. **Storage único** para documentos com RLS (Row Level Security)
3. **Edge Function** agendada para notificações diárias às 7h via UAZAPI
4. Notificar processos em fases críticas: Documentação Pendente, Aprovação Gestor, Pendência

---

## 1. Estrutura do Banco de Dados (PostgreSQL)

> **Observações sobre tabelas/features:**
> - **`historico_inss_gestao_escritorio_filizola`** (1.6): Registra eventos do portal do INSS (exigência, perícia, deferido/indeferido). Tem trigger que move o processo para PENDENCIA automaticamente ao detectar exigência. Usado como auditoria e automação de fases.
> - **`pg_cron`** (3.2): Agendador nativo do PostgreSQL. Dispara a Edge Function de notificações todos os dias às 7h. Sem ele, as notificações não seriam automáticas.
>
> Se nenhuma dessas features for necessária agora, podem ser removidas do escopo inicial e adicionadas depois.
>
> **Níveis de acesso (segundo momento):**
> Quando for implementar controle de acesso, a tabela `perfis_gestao_escritorio_filizola` já possui a coluna `cargo`. Serão 3 níveis:
> - **Super Admin**: acesso total, pode criar/editar/apagar clientes e processos, convidar pessoas
> - **Admin**: acesso total para criar/editar, mas NÃO pode apagar nem convidar pessoas
> - **Convidado**: somente visualização (leitura)
>
> Isso será implementado com políticas RLS mais granulares baseadas na coluna `cargo` da tabela de perfis. Não será feito agora.

### 1.1. Diagrama de Relacionamento

```
┌─────────────────────────────┐
│ perfis_gestao_escritorio_   │
│ filizola (usuarios)         │
└──────────────┬──────────────┘
               │ 1
               │
               │ N
┌──────────────▼──────────────┐       ┌─────────────────────────────┐
│ clientes_gestao_escritorio_ │◄──────┤ exigencias_doc_gestao_      │
│ filizola                    │       │ escritorio_filizola          │
└──────────────┬──────────────┘       │ (configurações)              │
               │ 1                     └─────────────────────────────┘
               │
               │ N
┌──────────────▼──────────────┐       ┌─────────────────────────────┐
│ processos_gestao_escritorio │──────►│ notificacoes_gestao_        │
│ _filizola                   │ N     │ escritorio_filizola          │
└──────────────┬──────────────┘       │ (histórico envio)            │
               │                       └─────────────────────────────┘
               │ N
               ├──┬──────────────────────────────┐
               │  │                              │
               │  │ N                            │ N
               ▼  ▼                              ▼
┌─────────────────────┐  ┌─────────────────────────────┐
│ documentos_gestao_  │  │ historico_inss_gestao_      │
│ escritorio_filizola │  │ escritorio_filizola          │
│ (uploads)           │  │                              │
└─────────────────────┘  └─────────────────────────────┘
```

### 1.2. Tabela: `perfis_gestao_escritorio_filizola` (extensão auth.users)

```sql
CREATE TABLE perfis_gestao_escritorio_filizola (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    nome_completo VARCHAR(200) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    telefone VARCHAR(20),
    cargo VARCHAR(50) NOT NULL, -- 'advogado', 'gestora', 'socio'
    ativo BOOLEAN DEFAULT true,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

-- RLS: Cada usuário vê só seu perfil
ALTER TABLE perfis_gestao_escritorio_filizola ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Usuários podem ver próprio perfil" ON perfis_gestao_escritorio_filizola
    FOR SELECT USING (auth.uid() = user_id);
```

### 1.3. Tabela: `clientes_gestao_escritorio_filizola`

```sql
CREATE TABLE clientes_gestao_escritorio_filizola (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome_completo VARCHAR(200) NOT NULL,
    cpf VARCHAR(14) NOT NULL UNIQUE,
    data_nascimento DATE,
    telefone VARCHAR(20),
    email VARCHAR(255),
    endereco JSONB, -- {logradouro, numero, complemento, bairro, cidade, uf, cep}
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW(),
    criado_por UUID REFERENCES perfis_gestao_escritorio_filizola(id)
);

CREATE INDEX idx_clientes_gef_cpf ON clientes_gestao_escritorio_filizola(cpf);
CREATE INDEX idx_clientes_gef_nome ON clientes_gestao_escritorio_filizola
    USING gin(to_tsvector('portuguese', nome_completo));

ALTER TABLE clientes_gestao_escritorio_filizola ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Todos logados podem ver clientes" ON clientes_gestao_escritorio_filizola
    FOR SELECT USING (true);
CREATE POLICY "Todos logados podem inserir clientes" ON clientes_gestao_escritorio_filizola
    FOR INSERT WITH CHECK (true);
CREATE POLICY "Todos logados podem atualizar clientes" ON clientes_gestao_escritorio_filizola
    FOR UPDATE USING (true);
```

### 1.4. Tabela: `processos_gestao_escritorio_filizola`

```sql
CREATE TYPE tipo_beneficio AS ENUM (
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

CREATE TYPE fase_kanban AS ENUM (
    'NOVO_PROCESSO',
    'DOCUMENTACAO',
    'DOC_PENDENTE',
    'APROVACAO_GESTOR',
    'PRONTO_PROTOCOLO',
    'PETICIONADO',
    'PENDENCIA',
    'PROCESSO_FINALIZADO'
);

CREATE TABLE processos_gestao_escritorio_filizola (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_processo VARCHAR(50) UNIQUE,
    cliente_id UUID NOT NULL REFERENCES clientes_gestao_escritorio_filizola(id) ON DELETE CASCADE,
    tipo_beneficio tipo_beneficio NOT NULL,
    fase_kanban fase_kanban DEFAULT 'NOVO_PROCESSO',
    numero_beneficio VARCHAR(30),
    der DATE,
    data_protocolo DATE,
    observacoes TEXT,
    urgencia BOOLEAN DEFAULT false,
    dias_na_fase INTEGER DEFAULT 0,
    ultima_movimentacao_fase TIMESTAMPTZ DEFAULT NOW(),
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW(),
    criado_por UUID REFERENCES perfis_gestao_escritorio_filizola(id),
    pasta_documentos_url TEXT -- Caminho no Storage: 'clientes/{cliente_id}/processos/{processo_id}/'
);

CREATE INDEX idx_processos_gef_cliente ON processos_gestao_escritorio_filizola(cliente_id);
CREATE INDEX idx_processos_gef_fase ON processos_gestao_escritorio_filizola(fase_kanban);
CREATE INDEX idx_processos_gef_numero ON processos_gestao_escritorio_filizola(numero_processo);
CREATE INDEX idx_processos_gef_urgencia ON processos_gestao_escritorio_filizola(urgencia)
    WHERE urgencia = true;
CREATE INDEX idx_processos_gef_notificacao ON processos_gestao_escritorio_filizola(fase_kanban)
    WHERE fase_kanban IN ('DOC_PENDENTE', 'APROVACAO_GESTOR', 'PENDENCIA');

-- Trigger para atualizar dias_na_fase
CREATE OR REPLACE FUNCTION atualizar_dias_fase()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.fase_kanban <> OLD.fase_kanban THEN
        NEW.ultima_movimentacao_fase = NOW();
        NEW.dias_na_fase = 0;
    ELSIF OLD.fase_kanban = NEW.fase_kanban THEN
        NEW.dias_na_fase = EXTRACT(DAY FROM (NOW() - OLD.ultima_movimentacao_fase));
    END IF;
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_atualizar_dias_fase
    BEFORE UPDATE ON processos_gestao_escritorio_filizola
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_dias_fase();
```

### 1.5. Tabela: `documentos_gestao_escritorio_filizola`

```sql
CREATE TYPE tipo_documento AS ENUM (
    'RG', 'CNH', 'CPF', 'COMPROVANTE_RESIDENCIA',
    'TITULO_ELEITOR', 'CTPS', 'CADUNICO', 'NIS_NIT',
    'LAUDO_MEDICO', 'EXAME', 'ATESTADO', 'RECEITA',
    'CERTIDAO_NASCIMENTO', 'CERTIDAO_CASAMENTO', 'CERTIDAO_OBITO',
    'RG_FALECIDO', 'CPF_FALECIDO',
    'PROCURACAO', 'CONTRATO', 'OUTRO'
);

CREATE TYPE categoria_documento AS ENUM (
    'DADOS_PESSOAIS',
    'DOCUMENTOS_FAMILIA',
    'DOCUMENTOS_FALECIDO',
    'COMPROVANTE_RENDA',
    'DOCUMENTOS_MEDICOS',
    'DOCUMENTOS_TRABALHISTAS',
    'CONTRATOS',
    'OUTROS'
);

CREATE TYPE qualidade_documento AS ENUM (
    'LEGIVEL',
    'ILEGIVEL',
    'PENDENTE_ANALISE'
);

CREATE TABLE documentos_gestao_escritorio_filizola (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    processo_id UUID NOT NULL REFERENCES processos_gestao_escritorio_filizola(id) ON DELETE CASCADE,
    tipo_documento tipo_documento NOT NULL,
    categoria_documento categoria_documento NOT NULL,
    storage_path TEXT NOT NULL,
    nome_arquivo_original VARCHAR(255),
    tamanho_bytes INTEGER,
    mimetype VARCHAR(100),
    qualidade_documento qualidade_documento DEFAULT 'PENDENTE_ANALISE',
    metadados_ia JSONB,
    classificado_por_ia BOOLEAN DEFAULT false,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_documentos_gef_processo ON documentos_gestao_escritorio_filizola(processo_id);
CREATE INDEX idx_documentos_gef_tipo ON documentos_gestao_escritorio_filizola(tipo_documento);
CREATE INDEX idx_documentos_gef_pendente ON documentos_gestao_escritorio_filizola(classificado_por_ia)
    WHERE classificado_por_ia = false;
```

### 1.6. Tabela: `historico_inss_gestao_escritorio_filizola`

```sql
CREATE TYPE evento_inss AS ENUM (
    'EXIGENCIA',
    'PERICIA_AGENDADA',
    'PERICIA_REALIZADA',
    'DEFERIDO',
    'INDEFERIDO',
    'JUNTADA_INDEFERIMENTO',
    'RECURSO_JUNTADO'
);

CREATE TABLE historico_inss_gestao_escritorio_filizola (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    processo_id UUID NOT NULL REFERENCES processos_gestao_escritorio_filizola(id) ON DELETE CASCADE,
    evento evento_inss NOT NULL,
    conteudo_texto TEXT,
    data_evento_portal TIMESTAMPTZ,
    prazo_fatal DATE,
    storage_print_path TEXT,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_historico_gef_processo ON historico_inss_gestao_escritorio_filizola(processo_id);
CREATE INDEX idx_historico_gef_evento ON historico_inss_gestao_escritorio_filizola(evento);
CREATE INDEX idx_historico_gef_prazo ON historico_inss_gestao_escritorio_filizola(prazo_fatal)
    WHERE prazo_fatal IS NOT NULL;

-- Trigger: mover processo para PENDENCIA quando detectada exigência
CREATE OR REPLACE FUNCTION mover_para_pendencia_exigencia()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.evento = 'EXIGENCIA' THEN
        UPDATE processos_gestao_escritorio_filizola
        SET fase_kanban = 'PENDENCIA',
            urgencia = true
        WHERE id = NEW.processo_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_mover_pendencia_exigencia
    AFTER INSERT ON historico_inss_gestao_escritorio_filizola
    FOR EACH ROW
    EXECUTE FUNCTION mover_para_pendencia_exigencia();
```

### 1.7. Tabela: `exigencias_doc_gestao_escritorio_filizola` (Configurações)

```sql
CREATE TABLE exigencias_doc_gestao_escritorio_filizola (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tipo_beneficio tipo_beneficio NOT NULL,
    tipo_documento tipo_documento NOT NULL,
    obrigatorio BOOLEAN DEFAULT true,
    descricao TEXT,
    ordem_exibicao INTEGER DEFAULT 0,
    ativo BOOLEAN DEFAULT true,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tipo_beneficio, tipo_documento)
);

CREATE INDEX idx_exigencias_gef_beneficio ON exigencias_doc_gestao_escritorio_filizola(tipo_beneficio);

-- Dados iniciais (seed)
INSERT INTO exigencias_doc_gestao_escritorio_filizola (tipo_beneficio, tipo_documento, obrigatorio, descricao, ordem_exibicao) VALUES
    -- ==========================================
    -- AUXILIO DOENCA / APOSENTADORIA INVALIDEZ
    -- ==========================================
    ('AUXILIO_DOENCA', 'RG', true, 'Identidade do requerente', 1),
    ('AUXILIO_DOENCA', 'CPF', true, 'CPF do requerente', 2),
    ('AUXILIO_DOENCA', 'COMPROVANTE_RESIDENCIA', true, 'Comprovante de endereço atualizado', 3),
    ('AUXILIO_DOENCA', 'CTPS', true, 'Carteira de trabalho', 4),
    ('AUXILIO_DOENCA', 'TITULO_ELEITOR', true, 'Título de eleitor', 5),
    ('AUXILIO_DOENCA', 'LAUDO_MEDICO', true, 'Laudo de incapacidade', 6),

    -- ==========================================
    -- PENSAO POR MORTE
    -- ==========================================
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

    -- ==========================================
    -- BPC LOAS DEFICIENTE
    -- ==========================================
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

    -- ==========================================
    -- BPC LOAS IDOSO
    -- ==========================================
    ('BPC_LOAS_IDOSO', 'RG', true, 'Identidade do requerente', 1),
    ('BPC_LOAS_IDOSO', 'CPF', true, 'CPF do requerente', 2),
    ('BPC_LOAS_IDOSO', 'COMPROVANTE_RESIDENCIA', true, 'Comprovante de endereço atualizado', 3),
    ('BPC_LOAS_IDOSO', 'CERTIDAO_OBITO', false, 'Certidão de óbito (se aplicável)', 4),
    ('BPC_LOAS_IDOSO', 'TITULO_ELEITOR', true, 'Título de eleitor', 5),

    -- ==========================================
    -- APOSENTADORIA POR IDADE
    -- ==========================================
    ('APOSENTADORIA_IDADE', 'RG', true, 'Identidade do requerente', 1),
    ('APOSENTADORIA_IDADE', 'CPF', true, 'CPF do requerente', 2),
    ('APOSENTADORIA_IDADE', 'COMPROVANTE_RESIDENCIA', true, 'Comprovante de endereço atualizado', 3),
    ('APOSENTADORIA_IDADE', 'CTPS', true, 'Carteira de trabalho', 4),
    ('APOSENTADORIA_IDADE', 'TITULO_ELEITOR', true, 'Título de eleitor', 5),
    ('APOSENTADORIA_IDADE', 'NIS_NIT', true, 'Número do NIS/NIT (PIS/PASEP)', 6);
```

### 1.8. Tabela: `notificacoes_gestao_escritorio_filizola` (Log de envios)

```sql
CREATE TABLE notificacoes_gestao_escritorio_filizola (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    processo_id UUID REFERENCES processos_gestao_escritorio_filizola(id) ON DELETE SET NULL,
    telefone_destino VARCHAR(20) NOT NULL,
    mensagem TEXT NOT NULL,
    tipo_notificacao VARCHAR(50) NOT NULL,
    status_envio VARCHAR(20) DEFAULT 'PENDENTE',
    resposta_uazapi JSONB,
    agendado_para TIMESTAMPTZ,
    enviado_em TIMESTAMPTZ,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notificacoes_gef_status ON notificacoes_gestao_escritorio_filizola(status_envio);
CREATE INDEX idx_notificacoes_gef_agendamento ON notificacoes_gestao_escritorio_filizola(agendado_para);
```

---

## 2. Storage - Bucket Único

### 2.1. Estrutura do Bucket `documentos_processuais`

```
documentos_processuais/
├── clientes/{cliente_id}/
│   └── processos/{processo_id}/
│       ├── originais/
│       │   ├── {timestamp}_{nome_arquivo}
│       │   └── ...
│       └── processados/
│           ├── {documento_id}_convertido.pdf
│           └── ...
```

> **Nota:** A coluna `pasta_documentos_url` na tabela `processos_gestao_escritorio_filizola` armazena o caminho base (ex: `clientes/{cliente_id}/processos/{processo_id}/`) para mapear e exibir os documentos no frontend. A tabela `documentos_gestao_escritorio_filizola` armazena os metadados detalhados de cada arquivo.

### 2.2. Políticas RLS (Row Level Security)

```sql
-- Upload
CREATE POLICY "Usuários autenticados podem fazer upload"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'documentos_processuais');

-- Download
CREATE POLICY "Usuários autenticados podem fazer download"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'documentos_processuais');

-- Deletar
CREATE POLICY "Usuários autenticados podem deletar"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (bucket_id = 'documentos_processuais');
```

---

## 3. Edge Function - Notificações Diárias

### 3.1. `notificar-processos-criticos`

Arquivo: `supabase/functions/notificar-processos-criticos/index.ts`

- Busca processos nas fases críticas: `DOC_PENDENTE`, `APROVACAO_GESTOR`, `PENDENCIA`
- Gera mensagens personalizadas por fase via WhatsApp (UAZAPI)
- Salva log de cada envio na tabela `notificacoes_gestao_escritorio_filizola`
- Protegida por `CRON_SECRET` no header Authorization

### 3.2. Agendamento via pg_cron

```sql
CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.schedule(
    'notificar-processos-criticos-7h',
    '0 7 * * *',
    $$
    SELECT net.http_post(
        url := 'https://<PROJETO>.supabase.co/functions/v1/notificar-processos-criticos',
        headers := '{"Content-Type": "application/json", "Authorization": "Bearer <CRON_SECRET>"}'::jsonb,
        body := '{}'::jsonb
    );
    $$
);
```

---

## 4. Edge Function - Análise de Documentos com IA

### 4.1. `analisar-documentos`

Arquivo: `supabase/functions/analisar-documentos/index.ts`

**Propósito:** Quando o usuário faz upload de documentos de um processo, esta Edge Function usa IA via **OpenRouter** (que dá acesso a modelos como GPT-4o, Claude, etc.) para analisar cada documento, classificar o tipo e gerar um checklist do que foi entregue vs. o que falta.

**Fluxo:**

```
Upload de documentos
        │
        ▼
┌─────────────────────────────────┐
│  1. Recebe processo_id          │
│  2. Busca tipo_beneficio do     │
│     processo                    │
│  3. Busca exigencias_doc para   │
│     esse beneficio              │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│  4. Para cada documento:        │
│     - Baixa do Storage          │
│     - Envia para OpenRouter API │
│       (modelo com visão)        │
│     - Classifica tipo_documento │
│     - Avalia qualidade          │
│     - Extrai metadados (CID,    │
│       datas, nomes)             │
│     - Atualiza tabela documentos│
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│  5. Compara documentos          │
│     entregues com exigencias_doc│
│  6. Retorna checklist:          │
│     - ✅ Documentos entregues   │
│     - ❌ Documentos faltando    │
│     - ⚠️ Documentos ilegiveis   │
│  7. Atualiza fase do processo   │
│     (DOC_PENDENTE se falta algo)│
└─────────────────────────────────┘
```

**Estrutura da Edge Function:**

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const OPENROUTER_API_KEY = Deno.env.get('OPENROUTER_API_KEY')
const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions"

// Modelo com visão (vision) - pode ser trocado facilmente via OpenRouter
const AI_MODEL = Deno.env.get('AI_MODEL') || 'openai/gpt-4o'

serve(async (req) => {
    const { processo_id } = await req.json()

    const supabase = createClient(
        Deno.env.get('SUPABASE_URL')!,
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // 1. Buscar processo com tipo de benefício
    const { data: processo } = await supabase
        .from('processos_gestao_escritorio_filizola')
        .select('id, tipo_beneficio, cliente_id')
        .eq('id', processo_id)
        .single()

    // 2. Buscar documentos obrigatórios para esse benefício
    const { data: exigencias } = await supabase
        .from('exigencias_doc_gestao_escritorio_filizola')
        .select('*')
        .eq('tipo_beneficio', processo.tipo_beneficio)
        .eq('obrigatorio', true)

    // 3. Buscar documentos já enviados para esse processo
    const { data: documentos } = await supabase
        .from('documentos_gestao_escritorio_filizola')
        .select('*')
        .eq('processo_id', processo_id)

    // 4. Analisar cada documento com IA via OpenRouter
    const resultados = []
    for (const doc of documentos) {
        // Baixar arquivo do Storage
        const { data: arquivo } = await supabase.storage
            .from('documentos_processuais')
            .download(doc.storage_path)

        // Converter para base64
        const base64 = await arrayBufferToBase64(arquivo)

        // Enviar para OpenRouter classificar
        const classificacao = await classificarDocumento(
            base64,
            doc.mimetype,
            exigencias.map(e => e.tipo_documento)
        )

        // Atualizar documento com resultado da IA
        await supabase
            .from('documentos_gestao_escritorio_filizola')
            .update({
                tipo_documento: classificacao.tipo,
                qualidade_documento: classificacao.qualidade,
                metadados_ia: classificacao.metadados,
                classificado_por_ia: true
            })
            .eq('id', doc.id)

        resultados.push(classificacao)
    }

    // 5. Gerar checklist comparando entregues vs. exigidos
    const tiposEntregues = new Set(
        resultados.filter(r => r.qualidade === 'LEGIVEL')
            .map(r => r.tipo)
    )

    const checklist = exigencias.map(ex => ({
        documento: ex.tipo_documento,
        obrigatorio: ex.obrigatorio,
        status: tiposEntregues.has(ex.tipo_documento) ? 'ENTREGUE' : 'FALTANDO',
        ordem: ex.ordem_exibicao
    }))

    const temPendencia = checklist.some(c => c.status === 'FALTANDO')

    // 6. Atualizar fase do processo se necessário
    if (temPendencia) {
        await supabase
            .from('processos_gestao_escritorio_filizola')
            .update({ fase_kanban: 'DOC_PENDENTE' })
            .eq('id', processo_id)
    }

    return new Response(JSON.stringify({
        processo_id,
        checklist,
        documentos_analisados: resultados.length,
        tem_pendencia: temPendencia
    }), {
        headers: { 'Content-Type': 'application/json' }
    })
})

async function classificarDocumento(
    base64: string,
    mimetype: string,
    tiposEsperados: string[]
) {
    const prompt = `Analise este documento brasileiro e identifique:
1. O tipo do documento entre: ${tiposEsperados.join(', ')}
2. Se o documento está legível ou ilegível
3. Extraia metadados relevantes (nome, CPF, datas, CID se for laudo)

Responda APENAS em JSON válido, sem markdown: { "tipo": "RG", "qualidade": "LEGIVEL", "metadados": {} }`

    const response = await fetch(OPENROUTER_API_URL, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
            'HTTP-Referer': Deno.env.get('SUPABASE_URL') || '',
            'X-Title': 'D&F Gestao - Analise Documentos'
        },
        body: JSON.stringify({
            model: AI_MODEL,
            max_tokens: 1024,
            messages: [{
                role: 'user',
                content: [
                    {
                        type: 'image_url',
                        image_url: {
                            url: `data:${mimetype};base64,${base64}`
                        }
                    },
                    { type: 'text', text: prompt }
                ]
            }]
        })
    })

    const result = await response.json()
    const content = result.choices[0].message.content

    // Remover possiveis ```json``` do retorno
    const jsonStr = content.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim()
    return JSON.parse(jsonStr)
}

function arrayBufferToBase64(buffer: ArrayBuffer): Promise<string> {
    return new Promise((resolve) => {
        const bytes = new Uint8Array(buffer)
        let binary = ''
        for (const byte of bytes) binary += String.fromCharCode(byte)
        resolve(btoa(binary))
    })
}
```

### 4.2. Variáveis de ambiente adicionais

```env
# OpenRouter (acesso a múltiplos modelos de IA com visão)
OPENROUTER_API_KEY=sk-or-xxx...
AI_MODEL=openai/gpt-4o
```

> **Nota:** Via OpenRouter é possível trocar o modelo livremente: `openai/gpt-4o`, `anthropic/claude-sonnet-4`, `google/gemini-pro-vision`, etc. Basta alterar a variável `AI_MODEL`.

---

## 5. Variáveis de Ambiente (.env.local)

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJxxx...

# UAZAPI (WhatsApp)
NEXT_PUBLIC_UAZAPI_INSTANCE=120363xxxxx
UAZAPI_API_URL=https://api.uazapi.com
UAZAPI_TOKEN=seu_token_aqui
UAZAPI_WEBHOOK_SECRET=webhook_secret

# OpenRouter (análise de documentos com IA)
OPENROUTER_API_KEY=sk-or-xxx...
AI_MODEL=openai/gpt-4o

# Cron Secret
CRON_SECRET=secret_key_protecao
```

---

## 6. Integração Frontend-Backend

### 6.1. Arquivos a criar

| Arquivo | Descrição |
|---------|-----------|
| `src/lib/supabase/client.ts` | Cliente Supabase |
| `src/lib/types/database.ts` | Tipos TypeScript do schema |
| `src/lib/services/processos.ts` | CRUD de processos |
| `src/lib/services/clientes.ts` | CRUD de clientes |
| `src/lib/services/documentos.ts` | Upload/download/análise de documentos |
| `src/lib/services/historico-inss.ts` | CRUD de histórico INSS |
| `src/lib/services/notificacoes.ts` | Consulta de logs de notificação |

### 6.2. Dependência a instalar

```
npm install @supabase/supabase-js
```

---

## 7. Plano de Implementação (Fases)

### Fase 1: Setup do Supabase
- [ ] Criar projeto no Supabase Dashboard
- [ ] Instalar dependência `@supabase/supabase-js` no Next.js
- [ ] Criar arquivo `.env.local` com as chaves

### Fase 2: Migrations do Banco
- [ ] Criar arquivo SQL com todas as tabelas, tipos, triggers e índices
- [ ] Executar migration via Supabase Dashboard (SQL Editor)
- [ ] Inserir dados iniciais (exigencias_doc_gestao_escritorio_filizola)
- [ ] Verificar relacionamentos e RLS

### Fase 3: Storage
- [ ] Criar bucket `documentos_processuais` via Dashboard ou migration
- [ ] Configurar políticas de acesso RLS no bucket
- [ ] Testar upload/download

### Fase 4: Edge Function - Notificações
- [ ] Criar função `notificar-processos-criticos`
- [ ] Configurar variáveis de ambiente no Supabase (UAZAPI, CRON_SECRET)
- [ ] Configurar pg_cron para execução às 7h
- [ ] Testar envio manual via curl

### Fase 5: Edge Function - Análise de Documentos com IA
- [ ] Criar função `analisar-documentos`
- [ ] Configurar OPENROUTER_API_KEY e AI_MODEL no Supabase
- [ ] Integrar com OpenRouter (modelo com visão) para classificação
- [ ] Gerar checklist automático (entregue vs. faltando)
- [ ] Atualizar fase do processo automaticamente

### Fase 6: Camada de Serviços (Frontend)
- [ ] Criar `src/lib/supabase/client.ts`
- [ ] Criar `src/lib/types/database.ts`
- [ ] Criar services: processos, clientes, documentos, historico-inss, notificacoes

### Fase 7: Validação
- [ ] Testar fluxo completo (criar cliente > criar processo > mover fases)
- [ ] Testar upload de documentos + análise IA
- [ ] Testar notificações automáticas
- [ ] Ajustar RLS se necessário

---

## 8. Arquivos Críticos (Resumo)

| Arquivo | Descrição |
|---------|-----------|
| `supabase/migrations/001_initial_schema.sql` | Todas as tabelas e relacionamentos |
| `supabase/functions/notificar-processos-criticos/index.ts` | Edge Function de notificações WhatsApp |
| `supabase/functions/analisar-documentos/index.ts` | Edge Function de análise de documentos com IA (OpenRouter) |
| `src/lib/supabase/client.ts` | Cliente Supabase (novo) |
| `src/lib/types/database.ts` | Tipos TypeScript (novo) |
| `src/lib/services/processos.ts` | Service de processos (novo) |
| `src/lib/services/clientes.ts` | Service de clientes (novo) |
| `src/lib/services/documentos.ts` | Service de documentos (novo) |
