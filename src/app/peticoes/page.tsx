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
    X,
    Variable,
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
import { getPalavrasGenero } from "@/lib/utils/adaptar-genero"

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

// Chaves para variaveis customizadas no localStorage
const VARIAVEIS_TEMPLATE_KEY = 'variaveis_custom_template'
const VARIAVEIS_GENERO_KEY = 'variaveis_custom_genero'

function carregarVariaveisCustom(): { template: string[], genero: string[] } {
    if (typeof window === 'undefined') return { template: [], genero: [] }
    try {
        return {
            template: JSON.parse(localStorage.getItem(VARIAVEIS_TEMPLATE_KEY) || '[]'),
            genero: JSON.parse(localStorage.getItem(VARIAVEIS_GENERO_KEY) || '[]'),
        }
    } catch { return { template: [], genero: [] } }
}

function salvarVariaveisCustom(template: string[], genero: string[]) {
    if (typeof window === 'undefined') return
    localStorage.setItem(VARIAVEIS_TEMPLATE_KEY, JSON.stringify(template))
    localStorage.setItem(VARIAVEIS_GENERO_KEY, JSON.stringify(genero))
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
    const [showGenero, setShowGenero] = useState(false)
    const [editando, setEditando] = useState<string | null>(null)
    const [templateText, setTemplateText] = useState("")
    const textareaRef = useRef<HTMLTextAreaElement>(null)
    const [tiposCustomizados, setTiposCustomizados] = useState<Record<string, string>>(() => carregarTiposCustomizados())
    const [variaveisCustomizadas, setVariaveisCustomizadas] = useState<string[]>(() => carregarVariaveisCustom().template)
    const [generoCustomizadas, setGeneroCustomizadas] = useState<string[]>(() => carregarVariaveisCustom().genero)
    const [mostrarDialogNovoTipo, setMostrarDialogNovoTipo] = useState(false)
    const [novoTipoNome, setNovoTipoNome] = useState('')
    const [mostrarDialogRemoverTipo, setMostrarDialogRemoverTipo] = useState(false)
    const [tipoParaRemover, setTipoParaRemover] = useState<string | null>(null)
    const [novaVariavel, setNovaVariavel] = useState('')
    const [showVariavelPicker, setShowVariavelPicker] = useState(false)
    const [variavelPickerFiltro, setVariavelPickerFiltro] = useState('')
    const [mostrarDialogNovaVariavel, setMostrarDialogNovaVariavel] = useState(false)
    const [novaVariavelNome, setNovaVariavelNome] = useState('')
    const [novaVariavelTipo, setNovaVariavelTipo] = useState<'template' | 'genero'>('template')

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
        setVariaveisCustomizadas((modelo?.variaveis_customizadas as string[]) || [])
        setMensagemErro("")
        setMensagemSucesso("")
    }

    function handleCancelarEdicao() {
        setEditando(null)
        setTemplateText("")
        setVariaveisCustomizadas([])
        setNovaVariavel("")
        setShowVariavelPicker(false)
        setVariavelPickerFiltro('')
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
            variaveisCustomizadas: variaveisCustomizadas,
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

    function handleCriarVariavel() {
        const nome = novaVariavelNome.trim()
        if (!nome) return

        if (novaVariavelTipo === 'genero') {
            setGeneroCustomizadas((prev) => [...prev, nome])
            salvarVariaveisCustom([...variaveisCustomizadas], [...generoCustomizadas, nome])
        } else {
            setVariaveisCustomizadas((prev) => [...prev, nome])
            salvarVariaveisCustom([...variaveisCustomizadas, nome], generoCustomizadas)
        }

        setNovaVariavelNome('')
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
                    <div className="flex gap-3">
                        <button
                            onClick={() => {
                                setNovaVariavelNome('')
                                setNovaVariavelTipo('template')
                                setMostrarDialogNovaVariavel(true)
                            }}
                            className="flex items-center gap-2 px-4 py-2 rounded-lg bg-[#171717] border border-[#333333] text-[#FACC15] hover:bg-[#FACC15]/5 hover:border-[#FACC15]/30 transition-colors font-bold text-sm"
                        >
                            <Variable className="h-4 w-4" />
                            <span>Nova Variavel</span>
                        </button>
                        <button
                            onClick={() => setMostrarDialogNovoTipo(true)}
                            className="flex items-center gap-2 px-4 py-2 rounded-lg bg-[#FACC15] hover:bg-[#EAB308] transition-colors text-black font-bold text-sm"
                        >
                            <span>+ Novo Tipo de Petição</span>
                        </button>
                    </div>
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

                {/* Adaptação de Gênero */}
                <div className="bg-[#171717] border border-[#333333] rounded-xl p-6">
                    <button
                        onClick={() => setShowGenero(!showGenero)}
                        className="flex items-center justify-between w-full"
                    >
                        <div className="flex items-center gap-3">
                            <div className="h-8 w-8 rounded-lg bg-[#FACC15]/10 flex items-center justify-center">
                                <span className="material-symbols-outlined text-[#FACC15] text-sm">wc</span>
                            </div>
                            <h3 className="text-xs font-black text-[#FACC15] uppercase tracking-[0.2em]">
                                Adaptação de Gênero
                            </h3>
                        </div>
                        {showGenero ? (
                            <ChevronUp className="h-4 w-4 text-[#A3A3A3]" />
                        ) : (
                            <ChevronDown className="h-4 w-4 text-[#A3A3A3]" />
                        )}
                    </button>

                    {showGenero && (
                        <div className="mt-4">
                            <p className="text-xs text-[#A3A3A3] mb-3">
                                Use {"{{palavra@}}"} para adaptar automaticamente conforme o sexo do cliente. Ex: {"{{solteiro@}}"} → "solteiro" ou "solteira".
                            </p>
                            <div className="grid gap-2 md:grid-cols-2">
                                {Object.entries(getPalavrasGenero()).map(([palavra, formas]) => (
                                    <div
                                        key={palavra}
                                        className="flex items-center justify-between p-2.5 bg-[#0A0A0A] rounded-lg border border-[#333333] group"
                                    >
                                        <div className="flex items-center gap-3">
                                            <code className="text-xs text-[#FACC15] font-mono">
                                                {"{{" + palavra + "@}}"}
                                            </code>
                                        </div>
                                        <div className="flex items-center gap-2">
                                            <span className="text-[10px] text-blue-400">{formas.masculino}</span>
                                            <span className="text-[10px] text-[#525252]">/</span>
                                            <span className="text-[10px] text-pink-400">{formas.feminino}</span>
                                        </div>
                                    </div>
                                ))}
                                {generoCustomizadas.map((palavra) => (
                                    <div
                                        key={palavra}
                                        className="flex items-center justify-between p-2.5 bg-pink-500/5 rounded-lg border border-pink-500/20 group"
                                    >
                                        <div className="flex items-center gap-3">
                                            <code className="text-xs text-pink-400 font-mono">
                                                {"{{" + palavra + "@}}"}
                                            </code>
                                            <span className="text-[10px] text-[#525252]">customizada</span>
                                        </div>
                                        <button
                                            onClick={() => {
                                                setGeneroCustomizadas((prev) => prev.filter((v) => v !== palavra))
                                                salvarVariaveisCustom(
                                                    variaveisCustomizadas,
                                                    generoCustomizadas.filter((v) => v !== palavra),
                                                )
                                            }}
                                            className="p-1 rounded hover:bg-red-500/10 text-red-400/70 hover:text-red-400 transition-colors"
                                            title="Remover"
                                        >
                                            <Trash2 className="h-3 w-3" />
                                        </button>
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}
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
                            {variaveisCustomizadas.map((variavel) => (
                                <div
                                    key={variavel}
                                    className="flex items-center justify-between p-3 bg-blue-500/5 rounded-lg border border-blue-500/20 group"
                                >
                                    <div className="flex items-center gap-3">
                                        <code className="text-sm text-blue-400 font-mono">
                                            {"{{" + variavel + "}}"}
                                        </code>
                                        <span className="text-xs text-[#525252]">customizada</span>
                                    </div>
                                    <button
                                        onClick={() => {
                                            setVariaveisCustomizadas((prev) => prev.filter((v) => v !== variavel))
                                            salvarVariaveisCustom(
                                                variaveisCustomizadas.filter((v) => v !== variavel),
                                                generoCustomizadas,
                                            )
                                        }}
                                        className="p-1 rounded hover:bg-red-500/10 text-red-400/70 hover:text-red-400 transition-colors"
                                        title="Remover"
                                    >
                                        <Trash2 className="h-3 w-3" />
                                    </button>
                                </div>
                            ))}
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

                                        {/* Botão Variável - abre o picker */}
                                        <div className="relative">
                                            <button
                                                type="button"
                                                onClick={() => setShowVariavelPicker(!showVariavelPicker)}
                                                className="flex items-center gap-2 px-4 py-2 bg-[#0A0A0A] border border-[#333333] rounded-lg text-xs font-bold text-[#A3A3A3] uppercase tracking-wider hover:border-[#FACC15]/30 hover:text-[#FACC15] transition-colors"
                                            >
                                                <Variable className="h-4 w-4" />
                                                Variavel
                                                <ChevronDown className={`h-3 w-3 transition-transform ${showVariavelPicker ? 'rotate-180' : ''}`} />
                                            </button>

                                            {showVariavelPicker && (
                                                <div className="absolute top-full left-0 mt-2 z-50 w-80 bg-[#171717] border border-[#333333] rounded-xl shadow-2xl overflow-hidden">
                                                    {/* Filtro */}
                                                    <div className="p-3 border-b border-[#333333]">
                                                        <input
                                                            type="text"
                                                            value={variavelPickerFiltro}
                                                            onChange={(e) => setVariavelPickerFiltro(e.target.value)}
                                                            placeholder="Buscar variavel..."
                                                            className="w-full px-3 py-2 bg-[#0A0A0A] border border-[#333333] rounded-lg text-xs text-white placeholder:text-[#525252] focus:outline-none focus:border-[#FACC15]/50"
                                                            autoFocus
                                                        />
                                                    </div>

                                                    {/* Seção: Variáveis de Template */}
                                                    <div className="border-b border-[#333333]">
                                                        <div className="px-3 py-2 bg-[#0A0A0A]">
                                                            <span className="text-[10px] font-black text-[#FACC15] uppercase tracking-widest">Variáveis de Template</span>
                                                        </div>
                                                        <div className="max-h-40 overflow-y-auto p-1">
                                                            {Object.entries(VARIAVEIS_DISPONIVEIS)
                                                                .filter(([v, d]) =>
                                                                    v.includes(variavelPickerFiltro.toLowerCase()) ||
                                                                    d.toLowerCase().includes(variavelPickerFiltro.toLowerCase())
                                                                )
                                                                .map(([variavel, descricao]) => (
                                                                    <button
                                                                        key={variavel}
                                                                        type="button"
                                                                        onClick={() => {
                                                                            inserirVariavel(variavel)
                                                                            setShowVariavelPicker(false)
                                                                            setVariavelPickerFiltro('')
                                                                        }}
                                                                        className="w-full flex items-center justify-between px-3 py-2 rounded-lg hover:bg-[#FACC15]/5 transition-colors group"
                                                                    >
                                                                        <div className="flex items-center gap-2">
                                                                            <code className="text-xs text-[#FACC15] font-mono">{"{{" + variavel + "}}"}</code>
                                                                            <span className="text-[10px] text-[#525252]">{descricao}</span>
                                                                        </div>
                                                                        <span className="text-[10px] text-[#333333] opacity-0 group-hover:opacity-100">inserir</span>
                                                                    </button>
                                                                ))
                                                            }
                                                            {variaveisCustomizadas
                                                                .filter((v) => v.includes(variavelPickerFiltro.toLowerCase()))
                                                                .map((variavel) => (
                                                                    <button
                                                                        key={variavel}
                                                                        type="button"
                                                                        onClick={() => {
                                                                            inserirVariavel(variavel)
                                                                            setShowVariavelPicker(false)
                                                                            setVariavelPickerFiltro('')
                                                                        }}
                                                                        className="w-full flex items-center justify-between px-3 py-2 rounded-lg hover:bg-blue-500/5 transition-colors group"
                                                                    >
                                                                        <div className="flex items-center gap-2">
                                                                            <code className="text-xs text-blue-400 font-mono">{"{{" + variavel + "}}"}</code>
                                                                            <span className="text-[10px] text-[#525252]">customizada</span>
                                                                        </div>
                                                                        <div className="flex items-center gap-1">
                                                                            <button
                                                                                type="button"
                                                                                onClick={(e) => {
                                                                                    e.stopPropagation()
                                                                                    setVariaveisCustomizadas((prev) => prev.filter((v) => v !== variavel))
                                                                                }}
                                                                                className="p-1 rounded hover:bg-red-500/10 text-[#525252] hover:text-red-400 transition-colors"
                                                                                title="Remover variavel"
                                                                            >
                                                                                <X className="h-3 w-3" />
                                                                            </button>
                                                                        </div>
                                                                    </button>
                                                                ))
                                                            }
                                                        </div>
                                                    </div>

                                                    {/* Seção: Variáveis de Gênero */}
                                                    <div>
                                                        <div className="px-3 py-2 bg-[#0A0A0A]">
                                                            <span className="text-[10px] font-black text-pink-400 uppercase tracking-widest">Variáveis de Gênero</span>
                                                        </div>
                                                        <div className="max-h-40 overflow-y-auto p-1">
                                                            {Object.entries(getPalavrasGenero())
                                                                .filter(([p]) => p.includes(variavelPickerFiltro.toLowerCase()))
                                                                .map(([palavra, formas]) => (
                                                                    <button
                                                                        key={palavra}
                                                                        type="button"
                                                                        onClick={() => {
                                                                            inserirVariavel(palavra + '@')
                                                                            setShowVariavelPicker(false)
                                                                            setVariavelPickerFiltro('')
                                                                        }}
                                                                        className="w-full flex items-center justify-between px-3 py-2 rounded-lg hover:bg-pink-500/5 transition-colors group"
                                                                    >
                                                                        <div className="flex items-center gap-2">
                                                                            <code className="text-xs text-pink-400 font-mono">{"{{" + palavra + "@}}"}</code>
                                                                        </div>
                                                                        <div className="flex items-center gap-1">
                                                                            <span className="text-[9px] text-blue-400">{formas.masculino}</span>
                                                                            <span className="text-[9px] text-[#333333]">/</span>
                                                                            <span className="text-[9px] text-pink-400">{formas.feminino}</span>
                                                                        </div>
                                                                    </button>
                                                                ))
                                                            }
                                                            {generoCustomizadas
                                                                .filter((p) => p.includes(variavelPickerFiltro.toLowerCase()))
                                                                .map((palavra) => (
                                                                    <button
                                                                        key={palavra}
                                                                        type="button"
                                                                        onClick={() => {
                                                                            inserirVariavel(palavra + '@')
                                                                            setShowVariavelPicker(false)
                                                                            setVariavelPickerFiltro('')
                                                                        }}
                                                                        className="w-full flex items-center justify-between px-3 py-2 rounded-lg hover:bg-pink-500/5 transition-colors group"
                                                                    >
                                                                        <code className="text-xs text-pink-400 font-mono">{"{{" + palavra + "@}}"}</code>
                                                                        <span className="text-[9px] text-[#525252]">customizada</span>
                                                                    </button>
                                                                ))
                                                            }
                                                        </div>
                                                    </div>

                                                    {/* Criar variável customizada */}
                                                    <div className="p-3 border-t border-[#333333]">
                                                        <div className="flex gap-2">
                                                            <input
                                                                type="text"
                                                                value={novaVariavel}
                                                                onChange={(e) => setNovaVariavel(e.target.value.replace(/[^a-zA-Z0-9_]/g, '').toLowerCase())}
                                                                onKeyDown={(e) => {
                                                                    if (e.key === "Enter" && novaVariavel.trim()) {
                                                                        e.preventDefault()
                                                                        if (!variaveisCustomizadas.includes(novaVariavel.trim())) {
                                                                            setVariaveisCustomizadas((prev) => [...prev, novaVariavel.trim()])
                                                                        }
                                                                        setNovaVariavel("")
                                                                    }
                                                                }}
                                                                placeholder="Nova variavel (ex: escola)"
                                                                className="flex-1 px-3 py-1.5 bg-[#0A0A0A] border border-[#333333] rounded-lg text-xs text-white font-mono focus:outline-none focus:border-blue-500/50 placeholder:text-[#525252]"
                                                            />
                                                            <button
                                                                type="button"
                                                                onClick={() => {
                                                                    if (novaVariavel.trim() && !variaveisCustomizadas.includes(novaVariavel.trim())) {
                                                                        setVariaveisCustomizadas((prev) => [...prev, novaVariavel.trim()])
                                                                    }
                                                                    setNovaVariavel("")
                                                                }}
                                                                disabled={!novaVariavel.trim()}
                                                                className="px-3 py-1.5 bg-blue-500/10 border border-blue-500/30 rounded-lg text-xs text-blue-400 hover:bg-blue-500/20 disabled:opacity-30 transition-colors"
                                                            >
                                                                +
                                                            </button>
                                                        </div>
                                                    </div>
                                                </div>
                                            )}
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

            {/* Dialog para criar nova variável */}
            {mostrarDialogNovaVariavel && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
                    <div className="bg-[#171717] border border-[#333333] rounded-xl p-6 w-full max-w-md">
                        <h3 className="text-lg font-bold text-white mb-1">Nova Variável</h3>
                        <p className="text-xs text-[#A3A3A3] mb-4">
                            Crie uma variavel para usar nos templates. Ela aparecera no dropdown correspondente.
                        </p>

                        <div className="space-y-4">
                            {/* Nome */}
                            <div>
                                <label className="text-xs text-[#A3A3A3] font-bold uppercase tracking-wider mb-2">Nome da Variavel</label>
                                <input
                                    type="text"
                                    value={novaVariavelNome}
                                    onChange={(e) => setNovaVariavelNome(e.target.value.replace(/[^a-zA-Z0-9_]/g, '').toLowerCase())}
                                    onKeyDown={(e) => {
                                        if (e.key === 'Enter') {
                                            e.preventDefault()
                                            handleCriarVariavel()
                                        }
                                    }}
                                    placeholder="ex: escola, profissao, cidade..."
                                    className="w-full px-4 py-2.5 bg-[#0A0A0A] border border-[#333333] rounded-lg text-white text-sm font-mono focus:outline-none focus:border-[#FACC15]/50"
                                    autoFocus
                                />
                                {novaVariavelNome && (
                                    <p className="mt-2 text-xs text-[#525252]">
                                        Resultado: <code className="text-[#FACC15]">
                                            {novaVariavelTipo === 'genero'
                                                ? `{{${novaVariavelNome}@}}`
                                                : `{{${novaVariavelNome}}`}
                                            </code>
                                    </p>
                                )}
                            </div>

                            {/* Tipo */}
                            <div>
                                <label className="text-xs text-[#A3A3A3] font-bold uppercase tracking-wider mb-2">Tipo</label>
                                <div className="flex gap-2">
                                    <button
                                        type="button"
                                        onClick={() => setNovaVariavelTipo('template')}
                                        className={`flex-1 p-3 rounded-lg border text-sm font-medium transition-colors ${
                                            novaVariavelTipo === 'template'
                                                ? 'bg-[#FACC15]/10 border-[#FACC15]/30 text-[#FACC15]'
                                                : 'bg-[#0A0A0A] border-[#333333] text-[#A3A3A3] hover:border-[#FACC15]/20'
                                        }`}
                                    >
                                        <code className="text-xs font-mono">{"{{nome}}"}</code>
                                        <p className="text-[10px] mt-0.5">Variavel de Template</p>
                                    </button>
                                    <button
                                        type="button"
                                        onClick={() => setNovaVariavelTipo('genero')}
                                        className={`flex-1 p-3 rounded-lg border text-sm font-medium transition-colors ${
                                            novaVariavelTipo === 'genero'
                                                ? 'bg-pink-500/10 border-pink-500/30 text-pink-400'
                                                : 'bg-[#0A0A0A] border-[#333333] text-[#A3A3A3] hover:border-pink-500/20'
                                        }`}
                                    >
                                        <code className="text-xs font-mono">{"{{solteiro@}}"}</code>
                                        <p className="text-[10px] mt-0.5">Variavel de Genero</p>
                                    </button>
                                </div>
                            </div>
                        </div>

                        <div className="flex gap-2 justify-end mt-6">
                            <button
                                onClick={() => setMostrarDialogNovaVariavel(false)}
                                className="px-4 py-2 rounded-lg bg-[#1F1F1F] border border-[#333333] text-[#A3A3A3] hover:text-white text-sm"
                            >
                                Cancelar
                            </button>
                            <button
                                onClick={() => {
                                    handleCriarVariavel()
                                    setMostrarDialogNovaVariavel(false)
                                }}
                                disabled={!novaVariavelNome.trim()}
                                className="px-4 py-2 rounded-lg bg-[#FACC15] hover:bg-[#EAB308] disabled:opacity-50 text-black font-bold text-sm"
                            >
                                Criar Variavel
                            </button>
                        </div>
                    </div>
                </div>
            )}

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
