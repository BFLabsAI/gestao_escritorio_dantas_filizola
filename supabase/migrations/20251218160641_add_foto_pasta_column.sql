
-- Add foto_pasta column to store the actual folder name in storage
ALTER TABLE empreendimentos_imobiliaria_rogaciano
ADD COLUMN IF NOT EXISTS foto_pasta TEXT;

-- Set default values based on known mappings
UPDATE empreendimentos_imobiliaria_rogaciano SET foto_pasta = 'ocean_ garden_cumbuco' WHERE nome = 'Ocean Garden Cumbuco';
UPDATE empreendimentos_imobiliaria_rogaciano SET foto_pasta = 'ocean_ garden_pdd' WHERE nome = 'Ocean Garden Porto das Dunas';
UPDATE empreendimentos_imobiliaria_rogaciano SET foto_pasta = 'beach_class_pdd' WHERE nome = 'Beach Class Porto das Dunas';
UPDATE empreendimentos_imobiliaria_rogaciano SET foto_pasta = 'beach_class_cumbuco' WHERE nome = 'Beach Class Cumbuco';
UPDATE empreendimentos_imobiliaria_rogaciano SET foto_pasta = 'Ihome_ aldeota' WHERE nome = 'Ihome Aldeota';
UPDATE empreendimentos_imobiliaria_rogaciano SET foto_pasta = 'biosphere' WHERE nome = 'Biosphere Conceito';
UPDATE empreendimentos_imobiliaria_rogaciano SET foto_pasta = 'mood_ praia' WHERE nome = 'Mood Praia';
UPDATE empreendimentos_imobiliaria_rogaciano SET foto_pasta = 'mood_shopping' WHERE nome = 'Mood Shopping';
UPDATE empreendimentos_imobiliaria_rogaciano SET foto_pasta = 'signa' WHERE nome = 'Signa Meireles';
UPDATE empreendimentos_imobiliaria_rogaciano SET foto_pasta = 'mansao_seara' WHERE nome = 'Mansão Seara';
UPDATE empreendimentos_imobiliaria_rogaciano SET foto_pasta = 'orizon' WHERE nome = 'Orizon';
UPDATE empreendimentos_imobiliaria_rogaciano SET foto_pasta = 'tribeca' WHERE nome = 'Tribeca';
UPDATE empreendimentos_imobiliaria_rogaciano SET foto_pasta = 'infinity' WHERE nome = 'Infinity';
UPDATE empreendimentos_imobiliaria_rogaciano SET foto_pasta = 'casa_macedo' WHERE nome = 'Casa Macêdo';
UPDATE empreendimentos_imobiliaria_rogaciano SET foto_pasta = 'bosque_cidade' WHERE nome = 'Bosque da Cidade';
UPDATE empreendimentos_imobiliaria_rogaciano SET foto_pasta = 'vista_coqueiral' WHERE nome = 'Vista Coqueiral';
;
