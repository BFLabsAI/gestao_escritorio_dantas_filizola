-- Create the fichas_tecnicas_vendas table
CREATE TABLE public.fichas_tecnicas_vendas (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT now(),
  nome_vendedor text NOT NULL,
  nome_cliente text NOT NULL,
  telefone_cliente text NOT NULL,
  segmento_cliente text NOT NULL,
  link_gravacao text NOT NULL,
  
  -- Etapa 1: Análise de Precisão
  etapa1_faturamento text NOT NULL,
  etapa1_funcao text NOT NULL,
  
  -- Etapa 2: Diagnóstico das Emoções
  etapa2_dores_problemas text NOT NULL,
  etapa2_dores_desafios text NOT NULL,
  etapa2_dores_ppp text NOT NULL,
  etapa2_dores_gaps text NOT NULL,
  etapa2_sonhos_meta text NOT NULL,
  etapa2_sonhos_crescimento_pct text NOT NULL,
  etapa2_sonhos_tempo_lucro text NOT NULL,
  
  -- Etapa 3: Apresentação da Solução
  etapa3_topicos_abordados text[] NOT NULL,
  etapa3_principal_interesse text NOT NULL,
  etapa3_notas text NOT NULL,
  
  -- Etapa 4: Quebra de Objeção
  etapa4_prova_social text NOT NULL,
  etapa4_pilar_autoridade text[] NOT NULL,
  etapa4_detalhes_autoridade text NOT NULL,
  etapa4_sistema_proprio text NOT NULL,
  
  -- Etapa 5: Fechamento
  etapa5_resposta_ancoragem text NOT NULL,
  etapa5_bonus_ofertado text[] NOT NULL,
  etapa5_outros_bonus text NOT NULL,
  etapa5_notas_fechamento text NOT NULL,
  etapa5_fechou_na_call boolean NOT NULL DEFAULT false,
  
  -- Status e Valor
  status_negocio text NOT NULL DEFAULT 'Em Negociação' CHECK (status_negocio IN ('Em Negociação', 'Ganho', 'Perdido')),
  valor_negocio decimal NOT NULL DEFAULT 0
);

-- Enable Row Level Security
ALTER TABLE public.fichas_tecnicas_vendas ENABLE ROW LEVEL SECURITY;

-- Create policies to allow public access (adjust according to your needs)
CREATE POLICY "Allow all operations on fichas_tecnicas_vendas" 
ON public.fichas_tecnicas_vendas 
FOR ALL 
USING (true) 
WITH CHECK (true);

-- Create index for better performance
CREATE INDEX idx_fichas_tecnicas_vendas_created_at ON public.fichas_tecnicas_vendas(created_at DESC);
CREATE INDEX idx_fichas_tecnicas_vendas_status ON public.fichas_tecnicas_vendas(status_negocio);;
