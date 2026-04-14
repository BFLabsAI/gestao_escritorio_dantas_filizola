"use client"

import { useEffect, useMemo, useRef, useState } from "react"
import DashboardLayout from "@/components/layout/dashboard-layout"
import {
    Save,
    Trash2,
    FileText,
    Loader2,
    CheckCircle2,
    Eye,
    ChevronDown,
    ChevronUp,
    Copy,
} from "lucide-react"
import {
    TIPO_BENEFICIO_LABELS,
    getTipoBeneficioLabel,
} from "@/lib/types/database"
import type { ModeloPeticao } from "@/lib/types/database"
import {
    buscarModelosPeticao,
    salvarModeloPeticao,
    deletarModeloPeticao,
    VARIAVEIS_DISPONIVEIS,
} from "@/lib/services/peticoes"

// Chave para tipos customizados no localStorage
const TIPOS_BENEFICIO_CUSTOM_KEY = 'tipos_beneficio_custom'

// Carregar tipos customizados do localStorage
function carregarTiposCustomizados(): Record<string, string> {
    if (typeof window === 'undefined') return {}
    try {
        const stored = localStorage.getItem(TIPOS_BENEFICIO_CUSTOM_KEY)
        return stored ? JSON.parse(stored) : {}
    } catch {
        return {}
    }
}

// Salvar tipos customizados no localStorage
function salvarTiposCustomizados(tipos: Record<string, string>) {
    if (typeof window === 'undefined') return
    localStorage.setItem(TIPOS_BENEFICIO_CUSTOM_KEY, JSON.stringify(tipos))
}

// Gerar slug a partir do nome
function gerarSlug(nome: string): string {
    return nome
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .toUpperCase()
        .replace(/[^A-Z0-9]/g, '_')
}

