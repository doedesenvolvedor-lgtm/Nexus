import React, { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { FiPlus, FiEdit, FiTrash2 } from 'react-icons/fi'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Input, Select, Modal, Badge, Textarea } from '../components/ui'
import { Table, FilterBar } from '../components/Table'

const EpisodesPage = () => {
  const [episodes, setEpisodes] = useState([])
  const [loading, setLoading] = useState(false)
  const [selectedEpisode, setSelectedEpisode] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [isCreateMode, setIsCreateMode] = useState(false)
  const [formData, setFormData] = useState({
    title: '',
    seasonNumber: 1,
    episodeNumber: 1,
    duration: '',
    releaseDate: '',
    sinopse: '',
    series: '',
  })

  useEffect(() => {
    fetchEpisodes()
  }, [])

  const fetchEpisodes = async () => {
    try {
      setLoading(true)
      // Mock data
      setEpisodes([
        { id: 1, title: 'Pilot', seasonNumber: 1, episodeNumber: 1, series: 'Breaking Bad', duration: 58 },
        { id: 2, title: 'Cat\'s in the Bag', seasonNumber: 1, episodeNumber: 2, series: 'Breaking Bad', duration: 48 },
      ])
    } catch (error) {
      console.error('Erro ao carregar episódios:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleCreateEpisode = () => {
    setIsCreateMode(true)
    setFormData({
      title: '',
      seasonNumber: 1,
      episodeNumber: 1,
      duration: '',
      releaseDate: '',
      sinopse: '',
      series: '',
    })
    setIsModalOpen(true)
  }

  const handleEditEpisode = (item) => {
    setIsCreateMode(false)
    setSelectedEpisode(item)
    setFormData(item)
    setIsModalOpen(true)
  }

  const handleDeleteEpisode = async (item) => {
    if (window.confirm(`Deseja deletar o episódio "${item.title}"?`)) {
      setEpisodes(episodes.filter(e => e.id !== item.id))
    }
  }

  const handleSaveEpisode = async () => {
    try {
      if (isCreateMode) {
        setEpisodes([...episodes, { ...formData, id: Date.now() }])
      } else {
        setEpisodes(episodes.map(e => e.id === selectedEpisode.id ? { ...selectedEpisode, ...formData } : e))
      }
      setIsModalOpen(false)
    } catch (error) {
      console.error('Erro ao salvar episódio:', error)
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
      key: 'series',
      label: 'Série',
    },
    {
      key: 'seasonNumber',
      label: 'Temporada',
      render: (value) => <Badge variant="primary">T{value}</Badge>,
    },
    {
      key: 'episodeNumber',
      label: 'Episódio',
      render: (value) => <Badge variant="secondary">E{value}</Badge>,
    },
    {
      key: 'duration',
      label: 'Duração',
      render: (value) => <span>{value} min</span>,
    },
  ]

  const actions = [
    {
      label: 'Editar',
      icon: FiEdit,
      onClick: (item) => handleEditEpisode(item),
    },
    {
      label: 'Deletar',
      icon: FiTrash2,
      variant: 'danger',
      onClick: (item) => handleDeleteEpisode(item),
    },
  ]

  return (
    <Container>
      <PageHeader
        title="⏱️ Episódios"
        subtitle="Gerencie todos os episódios das séries"
        actions={[
          <Button
            key="create"
            variant="primary"
            size="md"
            icon={FiPlus}
            onClick={handleCreateEpisode}
          >
            Novo Episódio
          </Button>,
        ]}
      />

      <Section>
        <Table
          columns={columns}
          data={episodes}
          loading={loading}
          actions={actions}
          paginated={true}
          pageSize={10}
        />
      </Section>

      {/* Modal */}
      <Modal
        isOpen={isModalOpen}
        title={isCreateMode ? 'Novo Episódio' : `Editar: ${selectedEpisode?.title}`}
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
              onClick={handleSaveEpisode}
            >
              {isCreateMode ? 'Criar' : 'Atualizar'}
            </Button>
          </>
        }
      >
        <div className="space-y-6">
          <Select
            label="Série"
            value={formData.series}
            onChange={(e) => setFormData({ ...formData, series: e.target.value })}
            options={[
              { label: 'Breaking Bad', value: 'breaking_bad' },
              { label: 'The Crown', value: 'the_crown' },
            ]}
            required
          />

          <Input
            label="Título do Episódio"
            value={formData.title}
            onChange={(e) => setFormData({ ...formData, title: e.target.value })}
            placeholder="Digite o título do episódio"
            required
          />

          <Textarea
            label="Sinopse"
            value={formData.sinopse}
            onChange={(e) => setFormData({ ...formData, sinopse: e.target.value })}
            placeholder="Digite a sinopse do episódio"
            rows={3}
            required
          />

          <div className="grid grid-cols-3 gap-4">
            <Input
              label="Temporada"
              type="number"
              value={formData.seasonNumber}
              onChange={(e) => setFormData({ ...formData, seasonNumber: e.target.value })}
              required
            />
            <Input
              label="Episódio"
              type="number"
              value={formData.episodeNumber}
              onChange={(e) => setFormData({ ...formData, episodeNumber: e.target.value })}
              required
            />
            <Input
              label="Duração (min)"
              type="number"
              value={formData.duration}
              onChange={(e) => setFormData({ ...formData, duration: e.target.value })}
              required
            />
          </div>

          <Input
            label="Data de Lançamento"
            type="date"
            value={formData.releaseDate}
            onChange={(e) => setFormData({ ...formData, releaseDate: e.target.value })}
            required
          />
        </div>
      </Modal>
    </Container>
  )
}

export default EpisodesPage
