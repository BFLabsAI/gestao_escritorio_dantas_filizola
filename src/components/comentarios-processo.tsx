"use client"

import { useState, useEffect, useRef } from "react"
import { Send, Loader2 } from "lucide-react"
import {
    buscarComentariosProcesso,
    criarComentarioProcesso,
    type ComentarioProcesso,
} from "@/lib/services/comentarios"

interface ComentariosProcessoProps {
    processoId: string
}

function getMvpUserId(): string {
    if (typeof window === "undefined") return ""
    let id = localStorage.getItem("mvp_usuario_temp_id")
    if (!id) {
        id = "mvp-" + crypto.randomUUID()
        localStorage.setItem("mvp_usuario_temp_id", id)
    }
    return id
}

export default function ComentariosProcesso({ processoId }: ComentariosProcessoProps) {
    const [comentarios, setComentarios] = useState<ComentarioProcesso[]>([])
    const [novoComentario, setNovoComentario] = useState("")
    const [enviando, setEnviando] = useState(false)
    const chatEndRef = useRef<HTMLDivElement>(null)
    const inputRef = useRef<HTMLInputElement>(null)

    useEffect(() => {
        carregarComentarios()
    }, [processoId])

    useEffect(() => {
        chatEndRef.current?.scrollIntoView({ behavior: "smooth" })
    }, [comentarios])

    async function carregarComentarios() {
        try {
            const { comentarios: data } = await buscarComentariosProcesso(processoId)
            if (data) setComentarios(data)
        } catch (e) {
            console.error("Erro comentarios processo:", e)
        }
    }

    async function handleEnviar() {
        const texto = novoComentario.trim()
        if (!texto) return

        setEnviando(true)
        setNovoComentario("")

        try {
            await criarComentarioProcesso(processoId, texto, getMvpUserId())
            await carregarComentarios()
        } catch (e) {
            console.error("Erro ao enviar:", e)
            setNovoComentario(texto)
        }

        setEnviando(false)
        inputRef.current?.focus()
    }

    function formatarData(data: string) {
        const agora = new Date()
        const d = new Date(data)
        const diffMin = Math.floor((agora.getTime() - d.getTime()) / 60000)
        if (diffMin < 1) return "agora"
        if (diffMin < 60) return `${diffMin}min`
        const diffHoras = Math.floor(diffMin / 60)
        if (diffHoras < 24) return `${diffHoras}h`
        const diffDias = Math.floor(diffMin / 1440)
        if (diffDias < 7) return `${diffDias}d`
        return d.toLocaleDateString("pt-BR", { day: "2-digit", month: "2-digit" })
    }

    function getNome(uid: string): string {
        if (uid.startsWith("mvp-")) return "Usuario"
        return uid.slice(0, 8)
    }

    function isMe(uid: string): boolean {
        return uid === getMvpUserId()
    }

    return (
        <div className="flex flex-col gap-3">
            {/* Lista de mensagens */}
            <div className="max-h-80 overflow-y-auto space-y-3 pr-1">
                {comentarios.length === 0 ? (
                    <p className="text-[#A3A3A3] text-sm text-center py-6 italic">
                        Nenhuma mensagem ainda. Inicie a conversa sobre este processo.
                    </p>
                ) : (
                    comentarios.map((c) => {
                        const me = isMe(c.usuario_id)
                        return (
                            <div key={c.id} className={`flex gap-3 ${me ? "flex-row-reverse" : ""}`}>
                                <div className={`h-7 w-7 rounded-full flex items-center justify-center text-[9px] font-bold border shrink-0 mt-0.5 ${
                                    me
                                        ? "bg-[#FACC15]/10 text-[#FACC15] border-[#FACC15]/20"
                                        : "bg-[#262626] text-[#FACC15] border-[#FACC15]/20"
                                }`}>
                                    {getNome(c.usuario_id).slice(0, 1).toUpperCase()}
                                </div>
                                <div className={`flex-1 min-w-0 max-w-[80%] ${me ? "text-right" : ""}`}>
                                    <div className={`flex items-center gap-2 ${me ? "justify-end" : ""}`}>
                                        <span className="text-xs font-bold text-white">
                                            {getNome(c.usuario_id)}
                                            {me && <span className="text-[9px] text-[#FACC15] ml-1">(voce)</span>}
                                        </span>
                                        <span className="text-[10px] text-[#525252]">{formatarData(c.criado_em)}</span>
                                    </div>
                                    <div className={`mt-1 inline-block px-3 py-2 rounded-xl text-sm leading-relaxed break-words ${
                                        me
                                            ? "bg-[#FACC15]/10 text-[#FACC15] rounded-br-sm"
                                            : "bg-[#0A0A0A] text-[#A3A3A3] border border-[#333333] rounded-bl-sm"
                                    }`}>
                                        {c.conteudo}
                                    </div>
                                </div>
                            </div>
                        )
                    })
                )}
                <div ref={chatEndRef} />
            </div>

            {/* Input */}
            <div className="flex gap-2 pt-2 border-t border-[#333333]">
                <input
                    ref={inputRef}
                    type="text"
                    value={novoComentario}
                    onChange={(e) => setNovoComentario(e.target.value)}
                    onKeyDown={(e) => {
                        if (e.key === "Enter" && !e.shiftKey) {
                            e.preventDefault()
                            handleEnviar()
                        }
                    }}
                    placeholder="Escrever mensagem..."
                    className="flex-1 bg-[#0A0A0A] border border-[#333333] rounded-lg px-4 py-2.5 text-sm text-white placeholder:text-[#525252] focus:outline-none focus:border-[#FACC15]/50 transition-colors"
                />
                <button
                    onClick={handleEnviar}
                    disabled={enviando || !novoComentario.trim()}
                    className="p-2.5 rounded-lg bg-[#FACC15] hover:bg-[#EAB308] disabled:opacity-30 transition-all"
                >
                    {enviando ? (
                        <Loader2 className="h-4 w-4 text-black animate-spin" />
                    ) : (
                        <Send className="h-4 w-4 text-black" />
                    )}
                </button>
            </div>
        </div>
    )
}
