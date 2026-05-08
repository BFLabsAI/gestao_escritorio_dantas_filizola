-- Create table for API Brasil logs
CREATE TABLE public.fenapp_api_logs (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  empresa_id UUID REFERENCES public.fenapp_empresas(id),
  cnpj TEXT NOT NULL,
  operacao TEXT NOT NULL DEFAULT 'enriquecimento_cnpj',
  request_headers JSONB,
  request_body JSONB,
  response_status INTEGER,
  response_body JSONB,
  response_headers JSONB,
  tempo_execucao_ms INTEGER,
  sucesso BOOLEAN DEFAULT false,
  erro_descricao TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.fenapp_api_logs ENABLE ROW LEVEL SECURITY;

-- Create policies for public access
CREATE POLICY "Acesso público leitura logs" 
ON public.fenapp_api_logs 
FOR SELECT 
USING (true);

CREATE POLICY "Acesso público escrita logs" 
ON public.fenapp_api_logs 
FOR ALL 
USING (true);

-- Create index for better performance
CREATE INDEX idx_fenapp_api_logs_empresa_id ON public.fenapp_api_logs(empresa_id);
CREATE INDEX idx_fenapp_api_logs_cnpj ON public.fenapp_api_logs(cnpj);
CREATE INDEX idx_fenapp_api_logs_created_at ON public.fenapp_api_logs(created_at DESC);;
