"use client"

import { useState, useEffect } from "react"
import DashboardLayout from "@/components/layout/dashboard-layout"
import { TrendingUp, Clock, AlertTriangle, FileCheck2, Filter, Download, X, Search, Loader2 } from "lucide-react"
import { buscarProcessos } from "@/lib/services/processos"
import type { Processo, FaseKanban } from "@/lib/types/database"
import { TIPO_BENEFICIO_LABELS, FASE_KANBAN_LABELS, FASE_KANBAN_COLORS, getTipoBeneficioLabel } from "@/lib/types/database"

const FASES_CRITICAS: FaseKanban[] = ["DOC_PENDENTE", "APROVACAO_GESTOR", "PENDENCIA"]

function getUrgenciaLevel(faseKanban: FaseKanban): "critical" | "high" | "medium" {
    if (faseKanban === "DOC_PENDENTE" || faseKanban === "PENDENCIA") return "critical"
    if (faseKanban === "APROVACAO_GESTOR") return "high"
    return "medium"
}

const URGENCIA_OPCOES = [
    { value: "critical", label: "Crítico", color: "bg-red-500" },
    { value: "high", label: "Alto", color: "bg-orange-500" },
    { value: "medium", label: "Médio", color: "bg-yellow-500" },
]

const BENEFICIO_OPCOES = Object.values(TIPO_BENEFICIO_LABELS)

const urgencyColors: Record<string, string> = {
    critical: "bg-red-500/10 text-red-400 border-red-500/20",
    high: "bg-orange-500/10 text-orange-400 border-orange-500/20",
    medium: "bg-yellow-500/10 text-yellow-400 border-yellow-500/20",
}

const urgencyLabels: Record<string, string> = {
    critical: "Crítico",
    high: "Alto",
    medium: "Médio",
}

