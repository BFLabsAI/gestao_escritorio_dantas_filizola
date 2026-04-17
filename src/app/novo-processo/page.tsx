"use client"

import { useState, useCallback, useEffect, Suspense } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import * as z from "zod"
import { useDropzone } from "react-dropzone"
import { useRouter, useSearchParams } from "next/navigation"

import DashboardLayout from "@/components/layout/dashboard-layout"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { UploadCloud, File as FileIcon, X, CheckCircle2, Loader2, Search, UserPlus, ArrowLeft } from "lucide-react"
import { buscarClientes, criarCliente } from "@/lib/services/clientes"
import { criarProcesso } from "@/lib/services/processos"
import { uploadDocumento, analisarDocumentos } from "@/lib/services/documentos"
import { supabase } from "@/lib/supabase/client"
import { TIPO_BENEFICIO_LABELS, getTipoBeneficioLabel } from "@/lib/types/database"
import type { Cliente } from "@/lib/types/database"

const formSchema = z.object({
    cpf: z.string().min(11, "CPF deve ter no mínimo 11 dígitos").max(14, "Formato inválido"),
    nome: z.string().min(3, "O nome deve ter pelo menos 3 caracteres"),
    sexo: z.string(),
    beneficio: z.string().min(1, "Selecione o benefício alvo"),
})

export default function NovoProcessoPageWrapper() {
    return (
        <Suspense fallback={<div className="flex items-center justify-center h-screen"><div className="animate-spin h-8 w-8 border-2 border-[#FACC15] border-t-transparent rounded-full" /></div>}>
            <NovoProcessoPage />
        </Suspense>
    )
}

