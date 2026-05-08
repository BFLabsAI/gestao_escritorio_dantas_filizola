-- Tabela principal de empresas
CREATE TABLE public.fenapp_empresas (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  nome_empresa TEXT NOT NULL,
  cnpj TEXT NOT NULL UNIQUE,
  razao_social TEXT,
  estado TEXT,
  cidade TEXT,
  endereco_completo TEXT,
  cep TEXT,
  telefone1 TEXT,
  telefone2 TEXT,
  email TEXT,
  situacao_cadastral TEXT,
  data_inicio_atividades DATE,
  cnae_principal TEXT,
  porte_empresa TEXT,
  status_enriquecimento TEXT DEFAULT 'pendente' CHECK (status_enriquecimento IN ('pendente', 'enriquecido', 'erro')),
  dados_api_brasil JSONB, -- armazena resposta completa da API
  arquivo_upload TEXT, -- nome do arquivo de upload
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Tabela de sócios das empresas
CREATE TABLE public.fenapp_socios (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  empresa_id UUID NOT NULL REFERENCES public.fenapp_empresas(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  cargo TEXT,
  qualificacao_codigo TEXT,
  qualificacao_descricao TEXT,
  cpf_parcial TEXT, -- CPF mascarado da API Brasil
  cpf_completo TEXT, -- CPF completo quando descoberto
  data_entrada_sociedade DATE,
  faixa_etaria TEXT,
  origem_cpf TEXT DEFAULT 'api_brasil' CHECK (origem_cpf IN ('api_brasil', 'ocr', 'busca_manual', 'validado')),
  score_stakeholder INTEGER DEFAULT 0,
  dados_api_brasil JSONB, -- dados completos do sócio da API
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Tabela de telefones dos sócios
CREATE TABLE public.fenapp_telefones (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  socio_id UUID NOT NULL REFERENCES public.fenapp_socios(id) ON DELETE CASCADE,
  telefone TEXT NOT NULL, -- formato 55ddd9xxxxxxxx
  ddd TEXT,
  numero TEXT,
  origem TEXT DEFAULT 'api_brasil' CHECK (origem IN ('api_brasil', 'manual', 'empresa')),
  whatsapp_ativo BOOLEAN DEFAULT false,
  numero_valido BOOLEAN DEFAULT true,
  status_envio TEXT DEFAULT 'pendente' CHECK (status_envio IN ('pendente', 'enviado', 'erro', 'respondido')),
  dt_envio TIMESTAMP WITH TIME ZONE,
  resposta_recebida BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Tabela de leads capturados
CREATE TABLE public.fenapp_leads (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  nome TEXT NOT NULL,
  telefone TEXT,
  email TEXT,
  associacao TEXT,
  cargo TEXT,
  origem TEXT DEFAULT 'site' CHECK (origem IN ('disparo', 'site', 'webinario')),
  empresa_id UUID REFERENCES public.fenapp_empresas(id), -- vinculação quando possível
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  utm_content TEXT,
  utm_term TEXT,
  status TEXT DEFAULT 'novo' CHECK (status IN ('novo', 'qualificado', 'reuniao', 'convertido')),
  observacoes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Tabela de uploads OCR
CREATE TABLE public.fenapp_uploads_ocr (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  nome_arquivo TEXT NOT NULL,
  empresa_id UUID REFERENCES public.fenapp_empresas(id),
  socio_id UUID REFERENCES public.fenapp_socios(id),
  dados_extraidos JSONB, -- dados brutos do OCR
  validado BOOLEAN DEFAULT false,
  path_arquivo TEXT, -- caminho no storage
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Tabela para controle de processamento em lote
CREATE TABLE public.fenapp_processamento_lote (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tipo TEXT NOT NULL CHECK (tipo IN ('enriquecimento_cnpj', 'busca_telefones')),
  status TEXT DEFAULT 'iniciado' CHECK (status IN ('iniciado', 'processando', 'concluido', 'erro')),
  total_registros INTEGER DEFAULT 0,
  processados INTEGER DEFAULT 0,
  com_sucesso INTEGER DEFAULT 0,
  com_erro INTEGER DEFAULT 0,
  detalhes JSONB,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS nas tabelas
ALTER TABLE public.fenapp_empresas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fenapp_socios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fenapp_telefones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fenapp_leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fenapp_uploads_ocr ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fenapp_processamento_lote ENABLE ROW LEVEL SECURITY;

-- Políticas RLS (acesso público por enquanto, depois pode ser refinado)
CREATE POLICY "Acesso público leitura empresas" ON public.fenapp_empresas FOR SELECT USING (true);
CREATE POLICY "Acesso público escrita empresas" ON public.fenapp_empresas FOR ALL USING (true);

CREATE POLICY "Acesso público leitura socios" ON public.fenapp_socios FOR SELECT USING (true);
CREATE POLICY "Acesso público escrita socios" ON public.fenapp_socios FOR ALL USING (true);

CREATE POLICY "Acesso público leitura telefones" ON public.fenapp_telefones FOR SELECT USING (true);
CREATE POLICY "Acesso público escrita telefones" ON public.fenapp_telefones FOR ALL USING (true);

CREATE POLICY "Acesso público leitura leads" ON public.fenapp_leads FOR SELECT USING (true);
CREATE POLICY "Acesso público escrita leads" ON public.fenapp_leads FOR ALL USING (true);

CREATE POLICY "Acesso público leitura uploads" ON public.fenapp_uploads_ocr FOR SELECT USING (true);
CREATE POLICY "Acesso público escrita uploads" ON public.fenapp_uploads_ocr FOR ALL USING (true);

CREATE POLICY "Acesso público leitura lote" ON public.fenapp_processamento_lote FOR SELECT USING (true);
CREATE POLICY "Acesso público escrita lote" ON public.fenapp_processamento_lote FOR ALL USING (true);

-- Triggers para updated_at
CREATE TRIGGER update_fenapp_empresas_updated_at
BEFORE UPDATE ON public.fenapp_empresas
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_fenapp_socios_updated_at
BEFORE UPDATE ON public.fenapp_socios
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_fenapp_leads_updated_at
BEFORE UPDATE ON public.fenapp_leads
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_fenapp_processamento_lote_updated_at
BEFORE UPDATE ON public.fenapp_processamento_lote
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Índices para performance
CREATE INDEX idx_fenapp_empresas_cnpj ON public.fenapp_empresas(cnpj);
CREATE INDEX idx_fenapp_empresas_status ON public.fenapp_empresas(status_enriquecimento);
CREATE INDEX idx_fenapp_socios_empresa_id ON public.fenapp_socios(empresa_id);
CREATE INDEX idx_fenapp_telefones_socio_id ON public.fenapp_telefones(socio_id);
CREATE INDEX idx_fenapp_telefones_status ON public.fenapp_telefones(status_envio);
CREATE INDEX idx_fenapp_leads_origem ON public.fenapp_leads(origem);
CREATE INDEX idx_fenapp_leads_status ON public.fenapp_leads(status);;
