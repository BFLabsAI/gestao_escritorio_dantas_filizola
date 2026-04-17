// ============================================
// Tipos do banco de dados D&F Gestao Escritorio Filizola
// ============================================

export type TipoBeneficio = string

export type FaseKanban =
    | 'NOVO_PROCESSO'
    | 'DOCUMENTACAO'
    | 'DOC_PENDENTE'
    | 'APROVACAO_GESTOR'
    | 'PRONTO_PROTOCOLO'
    | 'PETICIONADO'
    | 'PENDENCIA'
    | 'PROCESSO_FINALIZADO'

export type TipoDocumento = string

export type CategoriaDocumento =
    | 'DADOS_PESSOAIS' | 'DOCUMENTOS_FAMILIA' | 'DOCUMENTOS_FALECIDO'
    | 'COMPROVANTE_RENDA' | 'DOCUMENTOS_MEDICOS' | 'DOCUMENTOS_TRABALHISTAS'
    | 'CONTRATOS' | 'OUTROS'

export type QualidadeDocumento = 'LEGIVEL' | 'ILEGIVEL' | 'PENDENTE_ANALISE'

export type EventoInss =
    | 'EXIGENCIA' | 'PERICIA_AGENDADA' | 'PERICIA_REALIZADA'
    | 'DEFERIDO' | 'INDEFERIDO' | 'JUNTADA_INDEFERIMENTO' | 'RECURSO_JUNTADO'

// ============================================
// Tabelas
// ============================================

export interface Perfil {
    id: string
    user_id: string | null
    nome_completo: string
    email: string
    telefone: string | null
    cargo: string
    ativo: boolean
    criado_em: string
    atualizado_em: string
}

export type Sexo = 'masculino' | 'feminino' | 'nao_informado'

export interface Cliente {
    id: string
    nome_completo: string
    cpf: string
    sexo: Sexo
    data_nascimento: string | null
    telefone: string | null
    email: string | null
    endereco: {
        logradouro?: string
        numero?: string
        complemento?: string
        bairro?: string
        cidade?: string
        uf?: string
        cep?: string
    } | null
    criado_em: string
    atualizado_em: string
    criado_por: string | null
}

export interface Processo {
    id: string
    numero_processo: string | null
    cliente_id: string
    tipo_beneficio: TipoBeneficio
    fase_kanban: FaseKanban
    numero_beneficio: string | null
    der: string | null
    data_protocolo: string | null
    observacoes: string | null
    urgencia: boolean
    dias_na_fase: number
    ultima_movimentacao_fase: string
    pasta_documentos_url: string | null
    criado_em: string
    atualizado_em: string
    criado_por: string | null
    cliente?: Cliente
}

export interface Documento {
    id: string
    processo_id: string
    tipo_documento: TipoDocumento
    categoria_documento: CategoriaDocumento
    storage_path: string
    nome_arquivo_original: string | null
    tamanho_bytes: number | null
    mimetype: string | null
    qualidade_documento: QualidadeDocumento
    metadados_ia: Record<string, unknown> | null
    classificado_por_ia: boolean
    criado_em: string
}

export interface HistoricoINSS {
    id: string
    processo_id: string
    evento: EventoInss
    conteudo_texto: string | null
    data_evento_portal: string | null
    prazo_fatal: string | null
    storage_print_path: string | null
    criado_em: string
}

export interface ExigenciaDoc {
    id: string
    tipo_beneficio: TipoBeneficio
    tipo_documento: TipoDocumento
    obrigatorio: boolean
    descricao: string | null
    ordem_exibicao: number
    ativo: boolean
    criado_em: string
}

export interface ModeloPeticao {
    id: string
    categoria: 'peticoes'
    tipo_beneficio: TipoBeneficio | null
    nome_arquivo: string
    nome_original: string
    storage_path: string
    public_url: string
    mime_type: string | null
    conteudo_template: string | null
    ativo: boolean
    ordem_exibicao: number
    variaveis_customizadas: string[] | null
    criado_em: string
}

export interface DadoExtraido {
    id: string
    processo_id: string
    cliente_id: string
    documento_origem_id: string | null
    tipo_documento_origem: string
    campo: string
    valor: string
    confianca: number | null
    status: 'extraido' | 'confirmado' | 'corrigido'
    criado_em: string
    atualizado_em: string
}