function NovoProcessoPage() {
    const router = useRouter()
    const searchParams = useSearchParams()
    const modo = searchParams.get('modo') // 'novo-cliente' or 'cliente-existente'

    const [files, setFiles] = useState<File[]>([])
    const [isSubmitting, setIsSubmitting] = useState(false)
    const [isSuccess, setIsSuccess] = useState(false)
    const [erro, setErro] = useState("")
    const [beneficiosDisponiveis, setBeneficiosDisponiveis] = useState<string[]>(Object.keys(TIPO_BENEFICIO_LABELS))
    const [clientesDisponiveis, setClientesDisponiveis] = useState<Cliente[]>([])
    const [clienteSelecionadoId, setClienteSelecionadoId] = useState<string | null>(null)

    // Cliente existente mode state
    const [buscaCliente, setBuscaCliente] = useState("")
    const [clientesFiltrados, setClientesFiltrados] = useState<Cliente[]>([])
    const [clienteExistenteSelecionado, setClienteExistenteSelecionado] = useState<Cliente | null>(null)
    const [buscandoClientes, setBuscandoClientes] = useState(false)

    const form = useForm<z.infer<typeof formSchema>>({
        resolver: zodResolver(formSchema),
        defaultValues: { cpf: "", nome: "", sexo: "nao_informado", beneficio: "" },
    })

    const onDrop = useCallback((acceptedFiles: File[]) => {
        setFiles((prev) => [...prev, ...acceptedFiles])
    }, [])

    const { getRootProps, getInputProps, isDragActive } = useDropzone({
        onDrop,
        accept: { 'image/*': [], 'application/pdf': [], 'text/plain': ['.txt'], 'application/msword': ['.doc'], 'application/vnd.openxmlformats-officedocument.wordprocessingml.document': ['.docx'] }
    })

    const removeFile = (index: number) => {
        setFiles((prev) => prev.filter((_, i) => i !== index))
    }

    const formatarCPF = (value: string) => {
        const nums = value.replace(/\D/g, "").slice(0, 11)
        if (nums.length <= 3) return nums
        if (nums.length <= 6) return `${nums.slice(0, 3)}.${nums.slice(3)}`
        if (nums.length <= 9) return `${nums.slice(0, 3)}.${nums.slice(3, 6)}.${nums.slice(6)}`
        return `${nums.slice(0, 3)}.${nums.slice(3, 6)}.${nums.slice(6, 9)}-${nums.slice(9)}`
    }

    const encontrarClientePorCpf = (cpf: string) => {
        const cpfNormalizado = cpf.replace(/\D/g, "")
        return clientesDisponiveis.find((cliente) => cliente.cpf.replace(/\D/g, "") === cpfNormalizado)
    }

    const encontrarClientePorNome = (nome: string) => {
        const nomeNormalizado = nome.trim().toLowerCase()
        return clientesDisponiveis.find((cliente) => cliente.nome_completo.trim().toLowerCase() === nomeNormalizado)
    }

    const sincronizarCliente = (cliente: Cliente | undefined) => {
        if (!cliente) return

        setClienteSelecionadoId(cliente.id)
        form.setValue("nome", cliente.nome_completo, { shouldDirty: true, shouldValidate: true })
        form.setValue("cpf", formatarCPF(cliente.cpf), { shouldDirty: true, shouldValidate: true })
        form.setValue("sexo", cliente.sexo || "nao_informado", { shouldDirty: true })
    }

    useEffect(() => {
        async function carregarBeneficios() {
            const { data, error } = await supabase
                .from('exigencias_doc_gestao_escritorio_filizola')
                .select('tipo_beneficio')
                .eq('ativo', true)

            if (error || !data) return

            const valores = new Set<string>([
                ...Object.keys(TIPO_BENEFICIO_LABELS),
                ...data.map((item) => item.tipo_beneficio),
            ])

            setBeneficiosDisponiveis(Array.from(valores).sort((a, b) => getTipoBeneficioLabel(a).localeCompare(getTipoBeneficioLabel(b))))
        }

        carregarBeneficios()
    }, [])

    useEffect(() => {
        async function carregarClientes() {
            const { clientes, error } = await buscarClientes()
            if (!error && clientes) {
                setClientesDisponiveis(clientes)
            }
        }

        carregarClientes()
    }, [])

    // Busca de clientes no modo "cliente existente"
    useEffect(() => {
        if (modo !== 'cliente-existente' || !buscaCliente.trim()) {
            setClientesFiltrados([])
            return
        }

        const timer = setTimeout(async () => {
            setBuscandoClientes(true)
            const termo = buscaCliente.trim()
            const { clientes, error } = await buscarClientes(termo.length >= 2 ? termo : undefined)
            if (!error && clientes) {
                setClientesFiltrados(clientes.slice(0, 10))
            }
            setBuscandoClientes(false)
        }, 300)

        return () => clearTimeout(timer)
    }, [buscaCliente, modo])

    const selecionarClienteExistente = (cliente: Cliente) => {
        setClienteExistenteSelecionado(cliente)
        setClienteSelecionadoId(cliente.id)
        form.setValue("nome", cliente.nome_completo, { shouldDirty: true, shouldValidate: true })
        form.setValue("cpf", formatarCPF(cliente.cpf), { shouldDirty: true, shouldValidate: true })
        form.setValue("sexo", cliente.sexo || "nao_informado", { shouldDirty: true })
    }

    const onSubmit = async (values: z.infer<typeof formSchema>) => {
        setIsSubmitting(true)
        setErro("")

        try {
            let clienteId = clienteSelecionadoId

            if (!clienteId) {
                const clienteExistente = encontrarClientePorCpf(values.cpf) ?? encontrarClientePorNome(values.nome)

                if (clienteExistente) {
                    clienteId = clienteExistente.id
                    setClienteSelecionadoId(clienteExistente.id)
                }
            }

            if (!clienteId) {
                const { cliente: novoCliente, error: erroCliente } = await criarCliente({
                    nome_completo: values.nome,
                    cpf: values.cpf,
                    sexo: values.sexo,
                })

                if (erroCliente || !novoCliente) {
                    setErro("Erro ao criar cliente: " + (erroCliente?.message || "Tente novamente"))
                    setIsSubmitting(false)
                    return
                }

                clienteId = novoCliente.id
            }

            if (!clienteId) {
                setErro("Nao foi possivel identificar o cliente do processo.")
                setIsSubmitting(false)
                return
            }

            // 2. Criar processo
            const { processo: processoCriado, error: erroProcesso } = await criarProcesso({
                cliente_id: clienteId,
                tipo_beneficio: values.beneficio,
            })

            if (erroProcesso || !processoCriado) {
                setErro("Erro ao criar processo: " + (erroProcesso?.message || "Tente novamente"))
                setIsSubmitting(false)
                return
            }

            // 3. Fazer upload dos documentos
            if (files.length > 0) {
                let uploadComErro = false
                for (const arquivo of files) {
                    const { error: erroUpload } = await uploadDocumento({
                        processoId: processoCriado.id,
                        clienteId,
                        tipo_documento: "DOCUMENTO_GERAL",
                        categoria_documento: "OUTROS",
                        arquivo,
                    })
                    if (erroUpload) {
                        console.error("Erro ao enviar arquivo:", arquivo.name, erroUpload)
                        uploadComErro = true
                    }
                }

                // 4. Acionar análise por IA dos documentos enviados
                await analisarDocumentos(processoCriado.id).catch(() => {})

                if (uploadComErro) {
                    setErro("Processo criado, mas alguns arquivos não foram enviados. Você pode enviá-los depois na página do processo.")
                    setIsSubmitting(false)
                    return
                }
            }

            setIsSuccess(true)
            form.reset()
            setFiles([])
            setClienteSelecionadoId(null)
            setClienteExistenteSelecionado(null)
            setTimeout(() => {
                setIsSuccess(false)
                router.push('/board')
            }, 2000)
        } catch {
            setErro("Erro inesperado. Tente novamente.")
        } finally {
            setIsSubmitting(false)
        }
    }

    // Se modo = cliente-existente e nenhum cliente selecionado, mostrar busca
    const mostrarBuscaCliente = modo === 'cliente-existente' && !clienteExistenteSelecionado

    return (
        <DashboardLayout>
            <div className="flex flex-col gap-10 px-12 py-10 w-full max-w-5xl mx-auto bg-[#0A0A0A]">
                <div className="flex items-center justify-between border-b border-[#333333] pb-6">
                    <div>
                        <h1 className="text-4xl font-black text-white uppercase italic tracking-tighter">Entrada de Dossiê</h1>
                        <p className="text-[#A3A3A3] mt-1 font-medium">
                            {mostrarBuscaCliente
                                ? "Busque e selecione um cliente existente."
                                : "Capture documentos e inicie a auditoria automática da IA."}
                        </p>
                    </div>
                    {isSuccess && (
                        <div className="flex items-center gap-2 bg-[#FACC15]/10 text-[#FACC15] px-4 py-2 rounded-lg border border-[#FACC15]/20 animate-in fade-in slide-in-from-right-4">
                            <CheckCircle2 className="h-5 w-5" />
                            <span className="text-sm font-bold uppercase tracking-tight">Processo Criado com Sucesso!</span>
                        </div>
                    )}
                </div>

                {erro && (
                    <div className="bg-red-500/10 border border-red-500/20 text-red-400 px-4 py-3 rounded-lg text-sm font-bold">
                        {erro}
                    </div>
                )}

                {/* Painel de busca de cliente existente */}
                {mostrarBuscaCliente && (
                    <div className="bg-[#171717] border border-[#333333] p-8 rounded-xl shadow-2xl max-w-2xl mx-auto w-full">
                        <h3 className="text-xs font-black text-[#FACC15] uppercase tracking-[0.2em] mb-6">
                            Buscar Cliente Existente
                        </h3>

                        <div className="relative mb-6">
                            <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-[#A3A3A3]" />
                            <input
                                type="text"
                                value={buscaCliente}
                                onChange={(e) => setBuscaCliente(e.target.value)}
                                placeholder="Buscar por nome ou CPF..."
                                className="w-full h-14 bg-[#1F1F1F] border border-[#333333] text-white pl-12 pr-4 text-sm focus:border-[#FACC15] focus:ring-1 focus:ring-[#FACC15] transition-all rounded-lg outline-none placeholder:text-[#525252]"
                                autoFocus
                            />
                            {buscandoClientes && (
                                <Loader2 className="absolute right-4 top-1/2 -translate-y-1/2 h-5 w-5 text-[#FACC15] animate-spin" />
                            )}
                        </div>

                        {clientesFiltrados.length > 0 && (
                            <div className="space-y-2 max-h-80 overflow-y-auto">
                                {clientesFiltrados.map((cliente) => (
                                    <button
                                        key={cliente.id}
                                        onClick={() => selecionarClienteExistente(cliente)}
                                        className="w-full flex items-center justify-between p-4 bg-[#0A0A0A] border border-[#333333] rounded-lg hover:border-[#FACC15]/30 hover:bg-[#FACC15]/5 transition-all group"
                                    >
                                        <div className="flex items-center gap-4">
                                            <div className="h-10 w-10 rounded-full bg-[#262626] flex items-center justify-center text-sm font-bold text-[#FACC15] border border-[#FACC15]/30">
                                                {cliente.nome_completo.split(" ").map(n => n[0]).join("").slice(0, 2).toUpperCase()}
                                            </div>
                                            <div className="text-left">
                                                <p className="text-sm font-bold text-white group-hover:text-[#FACC15] transition-colors">
                                                    {cliente.nome_completo}
                                                </p>
                                                <p className="text-xs text-[#A3A3A3] font-mono">{formatarCPF(cliente.cpf)}</p>
                                            </div>
                                        </div>
                                        <div className="text-right">
                                            <p className="text-xs text-[#A3A3A3]">
                                                {cliente.telefone || '—'}
                                            </p>
                                            <p className="text-[10px] text-[#525252]">
                                                Desde {new Date(cliente.criado_em).toLocaleDateString("pt-BR")}
                                            </p>
                                        </div>
                                    </button>
                                ))}
                            </div>
                        )}

                        {buscaCliente.trim().length >= 2 && !buscandoClientes && clientesFiltrados.length === 0 && (
                            <div className="text-center py-8">
                                <p className="text-[#A3A3A3] text-sm">Nenhum cliente encontrado.</p>
                                <button
                                    onClick={() => router.push('/novo-processo?modo=novo-cliente')}
                                    className="mt-3 flex items-center gap-2 mx-auto text-[#FACC15] hover:text-[#EAB308] text-sm font-medium transition-colors"
                                >
                                    <UserPlus className="h-4 w-4" />
                                    Cadastrar como cliente novo
                                </button>
                            </div>
                        )}

                        <div className="mt-6 pt-4 border-t border-[#333333]">
                            <button
                                onClick={() => router.push('/novo-processo?modo=novo-cliente')}
                                className="flex items-center gap-2 text-[#A3A3A3] hover:text-[#FACC15] text-sm font-medium transition-colors"
                            >
                                <ArrowLeft className="h-4 w-4" />
                                Voltar para cadastro de cliente novo
                            </button>
                        </div>
                    </div>
                )}

                {/* Formulário de criação de processo (visível quando não está em modo de busca) */}
                {!mostrarBuscaCliente && (
                    <Form {...form}>
                        <form onSubmit={form.handleSubmit(onSubmit)} className="grid grid-cols-1 lg:grid-cols-5 gap-10">

                            <div className="lg:col-span-2 space-y-8">
                                <div className="bg-[#171717] border border-[#333333] p-6 rounded-xl space-y-6 shadow-2xl">
                                    <div className="flex items-center justify-between">
                                        <h3 className="text-xs font-black text-[#FACC15] uppercase tracking-[0.2em]">Dados do Requerente</h3>
                                        {modo === 'cliente-existente' && clienteExistenteSelecionado && (
                                            <button
                                                type="button"
                                                onClick={() => {
                                                    setClienteExistenteSelecionado(null)
                                                    setClienteSelecionadoId(null)
                                                    form.setValue("nome", "")
                                                    form.setValue("cpf", "")
                                                    form.setValue("sexo", "nao_informado")
                                                }}
                                                className="text-xs text-[#A3A3A3] hover:text-[#FACC15] transition-colors"
                                            >
                                                Trocar cliente
                                            </button>
                                        )}
                                    </div>

                                    {modo === 'cliente-existente' && clienteExistenteSelecionado && (
                                        <div className="p-3 bg-[#FACC15]/5 border border-[#FACC15]/20 rounded-lg flex items-center gap-3">
                                            <div className="h-8 w-8 rounded-full bg-[#262626] flex items-center justify-center text-xs font-bold text-[#FACC15] border border-[#FACC15]/30">
                                                {clienteExistenteSelecionado.nome_completo.split(" ").map(n => n[0]).join("").slice(0, 2).toUpperCase()}
                                            </div>
                                            <div>
                                                <p className="text-sm font-bold text-white">{clienteExistenteSelecionado.nome_completo}</p>
                                                <p className="text-xs text-[#A3A3A3] font-mono">{formatarCPF(clienteExistenteSelecionado.cpf)}</p>
                                            </div>
                                        </div>
                                    )}

                                    <FormField
                                        control={form.control}
                                        name="nome"
                                        render={({ field }) => (
                                            <FormItem>
                                                <FormLabel className="text-[10px] font-black uppercase text-[#A3A3A3] tracking-widest">Nome Completo</FormLabel>
                                                <FormControl>
                                                    <Input
                                                        list="clientes-por-nome"
                                                        placeholder="NOME DO CLIENTE"
                                                        className="bg-[#1F1F1F] border-[#333333] text-white focus:border-[#FACC15] transition-all h-12 uppercase font-bold text-sm"
                                                        disabled={!!clienteExistenteSelecionado}
                                                        {...field}
                                                        onChange={(e) => {
                                                            const value = e.target.value
                                                            field.onChange(value)

                                                            const cliente = encontrarClientePorNome(value)
                                                            if (cliente) {
                                                                sincronizarCliente(cliente)
                                                                return
                                                            }

                                                            setClienteSelecionadoId(null)
                                                        }}
                                                    />
                                                </FormControl>
                                                <datalist id="clientes-por-nome">
                                                    {clientesDisponiveis.map((cliente) => (
                                                        <option key={cliente.id} value={cliente.nome_completo} />
                                                    ))}
                                                </datalist>
                                                <FormMessage className="text-red-500 text-[10px] font-bold" />
                                            </FormItem>
                                        )}
                                    />

                                    <FormField
                                        control={form.control}
                                        name="cpf"
                                        render={({ field }) => (
                                            <FormItem>
                                                <FormLabel className="text-[10px] font-black uppercase text-[#A3A3A3] tracking-widest">CPF</FormLabel>
                                                <FormControl>
                                                    <Input
                                                        list="clientes-por-cpf"
                                                        placeholder="000.000.000-00"
                                                        className="bg-[#1F1F1F] border-[#333333] text-white focus:border-[#FACC15] transition-all h-12 font-mono"
                                                        disabled={!!clienteExistenteSelecionado}
                                                        {...field}
                                                        onChange={(e) => {
                                                            const value = formatarCPF(e.target.value)
                                                            field.onChange(value)

                                                            const cliente = encontrarClientePorCpf(value)
                                                            if (cliente) {
                                                                sincronizarCliente(cliente)
                                                                return
                                                            }

                                                            setClienteSelecionadoId(null)
                                                        }}
                                                    />
                                                </FormControl>
                                                <datalist id="clientes-por-cpf">
                                                    {clientesDisponiveis.map((cliente) => (
                                                        <option key={cliente.id} value={formatarCPF(cliente.cpf)} />
                                                    ))}
                                                </datalist>
                                                <FormMessage className="text-red-500 text-[10px] font-bold" />
                                            </FormItem>
                                        )}
                                    />

                                    <FormField
                                        control={form.control}
                                        name="beneficio"
                                        render={({ field }) => (
                                            <FormItem>
                                                <FormLabel className="text-[10px] font-black uppercase text-[#A3A3A3] tracking-widest">Benefício Alvo</FormLabel>
                                                <Select onValueChange={field.onChange} defaultValue={field.value} value={field.value}>
                                                    <FormControl>
                                                        <SelectTrigger className="bg-[#1F1F1F] border-[#333333] text-white h-12 focus:ring-0 focus:border-[#FACC15]">
                                                            <SelectValue placeholder="SELECIONE O BENEFÍCIO" />
                                                        </SelectTrigger>
                                                    </FormControl>
                                                    <SelectContent className="bg-[#171717] border-[#333333] text-white">
                                                        {beneficiosDisponiveis.map((value) => (
                                                            <SelectItem key={value} value={value}>{getTipoBeneficioLabel(value).toUpperCase()}</SelectItem>
                                                        ))}
                                                    </SelectContent>
                                                </Select>
                                                <FormMessage className="text-red-500 text-[10px] font-bold" />
                                            </FormItem>
                                        )}
                                    />

                                    <FormField
                                        control={form.control}
                                        name="sexo"
                                        render={({ field }) => (
                                            <FormItem>
                                                <FormLabel className="text-[10px] font-black uppercase text-[#A3A3A3] tracking-widest">Sexo</FormLabel>
                                                <Select onValueChange={field.onChange} defaultValue={field.value} value={field.value}>
                                                    <FormControl>
                                                        <SelectTrigger className="bg-[#1F1F1F] border-[#333333] text-white h-12 focus:ring-0 focus:border-[#FACC15]">
                                                            <SelectValue placeholder="SELECIONE" />
                                                        </SelectTrigger>
                                                    </FormControl>
                                                    <SelectContent className="bg-[#171717] border-[#333333] text-white">
                                                        <SelectItem value="masculino">Masculino</SelectItem>
                                                        <SelectItem value="feminino">Feminino</SelectItem>
                                                        <SelectItem value="nao_informado">Nao informado</SelectItem>
                                                    </SelectContent>
                                                </Select>
                                                <FormMessage className="text-red-500 text-[10px] font-bold" />
                                            </FormItem>
                                        )}
                                    />
                                </div>

                                <div className="bg-[#FACC15]/5 border border-[#FACC15]/20 p-5 rounded-xl shadow-inner">
                                    <div className="flex items-start gap-4">
                                        <span className="material-symbols-outlined text-[#FACC15] text-2xl">info</span>
                                        <p className="text-[11px] text-[#A3A3A3] font-medium leading-relaxed uppercase tracking-tight">
                                            <span className="text-white font-black block mb-1">Nota:</span>
                                            Se o cliente já existir, selecione pelo nome ou CPF e o outro campo será preenchido automaticamente. Se não existir, o sistema cria o cliente no envio.
                                        </p>
                                    </div>
                                </div>
                            </div>

                            <div className="lg:col-span-3 flex flex-col gap-6">
                                <div className="bg-[#171717] border border-[#333333] rounded-xl flex-1 flex flex-col overflow-hidden shadow-2xl">
                                    <div className="p-4 border-b border-[#333333] flex items-center justify-between bg-[#1F1F1F]/30">
                                        <h3 className="text-[10px] font-black uppercase text-[#A3A3A3] tracking-widest">Zona de Captura</h3>
                                        <span className="text-[10px] font-bold text-[#FACC15]">{files.length} ARQUIVOS CARREGADOS</span>
                                    </div>
                                    <div className="p-8 flex-1 flex flex-col">
                                        <div
                                            {...getRootProps()}
                                            className={`border-2 border-dashed rounded-2xl flex flex-col items-center justify-center p-12 text-center flex-1 cursor-pointer transition-all ${isDragActive ? 'border-[#FACC15] bg-[#FACC15]/5' : 'border-[#333333] bg-[#0A0A0A] hover:border-[#FACC15]/40 hover:bg-[#171717]'
                                                }`}
                                        >
                                            <input {...getInputProps()} />
                                            <div className="bg-[#1F1F1F] h-20 w-20 rounded-full flex items-center justify-center mb-6 border border-[#333333] group-hover:scale-105 transition-transform">
                                                <UploadCloud className="h-8 w-8 text-[#FACC15]" />
                                            </div>
                                            <h3 className="text-xl font-black text-white uppercase italic tracking-tighter">
                                                {isDragActive ? 'SOLTE AGORA' : 'Arraste o Dossiê Aqui'}
                                            </h3>
                                            <p className="text-xs text-[#A3A3A3] mt-2 font-bold tracking-widest uppercase">
                                                PDF • JPG • PNG • HEIC • DOC • DOCX • TXT
                                            </p>
                                        </div>

                                        {files.length > 0 && (
                                            <div className="mt-8 space-y-3">
                                                <div className="max-h-56 overflow-y-auto space-y-2 pr-2 scrollbar-thin scrollbar-thumb-[#333333]">
                                                    {files.map((file, index) => (
                                                        <div key={index} className="flex items-center justify-between p-4 bg-[#1F1F1F] border border-[#333333] rounded-lg group hover:border-[#FACC15]/30 transition-all">
                                                            <div className="flex items-center gap-4">
                                                                <div className="h-10 w-10 bg-[#0A0A0A] rounded flex items-center justify-center text-[#A3A3A3] group-hover:text-[#FACC15] transition-colors border border-[#333333]">
                                                                    <FileIcon className="h-5 w-5" />
                                                                </div>
                                                                <div>
                                                                    <p className="text-xs font-black text-white uppercase tracking-tight truncate max-w-[200px]">{file.name}</p>
                                                                    <p className="text-[10px] font-bold text-[#A3A3A3] uppercase">{(file.size / 1024 / 1024).toFixed(2)} MB</p>
                                                                </div>
                                                            </div>
                                                            <button onClick={() => removeFile(index)} className="p-2 text-[#A3A3A3] hover:text-red-500 transition-colors">
                                                                <X className="h-4 w-4" />
                                                            </button>
                                                        </div>
                                                    ))}
                                                </div>
                                            </div>
                                        )}
                                    </div>
                                    <div className="p-6 bg-[#1F1F1F]/30 border-t border-[#333333] flex justify-end">
                                        <button
                                            type="submit"
                                            disabled={isSubmitting}
                                            className="bg-[#FACC15] hover:bg-[#EAB308] disabled:opacity-50 disabled:grayscale transition-all text-black px-10 py-3 rounded-lg font-black text-xs uppercase tracking-[0.2em] shadow-[0_0_20px_rgba(250,204,21,0.2)] flex items-center gap-2"
                                        >
                                            {isSubmitting ? (
                                                <>
                                                    <Loader2 className="h-4 w-4 animate-spin" />
                                                    CRIANDO...
                                                </>
                                            ) : 'CRIAR PROCESSO'}
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </form>
                    </Form>
                )}
            </div>
        </DashboardLayout>
    )
}
