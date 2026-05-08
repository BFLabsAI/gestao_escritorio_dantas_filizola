-- Create the investment table for Carro Perfeito campaign
CREATE TABLE IF NOT EXISTS public.investimento_diario_carro_perfeito (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  dia INT NOT NULL,
  mes TEXT NOT NULL,
  ano INT NOT NULL,
  valor_investido_geral DECIMAL(10, 2) DEFAULT 0,
  valor_investido_demanda DECIMAL(10, 2) DEFAULT 0,
  valor_investido_discovery DECIMAL(10, 2) DEFAULT 0
);

-- Create the leads table for Carro Perfeito campaign
CREATE TABLE IF NOT EXISTS public.leads_carro_perfeito (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  telefone TEXT NOT NULL,
  email TEXT,
  ja_trabalha TEXT,
  conhece_cp TEXT,
  aluno_cp BOOLEAN,
  utm_source TEXT,
  utm_campaign TEXT,
  utm_medium TEXT,
  utm_content TEXT,
  utm_term TEXT,
  url TEXT,
  funil_cadastro TEXT NOT NULL,
  data_cadastro TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS on both tables
ALTER TABLE public.investimento_diario_carro_perfeito ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leads_carro_perfeito ENABLE ROW LEVEL SECURITY;

-- Create policies for public access (as requested for dashboard)
CREATE POLICY "Public can view investment data" 
ON public.investimento_diario_carro_perfeito 
FOR SELECT 
USING (true);

CREATE POLICY "Public can insert investment data" 
ON public.investimento_diario_carro_perfeito 
FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Public can update investment data" 
ON public.investimento_diario_carro_perfeito 
FOR UPDATE 
USING (true);

CREATE POLICY "Public can view leads data" 
ON public.leads_carro_perfeito 
FOR SELECT 
USING (true);

CREATE POLICY "Public can insert leads data" 
ON public.leads_carro_perfeito 
FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Public can update leads data" 
ON public.leads_carro_perfeito 
FOR UPDATE 
USING (true);

-- Create indexes for better performance
CREATE INDEX idx_leads_carro_perfeito_data_cadastro ON public.leads_carro_perfeito(data_cadastro);
CREATE INDEX idx_leads_carro_perfeito_funil ON public.leads_carro_perfeito(funil_cadastro);
CREATE INDEX idx_leads_carro_perfeito_utm_source ON public.leads_carro_perfeito(utm_source);
CREATE INDEX idx_leads_carro_perfeito_utm_campaign ON public.leads_carro_perfeito(utm_campaign);
CREATE INDEX idx_leads_carro_perfeito_utm_content ON public.leads_carro_perfeito(utm_content);

CREATE INDEX idx_investimento_diario_created_at ON public.investimento_diario_carro_perfeito(created_at);
CREATE INDEX idx_investimento_diario_date ON public.investimento_diario_carro_perfeito(ano, mes, dia);;
