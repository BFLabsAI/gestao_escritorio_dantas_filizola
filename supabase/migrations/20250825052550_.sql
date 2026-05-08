-- Adicionar campo de status de enriquecimento na tabela de sócios
ALTER TABLE public.fenapp_socios 
ADD COLUMN status_enriquecimento text DEFAULT 'pendente';

-- Criar comentário no campo
COMMENT ON COLUMN public.fenapp_socios.status_enriquecimento IS 'Status do enriquecimento de dados: pendente, enriquecido, erro';

-- Atualizar sócios que já têm CPF completo como enriquecidos
UPDATE public.fenapp_socios 
SET status_enriquecimento = 'enriquecido' 
WHERE cpf_completo IS NOT NULL AND cpf_completo != '';;
