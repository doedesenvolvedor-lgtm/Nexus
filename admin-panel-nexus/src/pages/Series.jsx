import React, { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { FiPlus, FiEdit, FiTrash2, FiSearch } from 'react-icons/fi'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Input, Select, Modal, Badge, Textarea } from '../components/ui'
import { Table, FilterBar } from '../components/Table'

const SeriesPage = () => {
  const [series, setSeries] = useState([])
  const [loading, setLoading] = useState(false)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedSeries, setSelectedSeries] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [isCreateMode, setIsCreateMode] = useState(false)
  const [formData, setFormData] = useState({
    title: '',
    sinopse: '',
    year: new Date().getFullYear(),
    category: '',
    quality: '1080p',
    language: 'Português',
    totalSeasons: 1,
  })

  useEffect(() => {
    fetchSeries()
  }, [])

  const fetchSeries = async () => {
    try {
      setLoading(true)
      // Mock data - substituir por API real
      setSeries([
        { id: 1, title: 'Breaking Bad', year: 2008, category: 'Drama', totalSeasons: 5, quality: '1080p' },
        { id: 2, title: 'The Crown', year: 2016, category: 'Drama', totalSeasons: 5, quality: '1080p' },
      ])
    } catch (error) {
      console.error('Erro ao carregar séries:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleCreateSeries = () => {
    setIsCreateMode(true)
    setFormData({
      title: '',
      sinopse: '',
      year: new Date().getFullYear(),
      category: '',
      quality: '1080p',
      language: 'Português',
      totalSeasons: 1,
    })
    setIsModalOpen(true)
  }

  const handleEditSeries = (item) => {
    setIsCreateMode(false)
    setSelectedSeries(item)
    setFormData(item)
    setIsModalOpen(true)
  }

  const handleDeleteSeries = async (item) => {
    if (window.confirm(`Deseja deletar a série "${item.title}"?`)) {
      try {
        setSeries(series.filter(s => s.id !== item.id))
      } catch (error) {
        console.error('Erro ao deletar série:', error)
      }
    }
  }

  const handleSaveSeries = async () => {
    try {
      if (isCreateMode) {
        setSeries([...series, { ...formData, id: Date.now() }])
      } else {
        setSeries(series.map(s => s.id === selectedSeries.id ? { ...selectedSeries, ...formData } : s))
      }
      setIsModalOpen(false)
    } catch (error) {
      console.error('Erro ao salvar série:', error)
    }
  }

  const columns = [
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
      key: 'totalSeasons',
      label: 'Temporadas',
      render: (value) => <Badge variant="primary">{value}</Badge>,
    },
    {
      key: 'category',
      label: 'Categoria',
      render: (value) => <Badge variant="secondary">{value}</Badge>,
    },
    {
      key: 'quality',
      label: 'Qualidade',
      render: (value) => <Badge variant="success">{value}</Badge>,
    },
  ]

  const actions = [
    {
      label: 'Editar',
      icon: FiEdit,
      onClick: (item) => handleEditSeries(item),
    },
    {
      label: 'Deletar',
      icon: FiTrash2,
      variant: 'danger',
      onClick: (item) => handleDeleteSeries(item),
    },
  ]

  const filters = [
    {
      key: 'search',
      type: 'text',
      placeholder: 'Buscar por título...',
    },
    {
      key: 'category',
      type: 'select',
      placeholder: 'Selecionar categoria',
      options: [
        { label: 'Drama', value: 'drama' },
        { label: 'Comédia', value: 'comedia' },
        { label: 'Ação', value: 'acao' },
        { label: 'Ficção', value: 'ficcao' },
      ],
    },
  ]

  return (
    <Container>
      <PageHeader
        title="📺 Séries"
        subtitle="Gerencie todo o catálogo de séries da plataforma"
        actions={[
          <Button
            key="create"
            variant="primary"
            size="md"
            icon={FiPlus}
            onClick={handleCreateSeries}
          >
            Nova Série
          </Button>,
        ]}
      />

      <Section className="mb-6">
        <FilterBar
          filters={filters}
          onFilterChange={(key, value) => setSearchTerm(value)}
        />
      </Section>

      <Section>
        <Table
          columns={columns}
          data={series}
          loading={loading}
          actions={actions}
          paginated={true}
          pageSize={10}
        />
      </Section>

      {/* Modal */}
      <Modal
        isOpen={isModalOpen}
        title={isCreateMode ? 'Nova Série' : `Editar: ${selectedSeries?.title}`}
        size="lg"
        onClose={() => setIsModalOpen(false)}
        footer={
          <>
            <Button
              variant="ghost"
              onClick={() => setIsModalOpen(false)}
            >
              Cancelar
            </Button>
            <Button
              variant="primary"
              onClick={handleSaveSeries}
            >
              {isCreateMode ? 'Criar' : 'Atualizar'}
            </Button>
          </>
        }
      >
        <div className="space-y-6">
          <Input
            label="Título"
            value={formData.title}
            onChange={(e) => setFormData({ ...formData, title: e.target.value })}
            placeholder="Digite o título da série"
            required
          />

          <Textarea
            label="Sinopse"
            value={formData.sinopse}
            onChange={(e) => setFormData({ ...formData, sinopse: e.target.value })}
            placeholder="Digite a sinopse da série"
            rows={4}
            required
          />

          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Ano"
              type="number"
              value={formData.year}
              onChange={(e) => setFormData({ ...formData, year: e.target.value })}
              required
            />
            <Input
              label="Total de Temporadas"
              type="number"
              value={formData.totalSeasons}
              onChange={(e) => setFormData({ ...formData, totalSeasons: e.target.value })}
              required
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <Select
              label="Qualidade"
              value={formData.quality}
              onChange={(e) => setFormData({ ...formData, quality: e.target.value })}
              options={[
                { label: '720p', value: '720p' },
                { label: '1080p', value: '1080p' },
                { label: '4K', value: '4k' },
              ]}
              required
            />
            <Select
              label="Idioma"
              value={formData.language}
              onChange={(e) => setFormData({ ...formData, language: e.target.value })}
              options={[
                { label: 'Português', value: 'Português' },
                { label: 'Inglês', value: 'Inglês' },
                { label: 'Espanhol', value: 'Espanhol' },
              ]}
              required
            />
          </div>

          <Select
            label="Categoria"
            value={formData.category}
            onChange={(e) => setFormData({ ...formData, category: e.target.value })}
            options={[
              { label: 'Drama', value: 'drama' },
              { label: 'Comédia', value: 'comedia' },
              { label: 'Ação', value: 'acao' },
              { label: 'Ficção Científica', value: 'ficção' },
              { label: 'Horror', value: 'horror' },
            ]}
            required
          />
        </div>
      </Modal>
    </Container>
  )
}

export default SeriesPage