export interface PeticaoGerada {
    id: string
    processo_id: string
    cliente_id: string
    modelo_id: string | null
    tipo_beneficio: TipoBeneficio
    conteudo_gerado: string | null
    variaveis_usadas: Record<string, unknown>
    storage_path: string | null
    status_geracao: 'pendente' | 'concluido' | 'erro'
    criado_em: string
}

export interface Notificacao {
    id: string
    processo_id: string | null
    telefone_destino: string
    mensagem: string
    tipo_notificacao: string
    status_envio: string
    resposta_uazapi: Record<string, unknown> | null
    agendado_para: string | null
    enviado_em: string | null
    criado_em: string
}

// ============================================
// Labels para exibição
// ============================================

export const TIPO_BENEFICIO_LABELS: Record<string, string> = {
    BPC_LOAS_DEFICIENTE: 'BPC/LOAS - Deficiente',
    BPC_LOAS_IDOSO: 'BPC/LOAS - Idoso',
    AUXILIO_DOENCA: 'Auxílio Doença',
    APOSENTADORIA_INVALIDEZ: 'Aposentadoria por Invalidez',
    APOSENTADORIA_IDADE: 'Aposentadoria por Idade',
    APOSENTADORIA_ESPECIAL: 'Aposentadoria Especial',
    SALARIO_MATERNIDADE: 'Salário Maternidade',
    REVISIONAL: 'Revisional',
    PENSAO_MORTE: 'Pensão por Morte',
}

export const FASE_KANBAN_LABELS: Record<FaseKanban, string> = {
    NOVO_PROCESSO: 'Novo Processo',
    DOCUMENTACAO: 'Documentação',
    DOC_PENDENTE: 'Doc. Pendente',
    APROVACAO_GESTOR: 'Aprovação Gestor',
    PRONTO_PROTOCOLO: 'Pronto p/ Protocolo',
    PETICIONADO: 'Peticionado',
    PENDENCIA: 'Pendência',
    PROCESSO_FINALIZADO: 'Finalizado',
}

export const FASE_KANBAN_COLORS: Record<FaseKanban, string> = {
    NOVO_PROCESSO: 'bg-blue-500/10 text-blue-400 border-blue-500/20',
    DOCUMENTACAO: 'bg-yellow-500/10 text-yellow-400 border-yellow-500/20',
    DOC_PENDENTE: 'bg-orange-500/10 text-orange-400 border-orange-500/20',
    APROVACAO_GESTOR: 'bg-purple-500/10 text-purple-400 border-purple-500/20',
    PRONTO_PROTOCOLO: 'bg-[#FACC15]/10 text-[#FACC15] border-[#FACC15]/20',
    PETICIONADO: 'bg-cyan-500/10 text-cyan-400 border-cyan-500/20',
    PENDENCIA: 'bg-red-500/10 text-red-400 border-red-500/20',
    PROCESSO_FINALIZADO: 'bg-green-500/10 text-green-400 border-green-500/20',
}

export const TIPO_DOCUMENTO_LABELS: Record<string, string> = {
    RG: 'Identidade (RG)',
    CNH: 'CNH',
    CPF: 'CPF',
    COMPROVANTE_RESIDENCIA: 'Comprovante de Endereço',
    TITULO_ELEITOR: 'Título de Eleitor',
    CTPS: 'Carteira de Trabalho (CTPS)',
    CADUNICO: 'Cadastro Único (CadÚnico)',
    NIS_NIT: 'NIS/NIT',
    LAUDO_MEDICO: 'Laudo Médico',
    EXAME: 'Exame',
    ATESTADO: 'Atestado',
    RECEITA: 'Receita Médica',
    CERTIDAO_NASCIMENTO: 'Certidão de Nascimento',
    CERTIDAO_CASAMENTO: 'Certidão de Casamento',
    CERTIDAO_OBITO: 'Certidão de Óbito',
    RG_FALECIDO: 'Identidade do Falecido',
    CPF_FALECIDO: 'CPF do Falecido',
    PROCURACAO: 'Procuração',
    CONTRATO: 'Contrato',
    OUTRO: 'Outro',
}

