-- Tabela para vincular profissionais aos procedimentos que podem realizar
CREATE TABLE profissional_procedimento_agenda_inteligente_orus (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profissional_id UUID NOT NULL REFERENCES profissionais_agenda_inteligente_orus(id) ON DELETE CASCADE,
  procedimento_id UUID NOT NULL REFERENCES procedimentos_agenda_inteligente_orus(id) ON DELETE CASCADE,
  ativo BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(profissional_id, procedimento_id)
);

-- Índices para performance
CREATE INDEX idx_profissional_procedimento_profissional 
  ON profissional_procedimento_agenda_inteligente_orus(profissional_id) WHERE ativo = true;

CREATE INDEX idx_profissional_procedimento_procedimento 
  ON profissional_procedimento_agenda_inteligente_orus(procedimento_id) WHERE ativo = true;

-- Adicionar comentários
COMMENT ON TABLE profissional_procedimento_agenda_inteligente_orus IS 'Vínculo entre profissionais e procedimentos que podem realizar';
COMMENT ON COLUMN profissional_procedimento_agenda_inteligente_orus.profissional_id IS 'ID do profissional';
COMMENT ON COLUMN profissional_procedimento_agenda_inteligente_orus.procedimento_id IS 'ID do procedimento';
COMMENT ON COLUMN profissional_procedimento_agenda_inteligente_orus.ativo IS 'Status do vínculo (ativo/inativo)';;
