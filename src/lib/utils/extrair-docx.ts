import mammoth from 'mammoth'

export async function extrairHtmlDocx(arquivo: File): Promise<string> {
    const arrayBuffer = await arquivo.arrayBuffer()

    const resultado = await mammoth.convertToHtml({ arrayBuffer }, {
        // Remover imagens — o template contém apenas texto e formatação.
        // Logos e assinaturas ficam no cabeçalho/rodapé do documento final gerado,
        // não no conteúdo editável do template.
        convertImage: mammoth.images.imgElement(() => {
            return Promise.resolve({ src: '' })
        }),
    })

    // Limpar tags <img> e <figure> vazias geradas
    return resultado.value
        .replace(/<img[^>]*src=""\s*\/?>/gi, '')
        .replace(/<img[^>]*>/gi, '')
        .replace(/<figure[^>]*>[\s\S]*?<\/figure>/gi, '')
}

export async function extrairTextoDocx(arquivo: File): Promise<string> {
    const arrayBuffer = await arquivo.arrayBuffer()
    const resultado = await mammoth.extractRawText({ arrayBuffer })
    return resultado.value
}
