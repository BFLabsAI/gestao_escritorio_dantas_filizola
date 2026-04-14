# Gestao Escritorio Dantas Filizola

Sistema de gestao para escritorio de advocacia previdenciaria. Gerencia clientes, processos, documentos, analise de documentos por IA e geracao automatica de peticoes em PDF.

## Tecnologias

- **Frontend:** Next.js 16, React 19, TypeScript, Tailwind CSS 4
- **UI:** Radix UI, Lucide Icons, shadcn/ui
- **Backend/Database:** Supabase (PostgreSQL, Storage, Edge Functions, Auth)
- **IA:** OpenRouter (vision models para analise de documentos)
- **PDF:** jsPDF (geracao de peticoes)
- **Deploy:** Vercel

## Funcionalidades

### Gestao de Clientes
- Cadastro de clientes com dados pessoais
- Visualizacao por cliente com historico de processos e peticoes

### Kanban de Processos
- Board visual com fases: Novo Processo > Documentacao > Doc. Pendente > Aprovacao Gestor > Pronto p/ Protocolo > Peticionado > Pendencia > Finalizado
- Drag-and-drop para mover processos entre fases
- Alteracao de fase diretamente na pagina do processo (dropdown)

### Documentos
- Upload de documentos (imagens, PDF, DOC, DOCX, TXT)
- Analise automatica por IA (classificacao, qualidade, extracao de dados)
- Checklist de exigencias documentais por tipo de beneficio
- Preview de imagens e abertura de PDFs diretamente no navegador

### Dados Extraidos
- Extracao automatica de dados dos documentos por IA
- Campos editaveis para correcao manual
- Variaveis utilizadas como `{{nome}}`, `{{cpf}}`, `{{der}}`, etc.

### Peticoes
- Templates de peticao por tipo de beneficio
- Geracao automatica de PDF com substituicao de variaveis
- Edicao de peticoes geradas com regeneracao de PDF
- Download seguro (blob URLs, sem exposicao de dados do Supabase)
- Tipos de peticao customizaveis pela interface (persistidos em localStorage)

### Notificacoes
- Envio de notificacoes via WhatsApp (API Uazapi)

## Estrutura do Projeto

```
src/
  app/
    board/           # Kanban board de processos
    clientes/        # Gestao de clientes
    dashboard/       # Dashboard principal
    kanban/          # Kanban alternativo
    novo-processo/   # Cadastro de novo processo
    peticoes/        # Gestao de templates de peticao
    processo/[id]/   # Detalhe do processo
    settings/        # Configuracoes
  components/
    layout/          # Layout do dashboard
    ui/              # Componentes shadcn/ui
  lib/
    services/        # Servicos (Supabase CRUD, IA, peticoes)
    supabase/        # Cliente Supabase
    types/           # Tipos TypeScript e labels
supabase/
  functions/         # Edge Functions (analise de documentos, notificacoes)
  migrations/        # Migrations SQL
```

## Configuracao

### Variaveis de ambiente

Crie um arquivo `.env.local` na raiz:

```
NEXT_PUBLIC_SUPABASE_URL=https://<projeto>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon_key>
```

### Instalacao

```bash
npm install
npm run dev
```

Acesse `http://localhost:3000`.

### Migrations

Para aplicar migrations no Supabase:

```bash
npx supabase db push
```

### Deploy

```bash
vercel --prod
```

## Tipos de Beneficio

| Slug | Label |
|------|-------|
| BPC_LOAS_DEFICIENTE | BPC/LOAS - Deficiente |
| BPC_LOAS_IDOSO | BPC/LOAS - Idoso |
| AUXILIO_DOENCA | Auxilio Doenca |
| APOSENTADORIA_INVALIDEZ | Aposentadoria por Invalidez |
| APOSENTADORIA_IDADE | Aposentadoria por Idade |
| APOSENTADORIA_ESPECIAL | Aposentadoria Especial |
| SALARIO_MATERNIDADE | Salario Maternidade |
| REVISIONAL | Revisional |
| PENSAO_MORTE | Pensao por Morte |

Tipos adicionais podem ser criados pela interface em `/peticoes`.
