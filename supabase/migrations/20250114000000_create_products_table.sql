-- Create products table for medical procedures/services
CREATE TABLE IF NOT EXISTS products_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  category VARCHAR(100) NOT NULL CHECK (category IN ('injetavel', 'soroterapia', 'hormonal', 'estetico', 'suplemento', 'outro')),
  description TEXT,
  
  -- Pricing
  price DECIMAL(10,2),
  
  -- Product details
  brand VARCHAR(100),
  active_ingredient TEXT,
  concentration VARCHAR(100),
  unit_measure VARCHAR(50),
  
  -- Application details
  application_method VARCHAR(100),
  typical_dosage VARCHAR(255),
  duration_minutes INTEGER,
  
  -- Inventory
  requires_inventory BOOLEAN DEFAULT true,
  current_stock INTEGER DEFAULT 0,
  min_stock_alert INTEGER DEFAULT 5,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  -- Metadata
  tags TEXT[],
  notes TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- Create index for faster queries
CREATE INDEX idx_products_evoluxhub_category ON products_evoluxhub(category);
CREATE INDEX idx_products_evoluxhub_active ON products_evoluxhub(is_active);
CREATE INDEX idx_products_evoluxhub_name ON products_evoluxhub(name);
-- Enable RLS
ALTER TABLE products_evoluxhub ENABLE ROW LEVEL SECURITY;
-- RLS Policies
CREATE POLICY "Allow read access to all products"
  ON products_evoluxhub
  FOR SELECT
  USING (true);
CREATE POLICY "Allow insert for authenticated users"
  ON products_evoluxhub
  FOR INSERT
  WITH CHECK (true);
CREATE POLICY "Allow update for authenticated users"
  ON products_evoluxhub
  FOR UPDATE
  USING (true);
-- Insert sample products
INSERT INTO products_evoluxhub (name, category, description, price, brand, concentration, application_method, typical_dosage, duration_minutes, tags) VALUES
  ('Monjaro (Tirzepatida)', 'injetavel', 'Agonista duplo GIP/GLP-1 para tratamento de diabetes e controle de peso', 1200.00, 'Eli Lilly', '2.5mg/0.5ml', 'Subcutânea', '2.5mg a 15mg semanal', 5, ARRAY['emagrecimento', 'diabetes', 'injetavel']),
  
  ('Ozempic (Semaglutida)', 'injetavel', 'Agonista GLP-1 para controle glicêmico e perda de peso', 980.00, 'Novo Nordisk', '1mg/0.75ml', 'Subcutânea', '0.25mg a 2.4mg semanal', 5, ARRAY['emagrecimento', 'diabetes', 'glp1']),
  
  ('Saxenda (Liraglutida)', 'injetavel', 'GLP-1 de uso diário para controle de peso', 850.00, 'Novo Nordisk', '6mg/ml', 'Subcutânea', '0.6mg a 3mg diário', 3, ARRAY['emagrecimento', 'glp1', 'diario']),
  
  ('Soroterapia Wellness', 'soroterapia', 'Hidratação e reposição vitamínica completa', 350.00, NULL, 'Solução 500ml', 'Intravenosa', '500ml', 45, ARRAY['hidratacao', 'vitaminas', 'wellness']),
  
  ('Soroterapia Detox', 'soroterapia', 'Soro com antioxidantes e suporte hepático', 450.00, NULL, 'Solução 500ml', 'Intravenosa', '500ml', 60, ARRAY['detox', 'antioxidante', 'hepatico']),
  
  ('Soroterapia Performance', 'soroterapia', 'Soro para recuperação física e performance esportiva', 550.00, NULL, 'Solução 500ml', 'Intravenosa', '500ml', 50, ARRAY['performance', 'esporte', 'recuperacao']),
  
  ('Reposição Testosterona', 'hormonal', 'Terapia de reposição hormonal masculina', 380.00, NULL, 'Variável', 'Intramuscular', 'Conforme protocolo', 10, ARRAY['hormonal', 'trh', 'masculino']),
  
  ('Reposição Estrogênio + Progesterona', 'hormonal', 'TRH bioidêntica feminina', 420.00, NULL, 'Variável', 'Oral/Transdérmica', 'Conforme protocolo', 5, ARRAY['hormonal', 'trh', 'feminino', 'bioidêntico']),
  
  ('DHEA', 'hormonal', 'Dehidroepiandrosterona para modulação hormonal', 180.00, NULL, '25mg ou 50mg', 'Oral', '25-50mg ao dia', 2, ARRAY['hormonal', 'dhea', 'antienvelhecimento']),
  
  ('Toxina Botulínica (Botox)', 'estetico', 'Toxina tipo A para tratamento de rugas dinâmicas', 1500.00, 'Allergan', '100U', 'Intradérmica', '20-50U por região', 20, ARRAY['estetico', 'toxina', 'rugas']),
  
  ('Ácido Hialurônico 2ml', 'estetico', 'Preenchimento dérmico com ácido hialurônico', 1800.00, NULL, '2ml', 'Intradérmica', '1-2ml por região', 30, ARRAY['estetico', 'preenchimento', 'volume']),
  
  ('Bioestimulador de Colágeno', 'estetico', 'Estimulação de colágeno com ácido poli-L-láctico', 2200.00, 'Sculptra', '5ml reconstituído', 'Intradérmica profunda', '5ml', 40, ARRAY['estetico', 'colageno', 'rejuvenescimento']),
  
  ('Lipólise Enzimática', 'estetico', 'Enzima para redução de gordura localizada', 650.00, NULL, '10ml', 'Subcutânea', '5-10ml por sessão', 25, ARRAY['estetico', 'lipolise', 'gordura']),
  
  ('Vitamina D3 50.000UI', 'suplemento', 'Suplementação de vitamina D alta dose', 45.00, NULL, '50.000UI', 'Oral', '1 cápsula semanal', 1, ARRAY['vitamina', 'suplemento', 'ossos']),
  
  ('Complexo B Injetável', 'injetavel', 'Vitaminas do complexo B para energia e metabolismo', 80.00, NULL, '2ml', 'Intramuscular', '2ml', 5, ARRAY['vitamina', 'energia', 'metabolismo']);
-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_products_evoluxhub_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trigger_update_products_evoluxhub_updated_at
  BEFORE UPDATE ON products_evoluxhub
  FOR EACH ROW
  EXECUTE FUNCTION update_products_evoluxhub_updated_at();
