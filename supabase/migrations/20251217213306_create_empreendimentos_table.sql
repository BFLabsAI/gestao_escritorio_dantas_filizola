CREATE TABLE IF NOT EXISTS empreendimentos_imobiliaria_rogaciano (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamp with time zone DEFAULT now(),
  nome text NOT NULL,
  construtora text NOT NULL,
  status text NOT NULL,
  endereco text NOT NULL,
  cidade text NOT NULL,
  estado text NOT NULL,
  total_unidades integer NULL,
  metragens text NULL,
  dormitorios text NULL,
  vagas_garagem text NULL,
  amenidades text[] NULL,
  descricao text NULL,
  diferenciais text NULL
);;
