import React, { useState } from 'react'
import { FiUpload, FiRefreshCw, FiTrash2, FiDownload, FiAlertCircle } from 'react-icons/fi'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Input, Modal, Badge, Textarea } from '../components/ui'
import toast from 'react-hot-toast'

const M3UImporterPage = () => {
  const [loading, setLoading] = useState(false)
  const [importing, setImporting] = useState(false)
  const [progress, setProgress] = useState(0)
  const [importUrl, setImportUrl] = useState('')
  const [importedItems, setImportedItems] = useState(0)
  const [lastUpdate, setLastUpdate] = useState(null)
  const [autoUpdate, setAutoUpdate] = useState(false)

  const handleImportUrl = async () => {
    if (!importUrl.trim()) {
      toast.error('Digite a URL da lista M3U')
      return
    }

    try {
      setImporting(true)
      setProgress(0)

      // Simular importação
      for (let i = 0; i <= 100; i += 10) {
        setProgress(i)
        await new Promise(resolve => setTimeout(resolve, 200))
      }

      setImportedItems(Math.floor(Math.random() * 500) + 50)
      setLastUpdate(new Date().toLocaleString('pt-BR'))
      toast.success('Lista M3U importada com sucesso!')
      setImportUrl('')
    } catch (error) {
      toast.error('Erro ao importar lista M3U')
    } finally {
      setImporting(false)
      setProgress(0)
    }
  }

  const handleFileUpload = async (e) => {
    const file = e.target.files?.[0]
    if (!file) return

    try {
      setImporting(true)
      setProgress(0)

      // Simular upload
      for (let i = 0; i <= 100; i += 10) {
        setProgress(i)
        await new Promise(resolve => setTimeout(resolve, 200))
      }

      setImportedItems(Math.floor(Math.random() * 300) + 30)
      setLastUpdate(new Date().toLocaleString('pt-BR'))
      toast.success('Arquivo M3U importado com sucesso!')
    } catch (error) {
      toast.error('Erro ao fazer upload do arquivo')
    } finally {
      setImporting(false)
      setProgress(0)
    }
  }

  const handleRemoveDuplicates = async () => {
    try {
      setLoading(true)
      await new Promise(resolve => setTimeout(resolve, 1000))
      toast.success('Duplicatas removidas!')
    } catch (error) {
      toast.error('Erro ao remover duplicatas')
    } finally {
      setLoading(false)
    }
  }

  const handleAutoUpdate = async () => {
    try {
      setAutoUpdate(!autoUpdate)
      toast.success(autoUpdate ? 'Auto-atualização desativada' : 'Auto-atualização ativada')
    } catch (error) {
      toast.error('Erro ao configurar auto-atualização')
    }
  }

  return (
    <Container>
      <PageHeader
        title="📥 Importador M3U"
        subtitle="Importe listas IPTV ou M3U para a plataforma"
      />

      {/* Estatísticas */}
      <Section className="mb-6 grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-nexus-card border border-nexus-primary/20 rounded-xl p-6">
          <p className="text-nexus-text-secondary text-sm mb-2">Itens Importados</p>
          <p className="text-3xl font-bold text-nexus-primary">{importedItems}</p>
          {lastUpdate && <p className="text-xs text-nexus-text-secondary mt-2">{lastUpdate}</p>}
        </div>

        <div className="bg-nexus-card border border-nexus-secondary/20 rounded-xl p-6">
          <p className="text-nexus-text-secondary text-sm mb-2">Status</p>
          <p className="text-xl font-semibold text-nexus-secondary">
            {autoUpdate ? '🟢 Auto-atualização Ativa' : '🔴 Desativada'}
          </p>
        </div>

        <div className="bg-nexus-card border border-nexus-success/20 rounded-xl p-6">
          <p className="text-nexus-text-secondary text-sm mb-2">Última Atualização</p>
          <p className="text-lg font-semibold text-nexus-success">
            {lastUpdate ? lastUpdate.split(' ')[0] : 'Nunca'}
          </p>
        </div>
      </Section>

      {/* Importação por URL */}
      <Section className="mb-6">
        <h2 className="text-xl font-bold mb-4 text-nexus-text flex items-center gap-2">
          <FiUpload /> Importar por URL
        </h2>
        <div className="flex gap-3">
          <Input
            value={importUrl}
            onChange={(e) => setImportUrl(e.target.value)}
            placeholder="https://exemplo.com/lista.m3u"
            type="url"
            disabled={importing}
          />
          <Button
            variant="primary"
            onClick={handleImportUrl}
            loading={importing}
            icon={FiUpload}
          >
            Importar
          </Button>
        </div>

        {importing && (
          <div className="mt-4">
            <div className="flex justify-between mb-2">
              <span className="text-sm text-nexus-text-secondary">Importando...</span>
              <span className="text-sm font-semibold text-nexus-primary">{progress}%</span>
            </div>
            <div className="w-full bg-nexus-card rounded-full h-2 overflow-hidden">
              <div
                className="h-full bg-gradient-to-r from-nexus-primary to-nexus-secondary transition-all duration-300"
                style={{ width: `${progress}%` }}
              />
            </div>
          </div>
        )}
      </Section>

      {/* Upload de Arquivo */}
      <Section className="mb-6">
        <h2 className="text-xl font-bold mb-4 text-nexus-text flex items-center gap-2">
          <FiUpload /> Importar Arquivo
        </h2>
        <div className="border-2 border-dashed border-nexus-card rounded-xl p-8 text-center hover:border-nexus-primary transition-colors cursor-pointer">
          <label className="cursor-pointer">
            <input
              type="file"
              accept=".m3u,.m3u8,.txt"
              onChange={handleFileUpload}
              disabled={importing}
              className="hidden"
            />
            <div className="flex flex-col items-center gap-3">
              <FiUpload className="text-4xl text-nexus-text-secondary" />
              <div>
                <p className="text-nexus-text font-medium">Clique para selecionar arquivo</p>
                <p className="text-nexus-text-secondary text-sm">.m3u, .m3u8 ou .txt</p>
              </div>
            </div>
          </label>
        </div>
      </Section>

      {/* Opções */}
      <Section className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-nexus-card border border-nexus-card rounded-xl p-6">
          <h3 className="text-lg font-bold mb-4 text-nexus-text">Operações</h3>
          <div className="space-y-3">
            <Button
              variant="secondary"
              fullWidth
              icon={FiRefreshCw}
              onClick={handleAutoUpdate}
            >
              {autoUpdate ? 'Desativar' : 'Ativar'} Auto-atualização
            </Button>
            <Button
              variant="secondary"
              fullWidth
              icon={FiTrash2}
              onClick={handleRemoveDuplicates}
              loading={loading}
            >
              Remover Duplicatas
            </Button>
            <Button
              variant="ghost"
              fullWidth
              icon={FiDownload}
            >
              Exportar Lista
            </Button>
          </div>
        </div>

        <div className="bg-nexus-card border border-nexus-card rounded-xl p-6">
          <h3 className="text-lg font-bold mb-4 text-nexus-text flex items-center gap-2">
            <FiAlertCircle /> Informações
          </h3>
          <ul className="space-y-2 text-sm text-nexus-text-secondary">
            <li>• Formato suportado: M3U, M3U8</li>
            <li>• Tamanho máximo: 50MB</li>
            <li>• Auto-atualização: Diária</li>
            <li>• Limpa duplicatas automaticamente</li>
            <li>• Backup automático de lista anterior</li>
          </ul>
        </div>
      </Section>
    </Container>
  )
}

export default M3UImporterPage
