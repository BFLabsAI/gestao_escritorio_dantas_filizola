// Mapa de palavras que variam por gênero
// Sintaxe no template: {{palavra@}} - substitui pela forma correta conforme sexo
const PALAVRAS_GENERO: Record<string, { masculino: string; feminino: string }> = {
    solteiro: { masculino: 'solteiro', feminino: 'solteira' },
    casado: { masculino: 'casado', feminino: 'casada' },
    divorciado: { masculino: 'divorciado', feminino: 'divorciada' },
    viuvo: { masculino: 'viúvo', feminino: 'viúva' },
    separado: { masculino: 'separado', feminino: 'separada' },
    requerente: { masculino: 'requerente', feminino: 'requerente' },
    segurado: { masculino: 'segurado', feminino: 'segurada' },
    beneficiario: { masculino: 'beneficiário', feminino: 'beneficiária' },
    inscrito: { masculino: 'inscrito', feminino: 'inscrita' },
    aposentado: { masculino: 'aposentado', feminino: 'aposentada' },
    contribuinte: { masculino: 'contribuinte', feminino: 'contribuinte' },
    falecido: { masculino: 'falecido', feminino: 'falecida' },
    autor: { masculino: 'autor', feminino: 'autora' },
    dependente: { masculino: 'dependente', feminino: 'dependente' },
    trabalhador: { masculino: 'trabalhador', feminino: 'trabalhadora' },
    empregado: { masculino: 'empregado', feminino: 'empregada' },
    desempregado: { masculino: 'desempregado', feminino: 'desempregada' },
    assistido: { masculino: 'assistido', feminino: 'assistida' },
    qualificado: { masculino: 'qualificado', feminino: 'qualificada' },
    incapaz: { masculino: 'incapaz', feminino: 'incapaz' },
    idoso: { masculino: 'idoso', feminino: 'idosa' },
    pobre: { masculino: 'pobre', feminino: 'pobre' },
    portador: { masculino: 'portador', feminino: 'portadora' },
    residente: { masculino: 'residente', feminino: 'residente' },
    domiciliado: { masculino: 'domiciliado', feminino: 'domiciliada' },
    maior: { masculino: 'maior', feminino: 'maior' },
    menor: { masculino: 'menor', feminino: 'menor' },
    conhecido: { masculino: 'conhecido', feminino: 'conhecida' },
    titular: { masculino: 'titular', feminino: 'titular' },
    nascido: { masculino: 'nascido', feminino: 'nascida' },
    procedente: { masculino: 'procedente', feminino: 'procedente' },
    improcedente: { masculino: 'improcedente', feminino: 'improcedente' },
}

/**
 * Adapta palavras no template conforme o sexo do cliente.
 * Sintaxe: {{palavra@}} ex: {{solteiro@}}, {{segurado@}}
 * Substitui pela forma masculina ou feminina da palavra.
 */
export function adaptarGenero(template: string, sexo: string): string {
    if (sexo === 'nao_informado' || (sexo !== 'masculino' && sexo !== 'feminino')) return template

    return template.replace(/\{\{(\w+)@\}\}/g, (match, palavra: string) => {
        const entrada = PALAVRAS_GENERO[palavra.toLowerCase()]
        if (!entrada) return match // Mantém {{palavra@}} se não encontrada
        return entrada[sexo]
    })
}

/**
 * Retorna a lista de palavras disponíveis para adaptação de gênero
 */
export function getPalavrasGenero(): Record<string, { masculino: string; feminino: string }> {
    return { ...PALAVRAS_GENERO }
}
