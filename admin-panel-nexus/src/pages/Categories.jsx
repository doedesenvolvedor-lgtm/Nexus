import React, { useState, useEffect } from 'react'
import { FiPlus, FiEdit, FiTrash2 } from 'react-icons/fi'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Input, Select, Modal, Badge, Textarea } from '../components/ui'
import { Table } from '../components/Table'

const CategoriesPage = () => {
  const [categories, setCategories] = useState([])
  const [loading, setLoading] = useState(false)
  const [selectedCategory, setSelectedCategory] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [isCreateMode, setIsCreateMode] = useState(false)
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    icon: '',
    color: '#6D28FF',
    order: 1,
  })

  useEffect(() => {
    fetchCategories()
  }, [])

  const fetchCategories = async () => {
    try {
      setLoading(true)
      // Mock data
      setCategories([
        { id: 1, name: 'Ação', description: 'Filmes de ação e aventura', icon: '🎬', color: '#6D28FF', order: 1 },
        { id: 2, name: 'Drama', description: 'Dramas e histórias profundas', icon: '🎭', color: '#2B7FFF', order: 2 },
        { id: 3, name: 'Comédia', description: 'Conteúdo cômico e engraçado', icon: '😂', color: '#F59E0B', order: 3 },
      ])
    } catch (error) {
      console.error('Erro ao carregar categorias:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleCreateCategory = () => {
    setIsCreateMode(true)
    setFormData({
      name: '',
      description: '',
      icon: '',
      color: '#6D28FF',
      order: 1,
    })
    setIsModalOpen(true)
  }

  const handleEditCategory = (item) => {
    setIsCreateMode(false)
    setSelectedCategory(item)
    setFormData(item)
    setIsModalOpen(true)
  }

  const handleDeleteCategory = async (item) => {
    if (window.confirm(`Deseja deletar a categoria "${item.name}"?`)) {
      setCategories(categories.filter(c => c.id !== item.id))
    }
  }

  const handleSaveCategory = async () => {
    try {
      if (isCreateMode) {
        setCategories([...categories, { ...formData, id: Date.now() }])
      } else {
        setCategories(categories.map(c => c.id === selectedCategory.id ? { ...selectedCategory, ...formData } : c))
      }
      setIsModalOpen(false)
    } catch (error) {
      console.error('Erro ao salvar categoria:', error)
    }
  }

  const columns = [
    {
      key: 'icon',
      label: 'Ícone',
      render: (value) => <span className="text-2xl">{value}</span>,
    },
    {
      key: 'name',
      label: 'Nome',
      sortable: true,
      render: (value) => <span className="font-medium">{value}</span>,
    },
    {
      key: 'description',
      label: 'Descrição',
    },
    {
      key: 'color',
      label: 'Cor',
      render: (value) => (
        <div className="flex items-center gap-2">
          <div
            className="w-6 h-6 rounded"
            style={{ backgroundColor: value }}
          />
          <span className="text-sm">{value}</span>
        </div>
      ),
    },
    {
      key: 'order',
      label: 'Ordem',
      render: (value) => <Badge variant="primary">#{value}</Badge>,
    },
  ]

  const actions = [
    {
      label: 'Editar',
      icon: FiEdit,
      onClick: (item) => handleEditCategory(item),
    },
    {
      label: 'Deletar',
      icon: FiTrash2,
      variant: 'danger',
      onClick: (item) => handleDeleteCategory(item),
    },
  ]

  return (
    <Container>
      <PageHeader
        title="🎯 Categorias"
        subtitle="Organize o conteúdo em categorias"
        actions={[
          <Button
            key="create"
            variant="primary"
            size="md"
            icon={FiPlus}
            onClick={handleCreateCategory}
          >
            Nova Categoria
          </Button>,
        ]}
      />

      <Section>
        <Table
          columns={columns}
          data={categories}
          loading={loading}
          actions={actions}
          paginated={true}
          pageSize={10}
        />
      </Section>

      {/* Modal */}
      <Modal
        isOpen={isModalOpen}
        title={isCreateMode ? 'Nova Categoria' : `Editar: ${selectedCategory?.name}`}
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
              onClick={handleSaveCategory}
            >
              {isCreateMode ? 'Criar' : 'Atualizar'}
            </Button>
          </>
        }
      >
        <div className="space-y-6">
          <Input
            label="Nome da Categoria"
            value={formData.name}
            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            placeholder="Ex: Ação, Drama, Comédia"
            required
          />

          <Textarea
            label="Descrição"
            value={formData.description}
            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
            placeholder="Descreva o tipo de conteúdo"
            rows={3}
            required
          />

          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Ícone/Emoji"
              value={formData.icon}
              onChange={(e) => setFormData({ ...formData, icon: e.target.value })}
              placeholder="Ex: 🎬"
              required
            />
            <Input
              label="Cor (Hex)"
              type="color"
              value={formData.color}
              onChange={(e) => setFormData({ ...formData, color: e.target.value })}
              required
            />
          </div>

          <Input
            label="Ordem de Exibição"
            type="number"
            value={formData.order}
            onChange={(e) => setFormData({ ...formData, order: e.target.value })}
            required
          />
        </div>
      </Modal>
    </Container>
  )
}

export default CategoriesPage