export default function DashboardPage() {
    const [carregando, setCarregando] = useState(true)
    const [processos, setProcessos] = useState<Processo[]>([])
    const [showFiltros, setShowFiltros] = useState(false)
    const [busca, setBusca] = useState("")
    const [urgenciaAtiva, setUrgenciaAtiva] = useState<string[]>([])
    const [beneficioAtivo, setBeneficioAtivo] = useState<string[]>([])
    const [filtroTipo, setFiltroTipo] = useState<"urgencia" | "beneficio">("urgencia")

    useEffect(() => {
        async function carregar() {
            setCarregando(true)
            const { processos: data } = await buscarProcessos()
            setProcessos(data || [])
            setCarregando(false)
        }
        carregar()
    }, [])

    const today = new Date().toISOString().split("T")[0]

    const processosProtocoladosHoje = processos.filter(
        (p) => p.data_protocolo && p.data_protocolo.startsWith(today)
    )

    const processosPreProtocolo = processos.filter(
        (p) => p.fase_kanban === "PRONTO_PROTOCOLO" || p.fase_kanban === "PETICIONADO"
    )

    const tempoMedioProtocolo =
        processosPreProtocolo.length > 0
            ? (
                  processosPreProtocolo.reduce((acc, p) => acc + (p.dias_na_fase || 0), 0) /
                  processosPreProtocolo.length
              ).toFixed(1)
            : "0.0"

    const prazosVencendo = processos.filter((p) => p.urgencia === true)

    const indicators = [
        { title: "Processos Protocolados Hoje", value: String(processosProtocoladosHoje.length), icon: FileCheck2, color: "text-[#FACC15]" },
        { title: "Tempo Médio até Protocolo", value: `${tempoMedioProtocolo} dias`, icon: Clock, color: "text-[#FACC15]" },
        { title: "Prazos Vencendo D-0", value: String(prazosVencendo.length), icon: AlertTriangle, color: "text-[#EF4444]" },
    ]

    const exigenciasData = processos.filter(
        (p) => FASES_CRITICAS.includes(p.fase_kanban) && p.urgencia === true
    )

    const exigenciasFormatadas = exigenciasData.map((p) => ({
        id: p.id,
        client: p.cliente?.nome_completo ?? "N/A",
        cpf: p.cliente?.cpf ?? "",
        process: p.numero_processo ?? "N/A",
        benefit: getTipoBeneficioLabel(p.tipo_beneficio),
        fase_kanban: p.fase_kanban,
        urgency: getUrgenciaLevel(p.fase_kanban),
    }))

    const toggleUrgencia = (u: string) => {
        setUrgenciaAtiva((prev) => prev.includes(u) ? prev.filter((x) => x !== u) : [...prev, u])
    }

    const toggleBeneficio = (b: string) => {
        setBeneficioAtivo((prev) => prev.includes(b) ? prev.filter((x) => x !== b) : [...prev, b])
    }

    const limparTudo = () => {
        setUrgenciaAtiva([])
        setBeneficioAtivo([])
        setBusca("")
    }

    const temFiltros = urgenciaAtiva.length > 0 || beneficioAtivo.length > 0 || busca !== ""

    const exigenciasFiltradas = exigenciasFormatadas.filter((item) => {
        const matchBusca =
            busca === "" ||
            item.client.toLowerCase().includes(busca.toLowerCase()) ||
            item.cpf.includes(busca) ||
            item.process.includes(busca) ||
            item.benefit.toLowerCase().includes(busca.toLowerCase())
        const matchUrgencia = urgenciaAtiva.length === 0 || urgenciaAtiva.includes(item.urgency)
        const matchBeneficio = beneficioAtivo.length === 0 || beneficioAtivo.includes(item.benefit)
        return matchBusca && matchUrgencia && matchBeneficio
    })

    return (
        <DashboardLayout>
            <div className="flex flex-col gap-8 px-12 py-10 w-full max-w-full">
                {/* Header Section */}
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                    <div>
                        <h2 className="text-3xl font-black text-white tracking-tight">Visão Geral</h2>
                        <p className="text-[#A3A3A3] mt-1">Acompanhe os principais indicadores do escritório hoje.</p>
                    </div>
                    <div className="flex gap-2">
                        <div className="relative flex items-center">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-[#A3A3A3] pointer-events-none" />
                            <input
                                type="search"
                                placeholder="Buscar exigência..."
                                value={busca}
                                onChange={(e) => setBusca(e.target.value)}
                                className="h-10 w-56 rounded-lg border border-[#333333] bg-[#1F1F1F] pl-10 pr-4 text-sm outline-none focus:border-[#FACC15] focus:ring-1 focus:ring-[#FACC15] transition-all text-white placeholder:text-[#A3A3A3]"
                            />
                        </div>
                        <div className="relative">
                            <button
                                onClick={() => setShowFiltros(!showFiltros)}
                                className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                                    temFiltros
                                        ? "bg-[#FACC15]/10 border border-[#FACC15]/30 text-[#FACC15]"
                                        : "bg-[#1F1F1F] border border-[#333333] text-[#A3A3A3] hover:text-white hover:border-[#FACC15]/50"
                                }`}
                            >
                                <Filter className="h-4 w-4" />
                                Filtros
                                {temFiltros && (
                                    <span className="ml-1 h-5 w-5 rounded-full bg-[#FACC15] text-black text-[10px] font-bold flex items-center justify-center">
                                        {urgenciaAtiva.length + beneficioAtivo.length}
                                    </span>
                                )}
                            </button>

                            {showFiltros && (
                                <div className="absolute right-0 top-full mt-2 z-50 bg-[#171717] border border-[#333333] rounded-xl p-4 shadow-2xl w-80">
                                    <div className="flex items-center justify-between mb-3">
                                        <span className="text-xs font-bold text-white uppercase tracking-widest">Filtrar Exigências</span>
                                        {temFiltros && (
                                            <button onClick={limparTudo} className="text-[10px] text-red-400 hover:text-red-300 font-bold uppercase">
                                                Limpar tudo
                                            </button>
                                        )}
                                    </div>

                                    {/* Tabs de filtro */}
                                    <div className="flex gap-1 mb-3 bg-[#0A0A0A] rounded-lg p-1">
                                        <button
                                            onClick={() => setFiltroTipo("urgencia")}
                                            className={`flex-1 px-3 py-1.5 rounded text-[10px] font-bold uppercase transition-all ${
                                                filtroTipo === "urgencia"
                                                    ? "bg-[#FACC15] text-black"
                                                    : "text-[#A3A3A3] hover:text-white"
                                            }`}
                                        >
                                            Urgência
                                        </button>
                                        <button
                                            onClick={() => setFiltroTipo("beneficio")}
                                            className={`flex-1 px-3 py-1.5 rounded text-[10px] font-bold uppercase transition-all ${
                                                filtroTipo === "beneficio"
                                                    ? "bg-[#FACC15] text-black"
                                                    : "text-[#A3A3A3] hover:text-white"
                                            }`}
                                        >
                                            Benefício
                                        </button>
                                    </div>

                                    {filtroTipo === "urgencia" ? (
                                        <div className="flex flex-col gap-1.5">
                                            {URGENCIA_OPCOES.map((opcao) => (
                                                <button
                                                    key={opcao.value}
                                                    onClick={() => toggleUrgencia(opcao.value)}
                                                    className={`flex items-center gap-3 px-3 py-2 rounded-lg text-left text-xs font-medium transition-all ${
                                                        urgenciaAtiva.includes(opcao.value)
                                                            ? "bg-[#FACC15]/10 text-[#FACC15] border border-[#FACC15]/20"
                                                            : "text-[#A3A3A3] hover:bg-[#1F1F1F] hover:text-white"
                                                    }`}
                                                >
                                                    <span className={`h-2 w-2 rounded-full ${opcao.color} ${urgenciaAtiva.includes(opcao.value) ? "opacity-100" : "opacity-40"}`} />
                                                    {opcao.label}
                                                </button>
                                            ))}
                                        </div>
                                    ) : (
                                        <div className="flex flex-col gap-1.5 max-h-48 overflow-y-auto">
                                            {BENEFICIO_OPCOES.map((opcao) => (
                                                <button
                                                    key={opcao}
                                                    onClick={() => toggleBeneficio(opcao)}
                                                    className={`flex items-center gap-3 px-3 py-2 rounded-lg text-left text-xs font-medium transition-all ${
                                                        beneficioAtivo.includes(opcao)
                                                            ? "bg-[#FACC15]/10 text-[#FACC15] border border-[#FACC15]/20"
                                                            : "text-[#A3A3A3] hover:bg-[#1F1F1F] hover:text-white"
                                                    }`}
                                                >
                                                    <span className={`h-2 w-2 rounded-full border ${beneficioAtivo.includes(opcao) ? "bg-[#FACC15] border-[#FACC15]" : "border-[#525252]"}`} />
                                                    {opcao}
                                                </button>
                                            ))}
                                        </div>
                                    )}
                                </div>
                            )}
                        </div>
                        <button className="flex items-center gap-2 px-4 py-2 bg-[#1F1F1F] border border-[#333333] rounded-lg text-sm font-medium text-[#A3A3A3] hover:text-white hover:border-[#FACC15]/50 transition-colors">
                            <Download className="h-4 w-4" />
                            Exportar
                        </button>
                        <button className="flex items-center justify-center gap-2 rounded-lg bg-[#FACC15] hover:bg-[#EAB308] transition-colors px-6 py-2.5 text-black font-bold text-sm shadow-[0_0_15px_rgba(250,204,21,0.15)]">
                            <TrendingUp className="h-4 w-4" />
                            Relatório Geral
                        </button>
                    </div>
                </div>

                {/* Filtros ativos (chips) */}
                {temFiltros && (
                    <div className="flex items-center gap-2 flex-wrap">
                        <span className="text-[10px] font-bold text-[#A3A3A3] uppercase tracking-widest">Ativos:</span>
                        {urgenciaAtiva.map((u) => (
                            <button
                                key={u}
                                onClick={() => toggleUrgencia(u)}
                                className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-red-500/10 text-red-400 border border-red-500/20 text-[10px] font-bold hover:bg-red-500/20 transition-colors"
                            >
                                {urgencyLabels[u]}
                                <X className="h-3 w-3" />
                            </button>
                        ))}
                        {beneficioAtivo.map((b) => (
                            <button
                                key={b}
                                onClick={() => toggleBeneficio(b)}
                                className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#FACC15]/10 text-[#FACC15] border border-[#FACC15]/20 text-[10px] font-bold hover:bg-[#FACC15]/20 transition-colors"
                            >
                                {b}
                                <X className="h-3 w-3" />
                            </button>
                        ))}
                    </div>
                )}

                {carregando ? (
                    <div className="flex items-center justify-center py-32">
                        <Loader2 className="h-8 w-8 text-[#FACC15] animate-spin" />
                    </div>
                ) : (
                    <>
                        {/* KPI Section */}
                        <div className="grid gap-6 md:grid-cols-3">
                            {indicators.map((kpi, i) => (
                                <div key={i} className="bg-[#171717] border border-[#333333] p-8 rounded-xl relative overflow-hidden group hover:border-[#FACC15]/30 transition-all">
                                    <div className="flex flex-col gap-2">
                                        <span className="text-[#A3A3A3] text-sm font-medium tracking-wide border-b border-[#333333] pb-2 w-fit">{kpi.title}</span>
                                        <div className="text-4xl font-black text-white mt-1 group-hover:text-[#FACC15] transition-colors">{kpi.value}</div>
                                    </div>
                                    <kpi.icon className={`absolute top-8 right-8 h-8 w-8 ${kpi.color} opacity-20 group-hover:opacity-100 transition-opacity`} />
                                </div>
                            ))}
                        </div>

                        {/* Critical Traffic Section */}
                        <div className="flex flex-col gap-4">
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-3">
                                    <span className="material-symbols-outlined text-[#FACC15]">warning</span>
                                    <h3 className="text-xl font-bold text-white uppercase tracking-tighter">Tráfego Crítico - Exigências INSS</h3>
                                </div>
                                <span className="text-xs text-[#A3A3A3] bg-[#1F1F1F] px-3 py-1 rounded-full border border-[#333333]">Scraping automático realizado há 15min</span>
                            </div>

                            <div className="bg-[#1F1F1F] border border-[#333333] rounded-xl overflow-hidden shadow-2xl">
                                <table className="min-w-full divide-y divide-[#333333]">
                                    <thead>
                                        <tr className="bg-[#262626]/30">
                                            <th className="px-6 py-4 text-left text-xs font-semibold text-[#A3A3A3] uppercase tracking-wider">Cliente</th>
                                            <th className="px-6 py-4 text-left text-xs font-semibold text-[#A3A3A3] uppercase tracking-wider">CPF</th>
                                            <th className="px-6 py-4 text-left text-xs font-semibold text-[#A3A3A3] uppercase tracking-wider">Processo</th>
                                            <th className="px-6 py-4 text-left text-xs font-semibold text-[#A3A3A3] uppercase tracking-wider">Benefício</th>
                                            <th className="px-6 py-4 text-left text-xs font-semibold text-[#A3A3A3] uppercase tracking-wider">Fase</th>
                                            <th className="px-6 py-4 text-left text-xs font-semibold text-[#A3A3A3] uppercase tracking-wider">Urgência</th>
                                            <th className="px-6 py-4 text-left text-xs font-semibold text-[#A3A3A3] uppercase tracking-wider">Ações</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-[#333333] bg-[#1F1F1F]">
                                        {exigenciasFiltradas.map((item) => (
                                            <tr key={item.id} className="group hover:bg-[#262626] transition-colors">
                                                <td className="px-6 py-4 whitespace-nowrap">
                                                    <div className="text-sm font-bold text-white group-hover:text-[#FACC15] transition-colors">{item.client}</div>
                                                </td>
                                                <td className="px-6 py-4 whitespace-nowrap text-sm text-[#A3A3A3] font-mono">{item.cpf}</td>
                                                <td className="px-6 py-4 whitespace-nowrap text-sm text-[#A3A3A3]">{item.process}</td>
                                                <td className="px-6 py-4 whitespace-nowrap text-sm text-white">
                                                    <span className="px-2.5 py-0.5 inline-flex text-xs leading-5 font-semibold rounded bg-[#FACC15]/10 text-[#FACC15] border border-[#FACC15]/20">
                                                        {item.benefit}
                                                    </span>
                                                </td>
                                                <td className="px-6 py-4 whitespace-nowrap">
                                                    <span className={`px-2.5 py-0.5 inline-flex text-xs leading-5 font-semibold rounded border ${FASE_KANBAN_COLORS[item.fase_kanban]}`}>
                                                        {FASE_KANBAN_LABELS[item.fase_kanban]}
                                                    </span>
                                                </td>
                                                <td className="px-6 py-4 whitespace-nowrap">
                                                    <span className={`px-2.5 py-0.5 inline-flex text-xs leading-5 font-semibold rounded border ${urgencyColors[item.urgency]}`}>
                                                        {urgencyLabels[item.urgency]}
                                                    </span>
                                                </td>
                                                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                                    <button className="text-[#A3A3A3] hover:text-[#FACC15] transition-all">
                                                        <span className="material-symbols-outlined text-[20px]">open_in_new</span>
                                                    </button>
                                                </td>
                                            </tr>
                                        ))}
                                        {exigenciasFiltradas.length === 0 && (
                                            <tr>
                                                <td colSpan={7} className="px-6 py-12 text-center text-[#A3A3A3] text-sm">
                                                    Nenhuma exigência encontrada
                                                </td>
                                            </tr>
                                        )}
                                    </tbody>
                                </table>
                                <div className="bg-[#262626]/30 px-6 py-3 border-t border-[#333333]">
                                    <p className="text-xs text-[#A3A3A3]">
                                        Mostrando {exigenciasFiltradas.length} de {exigenciasFormatadas.length} exigências
                                    </p>
                                </div>
                            </div>
                        </div>
                    </>
                )}
            </div>
        </DashboardLayout>
    )
}
