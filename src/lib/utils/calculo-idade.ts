export function calcularIdade(dataNascimento: string | Date): {
    anos: number
    meses: number
    dias: number
    textoFormatado: string
    textoPeticao: string
} | null {
    const nasc = typeof dataNascimento === 'string' ? new Date(dataNascimento) : dataNascimento

    if (isNaN(nasc.getTime())) return null

    const hoje = new Date()

    let anos = hoje.getFullYear() - nasc.getFullYear()
    let meses = hoje.getMonth() - nasc.getMonth()
    let dias = hoje.getDate() - nasc.getDate()

    if (dias < 0) {
        meses--
        dias += new Date(hoje.getFullYear(), hoje.getMonth(), 0).getDate()
    }

    if (meses < 0) {
        anos--
        meses += 12
    }

    const textoFormatado = `${anos} ano${anos !== 1 ? 's' : ''}, ${meses} mese${meses !== 1 ? 's' : ''} e ${dias} dia${dias !== 1 ? 's' : ''}`
    const textoPeticao = `${anos} anos de idade`

    return { anos, meses, dias, textoFormatado, textoPeticao }
}
