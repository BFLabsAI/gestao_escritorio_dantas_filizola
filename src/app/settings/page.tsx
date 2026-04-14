"use client"

import { useEffect, useMemo, useState } from "react"
import DashboardLayout from "@/components/layout/dashboard-layout"
import { Plus, Trash2, Save, FileText, ClipboardList, Loader2 } from "lucide-react"
import { supabase } from "@/lib/supabase/client"
import {
    TIPO_BENEFICIO_LABELS,
    TIPO_DOCUMENTO_LABELS,
    getTipoBeneficioLabel,
    getTipoDocumentoLabel,
} from "@/lib/types/database"
import type { ExigenciaDoc } from "@/lib/types/database"

function normalizarChave(valor: string) {
    return valor
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, "")
        .replace(/[^a-zA-Z0-9]+/g, "_")
        .replace(/^_+|_+$/g, "")
        .replace(/_+/g, "_")
        .toUpperCase()
}

export default function SettingsPage() {
    const [exigencias, setExigencias] = useState<ExigenciaDoc[]>([])
    const [carregando, setCarregando] = useState(true)
    const [salvando, setSalvando] = useState(false)
    const [isSaved, setIsSaved] = useState(false)
    const [documentoSelecionado, setDocumentoSelecionado] = useState("")
    const [novoDocumento, setNovoDocumento] = useState("")
    const [beneficiosSelecionados, setBeneficiosSelecionados] = useState<string[]>([])
    const [novoBeneficio, setNovoBeneficio] = useState("")
    const [descricao, setDescricao] = useState("")
    const [mensagemErro, setMensagemErro] = useState("")

    const carregarExigencias = async () => {
        setCarregando(true)
        setMensagemErro("")

        const { data, error } = await supabase
            .from("exigencias_doc_gestao_escritorio_filizola")
            .select("*")
            .eq("ativo", true)
            .order("tipo_beneficio")
            .order("ordem_exibicao")

        if (error) {
            setMensagemErro(error.message)
        } else {
            setExigencias((data as ExigenciaDoc[]) ?? [])
        }

        setCarregando(false)
    }

    useEffect(() => {
        carregarExigencias()
    }, [])

    const beneficiosDisponiveis = useMemo(() => {
        const values = new Set<string>([
            ...Object.keys(TIPO_BENEFICIO_LABELS),
            ...exigencias.map((item) => item.tipo_beneficio),
        ])

        return Array.from(values).sort((a, b) => getTipoBeneficioLabel(a).localeCompare(getTipoBeneficioLabel(b)))
    }, [exigencias])

    const documentosDisponiveis = useMemo(() => {
        const values = new Set<string>([
            ...Object.keys(TIPO_DOCUMENTO_LABELS),
            ...exigencias.map((item) => item.tipo_documento),
        ])

        return Array.from(values).sort((a, b) => getTipoDocumentoLabel(a).localeCompare(getTipoDocumentoLabel(b)))
    }, [exigencias])

    const exigenciasPorBeneficio = beneficiosDisponiveis.map((tipo) => ({
        tipo,
        label: getTipoBeneficioLabel(tipo),
        docs: exigencias.filter((item) => item.tipo_beneficio === tipo),
    }))

    const toggleBeneficio = (tipo: string) => {
        setBeneficiosSelecionados((prev) =>
            prev.includes(tipo) ? prev.filter((item) => item !== tipo) : [...prev, tipo]
        )
    }

    async function adicionarExigencia() {
        const tipoDocumentoFinal = documentoSelecionado || normalizarChave(novoDocumento)
        const novoBeneficioNormalizado = normalizarChave(novoBeneficio)
        const beneficiosFinais = Array.from(
            new Set([
                ...beneficiosSelecionados,
                ...(novoBeneficioNormalizado ? [novoBeneficioNormalizado] : []),
            ])
        )

        if (!tipoDocumentoFinal || beneficiosFinais.length === 0) {
            setMensagemErro("Informe um documento e pelo menos um benefício.")
            return
        }

        setSalvando(true)
        setMensagemErro("")

        for (const tipoBeneficio of beneficiosFinais) {
            const ordem = exigencias.filter((item) => item.tipo_beneficio === tipoBeneficio).length + 1

            const { error } = await supabase
                .from("exigencias_doc_gestao_escritorio_filizola")
                .upsert({
                    tipo_beneficio: tipoBeneficio,
                    tipo_documento: tipoDocumentoFinal,
                    obrigatorio: true,
                    descricao: descricao || null,
                    ordem_exibicao: ordem,
                    ativo: true,
                }, { onConflict: "tipo_beneficio,tipo_documento" })

            if (error) {
                setMensagemErro(error.message)
                setSalvando(false)
                return
            }
        }

        setDocumentoSelecionado("")
        setNovoDocumento("")
        setBeneficiosSelecionados([])
        setNovoBeneficio("")
        setDescricao("")
        setIsSaved(true)
        setTimeout(() => setIsSaved(false), 3000)

        await carregarExigencias()
        setSalvando(false)
    }

    async function removerExigencia(id: string) {
        const { error } = await supabase
            .from("exigencias_doc_gestao_escritorio_filizola")
            .delete()
            .eq("id", id)

        if (error) {
            setMensagemErro(error.message)
            return
        }

        await carregarExigencias()
    }

    return (
        <DashboardLayout>
            <div className="flex flex-col gap-8 px-12 py-10 w-full max-w-6xl">
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                    <div>
                        <h2 className="text-3xl font-black text-white tracking-tight">Configurações</h2>
                        <p className="text-[#A3A3A3] mt-1">Cadastre documentos e benefícios novos direto no sistema.</p>
                    </div>
                    <button
                        onClick={adicionarExigencia}
                        disabled={salvando}
                        className="flex items-center gap-2 rounded-lg bg-[#FACC15] hover:bg-[#EAB308] disabled:opacity-50 transition-colors px-6 py-2.5 text-black font-bold text-sm shadow-[0_0_15px_rgba(250,204,21,0.15)]"
                    >
                        {salvando ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                        {isSaved ? "Salvo!" : "Salvar Configuração"}
                    </button>
                </div>

                <div className="bg-[#FACC15]/5 border border-[#FACC15]/20 p-5 rounded-xl">
                    <div className="flex items-start gap-4">
                        <span className="material-symbols-outlined text-[#FACC15] text-2xl">info</span>
                        <div>
                            <p className="text-sm text-white font-bold mb-1">Catálogo dinâmico</p>
                            <p className="text-xs text-[#A3A3A3] leading-relaxed">
                                Você pode reutilizar um documento já existente ou digitar um novo. O mesmo vale para benefícios: selecione os já cadastrados ou crie um novo na hora.
                            </p>
                        </div>
                    </div>
                </div>

                <div className="bg-[#171717] border border-[#333333] rounded-xl p-6 space-y-5">
                    <div className="flex items-center gap-3">
                        <div className="h-8 w-8 rounded-lg bg-[#FACC15]/10 flex items-center justify-center">
                            <FileText className="text-[#FACC15] h-4 w-4" />
                        </div>
                        <h3 className="text-xs font-black text-[#FACC15] uppercase tracking-[0.2em]">Nova Exigência</h3>
                    </div>

                    {mensagemErro && (
                        <div className="rounded-lg border border-red-500/20 bg-red-500/10 px-4 py-3 text-sm text-red-400">
                            {mensagemErro}
                        </div>
                    )}

                    <div className="grid gap-4 md:grid-cols-2">
                        <div className="space-y-2">
                            <label className="text-[10px] font-bold text-[#A3A3A3] uppercase tracking-widest">Documento existente</label>
                            <select
                                value={documentoSelecionado}
                                onChange={(e) => setDocumentoSelecionado(e.target.value)}
                                className="w-full h-10 rounded-lg border border-[#333333] bg-[#1F1F1F] px-4 text-sm outline-none focus:border-[#FACC15] text-white"
                            >
                                <option value="">Selecione um documento</option>
                                {documentosDisponiveis.map((tipo) => (
                                    <option key={tipo} value={tipo}>
                                        {getTipoDocumentoLabel(tipo)}
                                    </option>
                                ))}
                            </select>
                        </div>

                        <div className="space-y-2">
                            <label className="text-[10px] font-bold text-[#A3A3A3] uppercase tracking-widest">Novo documento</label>
                            <input
                                value={novoDocumento}
                                onChange={(e) => setNovoDocumento(e.target.value)}
                                placeholder="Ex.: HOLERITE ou PPP"
                                className="w-full h-10 rounded-lg border border-[#333333] bg-[#1F1F1F] px-4 text-sm outline-none focus:border-[#FACC15] text-white"
                            />
                        </div>
                    </div>

                    <div className="space-y-2">
                        <label className="text-[10px] font-bold text-[#A3A3A3] uppercase tracking-widest">Aplicar aos benefícios existentes</label>
                        <div className="flex flex-wrap gap-2">
                            {beneficiosDisponiveis.map((tipo) => (
                                <button
                                    key={tipo}
                                    onClick={() => toggleBeneficio(tipo)}
                                    className={`px-3 py-1.5 rounded text-[10px] font-bold border transition-all ${
                                        beneficiosSelecionados.includes(tipo)
                                            ? "bg-[#FACC15]/10 text-[#FACC15] border-[#FACC15]/30"
                                            : "bg-[#1F1F1F] text-[#A3A3A3] border-[#333333] hover:border-[#FACC15]/20"
                                    }`}
                                >
                                    {getTipoBeneficioLabel(tipo)}
                                </button>
                            ))}
                        </div>
                    </div>

                    <div className="grid gap-4 md:grid-cols-2">
                        <div className="space-y-2">
                            <label className="text-[10px] font-bold text-[#A3A3A3] uppercase tracking-widest">Novo benefício</label>
                            <input
                                value={novoBeneficio}
                                onChange={(e) => setNovoBeneficio(e.target.value)}
                                placeholder="Ex.: AUXILIO_ACIDENTE"
                                className="w-full h-10 rounded-lg border border-[#333333] bg-[#1F1F1F] px-4 text-sm outline-none focus:border-[#FACC15] text-white"
                            />
                        </div>

                        <div className="space-y-2">
                            <label className="text-[10px] font-bold text-[#A3A3A3] uppercase tracking-widest">Descrição opcional</label>
                            <input
                                value={descricao}
                                onChange={(e) => setDescricao(e.target.value)}
                                placeholder="Detalhe adicional do documento"
                                className="w-full h-10 rounded-lg border border-[#333333] bg-[#1F1F1F] px-4 text-sm outline-none focus:border-[#FACC15] text-white"
                            />
                        </div>
                    </div>

                    <button
                        onClick={adicionarExigencia}
                        disabled={salvando}
                        className="inline-flex items-center gap-2 px-4 py-2 bg-[#FACC15] hover:bg-[#EAB308] disabled:opacity-50 transition-colors text-black font-bold text-sm rounded-lg"
                    >
                        {salvando ? <Loader2 className="h-4 w-4 animate-spin" /> : <Plus className="h-4 w-4" />}
                        Adicionar Exigência
                    </button>
                </div>

                {carregando ? (
                    <div className="flex items-center justify-center py-10">
                        <Loader2 className="h-6 w-6 text-[#FACC15] animate-spin" />
                        <span className="ml-3 text-[#A3A3A3] text-sm">Carregando...</span>
                    </div>
                ) : (
                    <div className="space-y-6">
                        {exigenciasPorBeneficio.map(({ tipo, label, docs }) => (
                            <div key={tipo} className="bg-[#171717] border border-[#333333] rounded-xl p-6">
                                <div className="flex items-center gap-3 mb-4">
                                    <div className="h-8 w-8 rounded-lg bg-[#FACC15]/10 flex items-center justify-center">
                                        <ClipboardList className="text-[#FACC15] h-4 w-4" />
                                    </div>
                                    <h3 className="text-xs font-black text-[#FACC15] uppercase tracking-[0.2em]">
                                        {label} ({docs.length} documentos)
                                    </h3>
                                </div>

                                <div className="space-y-2">
                                    {docs.map((doc) => (
                                        <div
                                            key={doc.id}
                                            className="flex items-center justify-between p-3 bg-[#0A0A0A] rounded-lg border border-[#333333] group hover:border-[#FACC15]/20 transition-all"
                                        >
                                            <div className="flex items-center gap-3">
                                                <span className={`h-2 w-2 rounded-full ${doc.obrigatorio ? "bg-green-500" : "bg-yellow-500"}`} />
                                                <span className="text-sm text-white">{getTipoDocumentoLabel(doc.tipo_documento)}</span>
                                                {doc.descricao && <span className="text-[10px] text-[#A3A3A3]">- {doc.descricao}</span>}
                                            </div>
                                            <button
                                                onClick={() => removerExigencia(doc.id)}
                                                className="p-1.5 rounded bg-transparent hover:bg-red-500/10 text-[#A3A3A3] hover:text-red-400 transition-all"
                                            >
                                                <Trash2 className="h-4 w-4" />
                                            </button>
                                        </div>
                                    ))}

                                    {docs.length === 0 && (
                                        <p className="text-xs text-[#525252] py-2">Nenhuma exigência configurada para este benefício.</p>
                                    )}
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>
        </DashboardLayout>
    )
}
