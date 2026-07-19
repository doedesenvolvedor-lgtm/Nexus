import React, { useState } from 'react'
import { FiSearch, FiRefreshCw, FiCheckCircle, FiAlertCircle } from 'react-icons/fi'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Input, Modal, Badge, Select } from '../components/ui'
import { Table } from '../components/Table'
import toast from 'react-hot-toast'

const TMDbIntegrationPage = () => {
  const [searchTerm, setSearchTerm] = useState('')
  const [results, setResults] = useState([])
  const [loading, setLoading] = useState(false)
  const [searchType, setSearchType] = useState('movie')
  const [selectedItem, setSelectedItem] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [syncing, setSyncing] = useState(false)
  const [lastSync, setLastSync] = useState(new Date().toLocaleString('pt-BR'))

  const handleSearch = async () => {
    if (!searchTerm.trim()) {
      toast.error('Digite um termo para buscar')
      return
    }

    try {
      setLoading(true)
      // Simular busca
      await new Promise(resolve => setTimeout(resolve, 800))
      
      const mockResults = [
        {
          id: 1,
          title: searchTerm,
          tmdbId: '550',
          year: 1999,
          rating: 8.8,
          synced: true,
          posterUrl: 'https://via.placeholder.com/100x150',
        },
        {
          id: 2,
          title: `${searchTerm} 2`,
          tmdbId: '551',
          year: 2001,
          rating: 7.2,
          synced: false,
          posterUrl: 'https://via.placeholder.com/100x150',
        },
      ]

      setResults(mockResults)
      toast.success('Busca concluída!')
    } catch (error) {
      toast.error('Erro ao buscar no TMDb')
    } finally {
      setLoading(false)
    }
  }

  const handleSyncItem = async (item) => {
    try {
      setSyncing(true)
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      setResults(results.map(r => 
        r.id === item.id ? { ...r, synced: true } : r
      ))
      
      setLastSync(new Date().toLocaleString('pt-BR'))
      toast.success(`"${item.title}" sincronizado com sucesso!`)
    } catch (error) {
      toast.error('Erro ao sincronizar')
    } finally {
      setSyncing(false)
    }
  }

  const handleSyncAll = async () => {
    try {
      setSyncing(true)
      await new Promise(resolve => setTimeout(resolve, 2000))
      
      setResults(results.map(r => ({ ...r, synced: true })))
      setLastSync(new Date().toLocaleString('pt-BR'))
      toast.success('Todos os itens sincronizados!')
    } catch (error) {
      toast.error('Erro ao sincronizar tudo')
    } finally {
      setSyncing(false)
    }
  }

  const columns = [
    {
      key: 'posterUrl',
      label: 'Poster',
      render: (value) => (
        <img 
          src={value} 
          alt="Poster" 
          className="h-12 w-8 object-cover rounded"
        />
      ),
    },
    {
      key: 'title',
      label: 'Título',
      sortable: true,
      render: (value) => <span className="font-medium">{value}</span>,
    },
    {
      key: 'year',
      label: 'Ano',
      sortable: true,
    },
    {
      key: 'rating',
      label: 'Classificação',
      render: (value) => <Badge variant="primary">⭐ {value}</Badge>,
    },
    {
      key: 'synced',
      label: 'Status',
      render: (value) => (
        <Badge variant={value ? 'success' : 'warning'}>
          {value ? '✓ Sincronizado' : '⏳ Pendente'}
        </Badge>
      ),
    },
  ]

  const actions = [
    {
      label: 'Sincronizar',
      icon: FiRefreshCw,
      onClick: (item) => handleSyncItem(item),
      hidden: (item) => item.synced,
    },
    {
      label: 'Ver Detalhes',
      onClick: (item) => {
        setSelectedItem(item)
        setIsModalOpen(true)
      },
    },
  ]

  return (
    <Container>
      <PageHeader
        title="🎬 Integração TMDb"
        subtitle="Sincronize conteúdo com The Movie Database"
      />

      {/* Informações de Sincronização */}
      <Section className="mb-6 bg-nexus-card border border-nexus-secondary/20 rounded-xl p-6">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-nexus-text-secondary text-sm">Última sincronização</p>
            <p className="text-lg font-semibold text-nexus-text">{lastSync}</p>
          </div>
          <Button
            variant="secondary"
            icon={FiRefreshCw}
            onClick={handleSyncAll}
            loading={syncing}
          >
            Sincronizar Tudo
          </Button>
        </div>
      </Section>

      {/* Busca */}
      <Section className="mb-6">
        <h2 className="text-xl font-bold mb-4 text-nexus-text">Buscar Conteúdo</h2>
        <div className="flex gap-3 flex-col md:flex-row">
          <Select
            value={searchType}
            onChange={(e) => setSearchType(e.target.value)}
            options={[
              { label: 'Filmes', value: 'movie' },
              { label: 'Séries', value: 'tv' },
              { label: 'Ambos', value: 'both' },
            ]}
            className="md:w-32"
          />
          <div className="flex gap-2 flex-1">
            <Input
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
              placeholder="Buscar filme, série ou pessoa..."
              icon={FiSearch}
              disabled={loading}
            />
            <Button
              variant="primary"
              icon={FiSearch}
              onClick={handleSearch}
              loading={loading}
            >
              Buscar
            </Button>
          </div>
        </div>
      </Section>

      {/* Resultados */}
      {results.length > 0 && (
        <Section>
          <h2 className="text-lg font-bold mb-4 text-nexus-text">
            Resultados ({results.length})
          </h2>
          <Table
            columns={columns}
            data={results}
            loading={false}
            actions={actions}
            paginated={true}
            pageSize={10}
          />
        </Section>
      )}

      {/* Modal de Detalhes */}
      <Modal
        isOpen={isModalOpen}
        title={selectedItem?.title}
        size="lg"
        onClose={() => setIsModalOpen(false)}
        footer={
          <Button
            variant="primary"
            onClick={() => {
              handleSyncItem(selectedItem)
              setIsModalOpen(false)
            }}
            loading={syncing}
          >
            Sincronizar Este Item
          </Button>
        }
      >
        <div className="space-y-6">
          <div className="flex gap-4">
            <img 
              src={selectedItem?.posterUrl} 
              alt="Poster" 
              className="h-32 w-24 object-cover rounded"
            />
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-2">
                <h3 className="text-xl font-bold text-nexus-text">{selectedItem?.title}</h3>
                <Badge variant="primary">ID: {selectedItem?.tmdbId}</Badge>
              </div>
              <p className="text-nexus-text-secondary mb-3">
                Ano: <span className="font-semibold">{selectedItem?.year}</span>
              </p>
              <div className="flex items-center gap-2 mb-3">
                <span className="text-2xl">⭐</span>
                <span className="text-lg font-bold text-nexus-text">{selectedItem?.rating}</span>
              </div>
              <Badge variant={selectedItem?.synced ? 'success' : 'warning'}>
                {selectedItem?.synced ? '✓ Sincronizado' : '⏳ Pendente'}
              </Badge>
            </div>
          </div>

          <div className="border-t border-nexus-card pt-4">
            <h4 className="font-semibold text-nexus-text mb-2">Campos a Sincronizar:</h4>
            <ul className="space-y-2 text-sm text-nexus-text-secondary">
              <li>✓ Capa/Poster</li>
              <li>✓ Sinopse</li>
              <li>✓ Elenco</li>
              <li>✓ Gêneros</li>
              <li>✓ Avaliação</li>
              <li>✓ Trailer</li>
            </ul>
          </div>
        </div>
      </Modal>
    </Container>
  )
}

export default TMDbIntegrationPage
