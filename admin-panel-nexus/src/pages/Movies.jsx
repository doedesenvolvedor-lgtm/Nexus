import React, { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { FiPlus, FiEdit, FiTrash2, FiSearch } from 'react-icons/fi'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Input, Select, Modal, Badge, Tabs } from '../components/ui'
import { Table, FilterBar } from '../components/Table'
import { moviesAPI } from '../api/endpoints'

const MoviesPage = () => {
  const [movies, setMovies] = useState([])
  const [loading, setLoading] = useState(false)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedMovie, setSelectedMovie] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [isCreateMode, setIsCreateMode] = useState(false)
  const [formData, setFormData] = useState({
    title: '',
    sinopse: '',
    year: new Date().getFullYear(),
    duration: '',
    category: '',
    quality: '1080p',
    language: 'Português',
  })

  useEffect(() => {
    fetchMovies()
  }, [])

  const fetchMovies = async () => {
    try {
      setLoading(true)
      const response = await moviesAPI.list(1, 20)
      setMovies(response.data.data || [])
    } catch (error) {
      console.error('Erro ao carregar filmes:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleCreateMovie = () => {
    setIsCreateMode(true)
    setFormData({
      title: '',
      sinopse: '',
      year: new Date().getFullYear(),
      duration: '',
      category: '',
      quality: '1080p',
      language: 'Português',
    })
    setIsModalOpen(true)
  }

  const handleEditMovie = (movie) => {
    setIsCreateMode(false)
    setSelectedMovie(movie)
    setFormData(movie)
    setIsModalOpen(true)
  }

  const handleDeleteMovie = async (movie) => {
    if (window.confirm(`Deseja deletar o filme "${movie.title}"?`)) {
      try {
        await moviesAPI.delete(movie.id)
        setMovies(movies.filter(m => m.id !== movie.id))
      } catch (error) {
        console.error('Erro ao deletar filme:', error)
      }
    }
  }

  const handleSaveMovie = async () => {
    try {
      if (isCreateMode) {
        const response = await moviesAPI.create(formData)
        setMovies([...movies, response.data])
      } else {
        await moviesAPI.update(selectedMovie.id, formData)
        setMovies(movies.map(m => m.id === selectedMovie.id ? { ...selectedMovie, ...formData } : m))
      }
      setIsModalOpen(false)
    } catch (error) {
      console.error('Erro ao salvar filme:', error)
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
      key: 'duration',
      label: 'Duração',
      render: (value) => <span>{value} min</span>,
    },
    {
      key: 'quality',
      label: 'Qualidade',
      render: (value) => <Badge variant="primary">{value}</Badge>,
    },
    {
      key: 'category',
      label: 'Categoria',
      render: (value) => <Badge variant="secondary">{value}</Badge>,
    },
  ]

  const actions = [
    {
      label: 'Editar',
      icon: FiEdit,
      onClick: (movie) => handleEditMovie(movie),
    },
    {
      label: 'Deletar',
      icon: FiTrash2,
      variant: 'danger',
      onClick: (movie) => handleDeleteMovie(movie),
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
        { label: 'Ação', value: 'acao' },
        { label: 'Drama', value: 'drama' },
        { label: 'Comédia', value: 'comedia' },
        { label: 'Terror', value: 'terror' },
      ],
    },
    {
      key: 'quality',
      type: 'select',
      placeholder: 'Selecionar qualidade',
      options: [
        { label: '720p', value: '720p' },
        { label: '1080p', value: '1080p' },
        { label: '4K', value: '4k' },
      ],
    },
  ]

  return (
    <Container>
      <PageHeader
        title="🎬 Filmes"
        subtitle="Gerencie todo o catálogo de filmes da plataforma"
        actions={[
          <Button
            key="create"
            variant="primary"
            size="md"
            icon={FiPlus}
            onClick={handleCreateMovie}
          >
            Novo Filme
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
          data={movies}
          loading={loading}
          actions={actions}
          paginated={true}
          pageSize={10}
        />
      </Section>

      {/* Modal */}
      <Modal
        isOpen={isModalOpen}
        title={isCreateMode ? 'Novo Filme' : `Editar: ${selectedMovie?.title}`}
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
              onClick={handleSaveMovie}
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
            placeholder="Digite o título do filme"
            required
          />

          <Input
            label="Sinopse"
            value={formData.sinopse}
            onChange={(e) => setFormData({ ...formData, sinopse: e.target.value })}
            placeholder="Digite a sinopse do filme"
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
              label="Duração (minutos)"
              type="number"
              value={formData.duration}
              onChange={(e) => setFormData({ ...formData, duration: e.target.value })}
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
              { label: 'Ação', value: 'acao' },
              { label: 'Drama', value: 'drama' },
              { label: 'Comédia', value: 'comedia' },
              { label: 'Terror', value: 'terror' },
              { label: 'Romance', value: 'romance' },
              { label: 'Ficção Científica', value: 'ficção' },
            ]}
            required
          />
        </div>
      </Modal>
    </Container>
  )
}

export default MoviesPage