export default function PeticoesPage() {
    const [modelos, setModelos] = useState<ModeloPeticao[]>([])
    const [carregando, setCarregando] = useState(true)
    const [salvando, setSalvando] = useState<string | null>(null)
    const [deletando, setDeletando] = useState<string | null>(null)
    const [mensagemErro, setMensagemErro] = useState("")
    const [mensagemSucesso, setMensagemSucesso] = useState("")
    const [showVariaveis, setShowVariaveis] = useState(false)
    const [editando, setEditando] = useState<string | null>(null)
    const [templateText, setTemplateText] = useState("")
    const textareaRef = useRef<HTMLTextAreaElement>(null)
    const [tiposCustomizados, setTiposCustomizados] = useState<Record<string, string>>(() => carregarTiposCustomizados())
    const [mostrarDialogNovoTipo, setMostrarDialogNovoTipo] = useState(false)
    const [novoTipoNome, setNovoTipoNome] = useState('')
    const [mostrarDialogRemoverTipo, setMostrarDialogRemoverTipo] = useState(false)
    const [tipoParaRemover, setTipoParaRemover] = useState<string | null>(null)

    const carregarModelos = async () => {
        setCarregando(true)
        setMensagemErro("")

        const { modelos: data, error } = await buscarModelosPeticao()

        if (error) {
            setMensagemErro(error.message)
        } else {
            setModelos(data ?? [])
        }

        setCarregando(false)
    }

    useEffect(() => {
        carregarModelos()
    }, [])

    function getLabelComCustom(tipo: string): string {
        if (tiposCustomizados[tipo]) return tiposCustomizados[tipo]
        return getTipoBeneficioLabel(tipo)
    }

    const beneficiosDisponiveis = useMemo(() => {
        const staticos = Object.keys(TIPO_BENEFICIO_LABELS)
        const customizados = Object.keys(tiposCustomizados)
        const existentes = modelos.map((m) => m.tipo_beneficio).filter(Boolean) as string[]
        const todos = Array.from(new Set([...staticos, ...customizados, ...existentes]))
        return todos.sort((a, b) => getLabelComCustom(a).localeCompare(getLabelComCustom(b)))
    }, [modelos, tiposCustomizados])

    const modelosPorBeneficio = useMemo(() => {
        return beneficiosDisponiveis.map((tipo) => {
            const modeloAtivo = modelos.find(
                (m) => m.tipo_beneficio === tipo && m.ativo
            )
            const todosModelos = modelos.filter((m) => m.tipo_beneficio === tipo)

            return {
                tipo,
                label: getLabelComCustom(tipo),
                modeloAtivo: modeloAtivo ?? null,
                total: todosModelos.length,
            }
        })
    }, [beneficiosDisponiveis, modelos])

    function handleIniciarEdicao(tipo: string, modelo: ModeloPeticao | null) {
        setEditando(tipo)
        setTemplateText(modelo?.conteudo_template || "")
        setMensagemErro("")
        setMensagemSucesso("")
    }

    function handleCancelarEdicao() {
        setEditando(null)
        setTemplateText("")
    }

    function inserirVariavel(variavel: string) {
        const textarea = textareaRef.current
        if (!textarea) {
            setTemplateText((prev) => prev + `{{${variavel}}}`)
            return
        }

        const inicio = textarea.selectionStart
        const fim = textarea.selectionEnd
        const texto = templateText
        const novoTexto = texto.slice(0, inicio) + `{{${variavel}}}` + texto.slice(fim)

        setTemplateText(novoTexto)

        // Restaurar foco e posicionar cursor após a variável inserida
        requestAnimationFrame(() => {
            const pos = inicio + variavel.length + 2 // +2 pelos {{
            textarea.focus()
            textarea.setSelectionRange(pos, pos)
        })
    }

    async function handleSalvar(tipoBeneficio: string) {
        if (!templateText.trim()) {
            setMensagemErro("O template não pode estar vazio.")
            return
        }

        setSalvando(tipoBeneficio)
        setMensagemErro("")

        const { modelo, error } = await salvarModeloPeticao({
            tipoBeneficio,
            conteudo: templateText.trim(),
        })

        if (error) {
            setMensagemErro(`Erro ao salvar: ${error.message}`)
        } else {
            setMensagemSucesso(`Template salvo com sucesso.`)
            setEditando(null)
            setTemplateText("")
            await carregarModelos()
        }

        setSalvando(null)
    }

    async function handleDelete(id: string) {
        if (!confirm("Tem certeza que deseja excluir este template?")) return

        setDeletando(id)
        setMensagemErro("")

        const { error } = await deletarModeloPeticao(id)

        if (error) {
            setMensagemErro(`Erro ao excluir: ${error.message}`)
        } else {
            await carregarModelos()
        }

        setDeletando(null)
    }

    function copiarVariavel(variavel: string) {
        navigator.clipboard.writeText(`{{${variavel}}}`)
    }

    return (
        <DashboardLayout>
            <div className="flex flex-col gap-8 px-12 py-10 w-full max-w-6xl">
                {/* Header */}
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                    <div>
                        <h2 className="text-3xl font-black text-white tracking-tight">
                            Templates de Petições
                        </h2>
                        <p className="text-[#A3A3A3] mt-1">
                            Gerencie os modelos de petição para cada tipo de benefício.
                        </p>
                    </div>
                    <button
                        onClick={() => setMostrarDialogNovoTipo(true)}
                        className="flex items-center gap-2 px-4 py-2 rounded-lg bg-[#FACC15] hover:bg-[#EAB308] transition-colors text-black font-bold text-sm"
                    >
                        <span>+ Novo Tipo de Petição</span>
                    </button>
                </div>

                {/* Info Banner */}
                <div className="bg-[#FACC15]/5 border border-[#FACC15]/20 p-5 rounded-xl">
                    <div className="flex items-start gap-4">
                        <span className="material-symbols-outlined text-[#FACC15] text-2xl">
                            info
                        </span>
                        <div>
                            <p className="text-sm text-white font-bold mb-1">
                                Como funciona
                            </p>
                            <p className="text-xs text-[#A3A3A3] leading-relaxed">
                                Crie o texto do template usando variáveis como {"{{nome}}"}, {"{{cpf}}"}, {"{{der}}"}.
                                Na página do processo, o sistema substitui automaticamente essas variáveis
                                pelos dados reais extraídos dos documentos do cliente e gera o PDF da petição.
                            </p>
                        </div>
                    </div>
                </div>

                {/* Mensagens */}
                {mensagemErro && (
                    <div className="rounded-lg border border-red-500/20 bg-red-500/10 px-4 py-3 text-sm text-red-400">
                        {mensagemErro}
                    </div>
                )}
                {mensagemSucesso && (
                    <div className="rounded-lg border border-green-500/20 bg-green-500/10 px-4 py-3 text-sm text-green-400">
                        {mensagemSucesso}
                    </div>
                )}

                {/* Variáveis Disponíveis */}
                <div className="bg-[#171717] border border-[#333333] rounded-xl p-6">
                    <button
                        onClick={() => setShowVariaveis(!showVariaveis)}
                        className="flex items-center justify-between w-full"
                    >
                        <div className="flex items-center gap-3">
                            <div className="h-8 w-8 rounded-lg bg-[#FACC15]/10 flex items-center justify-center">
                                <Eye className="text-[#FACC15] h-4 w-4" />
                            </div>
                            <h3 className="text-xs font-black text-[#FACC15] uppercase tracking-[0.2em]">
                                Variáveis disponíveis no template
                            </h3>
                        </div>
                        {showVariaveis ? (
                            <ChevronUp className="h-4 w-4 text-[#A3A3A3]" />
                        ) : (
                            <ChevronDown className="h-4 w-4 text-[#A3A3A3]" />
                        )}
                    </button>

                    {showVariaveis && (
                        <div className="mt-4 grid gap-2 md:grid-cols-2">
                            {Object.entries(VARIAVEIS_DISPONIVEIS).map(
                                ([variavel, descricao]) => (
                                    <div
                                        key={variavel}
                                        className="flex items-center justify-between p-3 bg-[#0A0A0A] rounded-lg border border-[#333333] group"
                                    >
                                        <div className="flex items-center gap-3">
                                            <code className="text-sm text-[#FACC15] font-mono">
                                                {"{{" + variavel + "}}"}
                                            </code>
                                            <span className="text-xs text-[#A3A3A3]">
                                                {descricao}
                                            </span>
                                        </div>
                                        <button
                                            onClick={() => copiarVariavel(variavel)}
                                            className="opacity-0 group-hover:opacity-100 transition-opacity p-1 rounded hover:bg-[#333333]"
                                            title="Copiar"
                                        >
                                            <Copy className="h-3 w-3 text-[#A3A3A3]" />
                                        </button>
                                    </div>
                                )
                            )}
                        </div>
                    )}
                </div>

                {/* Lista de Templates por Benefício */}
                {carregando ? (
                    <div className="flex items-center justify-center py-10">
                        <Loader2 className="h-6 w-6 text-[#FACC15] animate-spin" />
                        <span className="ml-3 text-[#A3A3A3] text-sm">
                            Carregando...
                        </span>
                    </div>
                ) : (
                    <div className="space-y-4">
                        {modelosPorBeneficio.map(({ tipo, label, modeloAtivo, total }) => (
                            <div
                                key={tipo}
                                className="bg-[#171717] border border-[#333333] rounded-xl p-6"
                            >
                                {/* Header do benefício */}
                                <div className="flex items-center justify-between gap-4">
                                    <div className="flex items-center gap-3 min-w-0">
                                        <div className="h-10 w-10 rounded-lg bg-[#FACC15]/10 flex items-center justify-center shrink-0">
                                            <FileText className="text-[#FACC15] h-5 w-5" />
                                        </div>
                                        <div className="min-w-0">
                                            <p className="text-sm font-bold text-white truncate">
                                                {label}
                                            </p>
                                            <p className="text-xs text-[#A3A3A3]">
                                                {modeloAtivo
                                                    ? modeloAtivo.conteudo_template
                                                        ? "Template configurado"
                                                        : `Template ativo: ${modeloAtivo.nome_original}`
                                                    : "Nenhum template configurado"}
                                            </p>
                                        </div>
                                    </div>

                                    <div className="flex items-center gap-2 shrink-0">
                                        {tiposCustomizados[tipo] && (
                                            <button
                                                onClick={() => {
                                                    setTipoParaRemover(tipo)
                                                    setMostrarDialogRemoverTipo(true)
                                                }}
                                                className="p-2 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400 hover:bg-red-500/20 transition-colors"
                                                title="Remover tipo de petição"
                                            >
                                                <Trash2 className="h-4 w-4" />
                                            </button>
                                        )}
                                        {modeloAtivo && (
                                            <>
                                                <span className="flex items-center gap-1.5 px-2.5 py-1 rounded text-[10px] font-bold bg-green-500/10 text-green-400 border border-green-500/20">
                                                    <CheckCircle2 className="h-3 w-3" />
                                                    Configurado
                                                </span>
                                                <button
                                                    onClick={() => handleDelete(modeloAtivo.id)}
                                                    disabled={deletando === modeloAtivo.id}
                                                    className="p-2 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400 hover:bg-red-500/20 disabled:opacity-50 transition-colors"
                                                    title="Excluir template"
                                                >
                                                    {deletando === modeloAtivo.id ? (
                                                        <Loader2 className="h-4 w-4 animate-spin" />
                                                    ) : (
                                                        <Trash2 className="h-4 w-4" />
                                                    )}
                                                </button>
                                            </>
                                        )}

                                        {editando !== tipo ? (
                                            <button
                                                onClick={() => handleIniciarEdicao(tipo, modeloAtivo)}
                                                className="flex items-center gap-2 px-4 py-2 rounded-lg bg-[#FACC15] hover:bg-[#EAB308] transition-colors text-black font-bold text-sm"
                                            >
                                                {modeloAtivo ? "Editar" : "Criar"} Template
                                            </button>
                                        ) : null}
                                    </div>
                                </div>

                                {/* Editor de template */}
                                {editando === tipo && (
                                    <div className="mt-4 space-y-3">
                                        <div className="relative">
                                            <textarea
                                                ref={textareaRef}
                                                value={templateText}
                                                onChange={(e) => setTemplateText(e.target.value)}
                                                placeholder={`Digite o template da petição aqui...\n\nExemplo:\nAo INSS - Instituto Nacional do Seguro Social\n\nRef: Processo {{numero_processo}}\nBenefício: {{tipo_beneficio}}\n\n{{nome}}, portador do CPF {{cpf}}, nascido em {{data_nascimento}}...`}
                                                className="w-full h-64 bg-[#0A0A0A] border border-[#333333] rounded-lg p-4 text-sm text-white font-mono resize-y focus:outline-none focus:border-[#FACC15]/50 placeholder:text-[#525252]"
                                            />
                                        </div>

                                        {/* Inserir variáveis rápidas */}
                                        <div className="flex flex-wrap gap-2">
                                            <span className="text-xs text-[#A3A3A3] self-center mr-1">Inserir:</span>
                                            {Object.entries(VARIAVEIS_DISPONIVEIS).map(([variavel, descricao]) => (
                                                <button
                                                    key={variavel}
                                                    type="button"
                                                    onClick={() => inserirVariavel(variavel)}
                                                    className="px-2 py-1 text-[10px] font-mono bg-[#0A0A0A] border border-[#333333] rounded text-[#FACC15] hover:bg-[#FACC15]/10 hover:border-[#FACC15]/30 transition-colors"
                                                    title={descricao}
                                                >
                                                    {"{{" + variavel + "}}"}
                                                </button>
                                            ))}
                                        </div>

                                        {/* Botões de ação */}
                                        <div className="flex items-center gap-2 justify-end">
                                            <button
                                                onClick={handleCancelarEdicao}
                                                className="px-4 py-2 rounded-lg bg-[#1F1F1F] border border-[#333333] text-[#A3A3A3] hover:text-white text-sm transition-colors"
                                            >
                                                Cancelar
                                            </button>
                                            <button
                                                onClick={() => handleSalvar(tipo)}
                                                disabled={salvando === tipo || !templateText.trim()}
                                                className="flex items-center gap-2 px-4 py-2 rounded-lg bg-[#FACC15] hover:bg-[#EAB308] disabled:opacity-50 transition-colors text-black font-bold text-sm"
                                            >
                                                {salvando === tipo ? (
                                                    <Loader2 className="h-4 w-4 animate-spin" />
                                                ) : (
                                                    <Save className="h-4 w-4" />
                                                )}
                                                Salvar Template
                                            </button>
                                        </div>
                                    </div>
                                )}

                                {/* Preview do template existente */}
                                {modeloAtivo?.conteudo_template && editando !== tipo && (
                                    <div className="mt-4 p-4 bg-[#0A0A0A] rounded-lg border border-[#333333]">
                                        <p className="text-[10px] font-bold uppercase tracking-wider text-[#525252] mb-2">
                                            Preview do template
                                        </p>
                                        <pre className="text-xs text-[#A3A3A3] whitespace-pre-wrap font-mono max-h-32 overflow-y-auto">
                                            {modeloAtivo.conteudo_template.length > 500
                                                ? modeloAtivo.conteudo_template.slice(0, 500) + "..."
                                                : modeloAtivo.conteudo_template}
                                        </pre>
                                    </div>
                                )}
                            </div>
                        ))}
                    </div>
                )}
            </div>

            {/* Dialog para criar novo tipo */}
            {mostrarDialogNovoTipo && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
                    <div className="bg-[#171717] border border-[#333333] rounded-xl p-6 w-full max-w-md">
                        <h3 className="text-lg font-bold text-white mb-4">Novo Tipo de Petição</h3>
                        <input
                            type="text"
                            value={novoTipoNome}
                            onChange={(e) => setNovoTipoNome(e.target.value)}
                            placeholder="Ex: Auxílio Acidente"
                            className="w-full px-4 py-2 bg-[#0A0A0A] border border-[#333333] rounded-lg text-white focus:outline-none focus:border-[#FACC15]/50 mb-4"
                        />
                        <div className="flex gap-2 justify-end">
                            <button
                                onClick={() => {
                                    setMostrarDialogNovoTipo(false)
                                    setNovoTipoNome('')
                                }}
                                className="px-4 py-2 rounded-lg bg-[#1F1F1F] border border-[#333333] text-[#A3A3A3] hover:text-white text-sm"
                            >
                                Cancelar
                            </button>
                            <button
                                onClick={() => {
                                    if (!novoTipoNome.trim()) return
                                    const slug = gerarSlug(novoTipoNome)
                                    const novosTipos = { ...tiposCustomizados, [slug]: novoTipoNome.trim() }
                                    setTiposCustomizados(novosTipos)
                                    salvarTiposCustomizados(novosTipos)
                                    setMostrarDialogNovoTipo(false)
                                    setNovoTipoNome('')
                                }}
                                disabled={!novoTipoNome.trim()}
                                className="px-4 py-2 rounded-lg bg-[#FACC15] hover:bg-[#EAB308] disabled:opacity-50 text-black font-bold text-sm"
                            >
                                Criar
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* Dialog para confirmar remoção */}
            {mostrarDialogRemoverTipo && tipoParaRemover && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
                    <div className="bg-[#171717] border border-[#333333] rounded-xl p-6 w-full max-w-md">
                        <h3 className="text-lg font-bold text-white mb-4">Remover Tipo de Petição</h3>
                        <p className="text-[#A3A3A3] mb-4">
                            Tem certeza que deseja remover "{getLabelComCustom(tipoParaRemover)}"? Esta ação não pode ser desfeita.
                        </p>
                        <div className="flex gap-2 justify-end">
                            <button
                                onClick={() => {
                                    setMostrarDialogRemoverTipo(false)
                                    setTipoParaRemover(null)
                                }}
                                className="px-4 py-2 rounded-lg bg-[#1F1F1F] border border-[#333333] text-[#A3A3A3] hover:text-white text-sm"
                            >
                                Cancelar
                            </button>
                            <button
                                onClick={() => {
                                    const novosTipos = { ...tiposCustomizados }
                                    delete novosTipos[tipoParaRemover!]
                                    setTiposCustomizados(novosTipos)
                                    salvarTiposCustomizados(novosTipos)
                                    setMostrarDialogRemoverTipo(false)
                                    setTipoParaRemover(null)
                                }}
                                className="px-4 py-2 rounded-lg bg-red-500 hover:bg-red-600 text-white font-bold text-sm"
                            >
                                Remover
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </DashboardLayout>
    )
}