export function formatarLabelDinamico(valor: string | null | undefined) {
    if (!valor) return ''

    const texto = valor
        .replace(/[_-]+/g, ' ')
        .trim()

    if (!texto) return ''

    return texto
        .toLowerCase()
        .replace(/\b\w/g, (letra) => letra.toUpperCase())
}

export function getTipoBeneficioLabel(tipo: string | null | undefined) {
    if (!tipo) return ''
    return TIPO_BENEFICIO_LABELS[tipo] ?? formatarLabelDinamico(tipo)
}

export function getTipoDocumentoLabel(tipo: string | null | undefined) {
    if (!tipo) return ''
    return TIPO_DOCUMENTO_LABELS[tipo] ?? formatarLabelDinamico(tipo)
}

// ============================================
// Campos de extração por tipo de documento
// ============================================

export const CAMPOS_EXTRACAO: Record<string, string[]> = {
    RG: ['nome_completo', 'cpf', 'data_nascimento', 'naturalidade', 'uf_naturalidade', 'rg_numero', 'orgao_expedidor'],
    CNH: ['nome_completo', 'cpf', 'data_nascimento', 'endereco_completo', 'cnh_numero', 'validade'],
    CPF: ['cpf', 'nome_completo'],
    COMPROVANTE_RESIDENCIA: ['logradouro', 'numero', 'complemento', 'bairro', 'cidade', 'uf', 'cep', 'endereco_completo'],
    CTPS: ['nome_completo', 'cpf', 'data_nascimento', 'ctps_numero', 'serie'],
    CERTIDAO_NASCIMENTO: ['nome_completo', 'data_nascimento', 'nome_mae', 'nome_pai', 'cartorio', 'registro'],
    LAUDO_MEDICO: ['cid', 'diagnostico', 'data_laudo', 'medico', 'crm'],
    ATESTADO: ['conteudo_texto', 'data_atestado', 'medico'],
    RECEITA: ['medicamento', 'posologia', 'data_receita', 'medico'],
    CERTIDAO_OBITO: ['nome_falecido', 'data_obito', 'cartorio'],
    TITULO_ELEITOR: ['nome_completo', 'titulo_numero', 'zona', 'secao'],
    EXAME: ['conteudo_texto', 'data_exame', 'medico', 'tipo_exame'],
    CERTIDAO_CASAMENTO: ['nome_conjuge1', 'nome_conjuge2', 'data_casamento', 'cartorio'],
}

export const CAMPO_LABELS: Record<string, string> = {
    nome_completo: 'Nome Completo',
    cpf: 'CPF',
    data_nascimento: 'Data de Nascimento',
    naturalidade: 'Naturalidade',
    uf_naturalidade: 'UF Naturalidade',
    rg_numero: 'Número do RG',
    orgao_expedidor: 'Órgão Expedidor',
    cnh_numero: 'Número CNH',
    validade: 'Validade',
    logradouro: 'Logradouro',
    numero: 'Número',
    complemento: 'Complemento',
    bairro: 'Bairro',
    cidade: 'Cidade',
    uf: 'UF',
    cep: 'CEP',
    endereco_completo: 'Endereço Completo',
    ctps_numero: 'Número CTPS',
    serie: 'Série',
    nome_mae: 'Nome da Mãe',
    nome_pai: 'Nome do Pai',
    cartorio: 'Cartório',
    registro: 'Registro',
    cid: 'CID',
    diagnostico: 'Diagnóstico',
    data_laudo: 'Data do Laudo',
    medico: 'Médico',
    crm: 'CRM',
    conteudo_texto: 'Conteúdo',
    data_atestado: 'Data do Atestado',
    medicamento: 'Medicamento',
    posologia: 'Posologia',
    data_receita: 'Data da Receita',
    nome_falecido: 'Nome do Falecido',
    data_obito: 'Data do Óbito',
    titulo_numero: 'Número do Título',
    zona: 'Zona',
    secao: 'Seção',
    data_exame: 'Data do Exame',
    tipo_exame: 'Tipo de Exame',
    nome_conjuge1: 'Nome do Cônjuge 1',
    nome_conjuge2: 'Nome do Cônjuge 2',
    data_casamento: 'Data do Casamento',
}
