import type { Documento, Pasta, Agrupamento } from '@/lib/types/database'
import { PASTAS_PROCESSO, PASTA_OUTROS } from '@/lib/types/database'

function documentoMatchPasta(doc: Documento, pasta: Pasta): boolean {
    const { mapeamento } = pasta
    const matchTipo = mapeamento.tipo_documento?.includes(doc.tipo_documento)
    const matchCategoria = mapeamento.categoria_documento?.includes(doc.categoria_documento)
    const excluido = mapeamento.excluidos?.includes(doc.tipo_documento)

    if (excluido) return false

    if (matchTipo) return true

    if (matchCategoria && !mapeamento.tipo_documento) return true

    return false
}

function documentosPorPasta(
    documentos: Documento[],
    pasta: Pasta,
    idsJaClassificados: Set<string>,
): { documentos: Documento[]; idsClassificados: Set<string> } {
    const idsClassificados = new Set<string>()

    const docs = documentos.filter((doc) => {
        if (idsJaClassificados.has(doc.id)) return false
        if (!documentoMatchPasta(doc, pasta)) return false
        idsClassificados.add(doc.id)
        return true
    })

    return { documentos: docs, idsClassificados }
}

function agruparSubpastas(
    documentos: Documento[],
    subpastas: Pasta[] | undefined,
    idsJaClassificados: Set<string>,
): Agrupamento[] {
    if (!subpastas) return []

    const resultado: Agrupamento[] = []
    const idsAcumulados = new Set(idsJaClassificados)

    for (const subpasta of subpastas) {
        const { documentos: docs, idsClassificados } = documentosPorPasta(documentos, subpasta, idsAcumulados)
        idsClassificados.forEach((id) => idsAcumulados.add(id))

        resultado.push({
            pasta: subpasta,
            documentos: docs,
            subpastas: [],
        })
    }

    return resultado
}

function pastaTemTipoDocumento(pasta: Pasta): boolean {
    return (pasta.mapeamento.tipo_documento?.length ?? 0) > 0
}

export function agruparDocumentosPorPasta(documentos: Documento[]): Agrupamento[] {
    if (documentos.length === 0) return []

    const resultado: Agrupamento[] = []
    const idsJaClassificados = new Set<string>()

    // Separar pastas: primeiro as que têm tipo_documento (mais específicas),
    // depois as que só usam categoria_documento (mais genéricas)
    const pastasComTipo = PASTAS_PROCESSO.filter(pastaTemTipoDocumento)
    const pastasSemTipo = PASTAS_PROCESSO.filter(p => !pastaTemTipoDocumento(p))

    const ordemProcessamento = [...pastasComTipo, ...pastasSemTipo]

    for (const pasta of ordemProcessamento) {
        const { documentos: docs, idsClassificados } = documentosPorPasta(documentos, pasta, idsJaClassificados)
        idsClassificados.forEach((id) => idsJaClassificados.add(id))

        const subpastasAgrupadas = agruparSubpastas(documentos, pasta.subpastas, idsJaClassificados)

        resultado.push({
            pasta,
            documentos: docs,
            subpastas: subpastasAgrupadas,
        })
    }

    // Documentos restantes vão para "Outros"
    const docsRestantes = documentos.filter((doc) => !idsJaClassificados.has(doc.id))
    if (docsRestantes.length > 0) {
        resultado.push({
            pasta: PASTA_OUTROS,
            documentos: docsRestantes,
            subpastas: [],
        })
    }

    return resultado.filter((grupo) => grupo.documentos.length > 0 || grupo.subpastas.some((s) => s.documentos.length > 0))
}
