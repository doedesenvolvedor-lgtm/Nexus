import React, { useState, useEffect } from 'react'
import { FiPlus, FiEdit, FiTrash2, FiArrowUp, FiArrowDown } from 'react-icons/fi'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Input, Modal, Badge, Textarea } from '../components/ui'
import { Table } from '../components/Table'

const BannersPage = () => {
  const [banners, setBanners] = useState([])
  const [loading, setLoading] = useState(false)
  const [selectedBanner, setSelectedBanner] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [isCreateMode, setIsCreateMode] = useState(false)
  const [formData, setFormData] = useState({
    title: '',
    subtitle: '',
    imageUrl: '',
    linkUrl: '',
    status: 'ativo',
    startDate: '',
    endDate: '',
    order: 1,
  })

  useEffect(() => {
    fetchBanners()
  }, [])

  const fetchBanners = async () => {
    try {
      setLoading(true)
      setBanners([
        { id: 1, title: 'Banner 1', imageUrl: 'https://...', status: 'ativo', order: 1 },
        { id: 2, title: 'Banner 2', imageUrl: 'https://...', status: 'ativo', order: 2 },
      ])
    } catch (error) {
      console.error('Erro ao carregar banners:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleCreateBanner = () => {
    setIsCreateMode(true)
    setFormData({
      title: '',
      subtitle: '',
      imageUrl: '',
      linkUrl: '',
      status: 'ativo',
      startDate: '',
      endDate: '',
      order: 1,
    })
    setIsModalOpen(true)
  }

  const handleEditBanner = (item) => {
    setIsCreateMode(false)
    setSelectedBanner(item)
    setFormData(item)
    setIsModalOpen(true)
  }

  const handleDeleteBanner = async (item) => {
    if (window.confirm(`Deseja deletar o banner "${item.title}"?`)) {
      setBanners(banners.filter(b => b.id !== item.id))
    }
  }

  const handleSaveBanner = async () => {
    try {
      if (isCreateMode) {
        setBanners([...banners, { ...formData, id: Date.now() }])
      } else {
        setBanners(banners.map(b => b.id === selectedBanner.id ? { ...selectedBanner, ...formData } : b))
      }
      setIsModalOpen(false)
    } catch (error) {
      console.error('Erro ao salvar banner:', error)
    }
  }

  const handleReorder = (id, direction) => {
    const index = banners.findIndex(b => b.id === id)
    const newBanners = [...banners]
    
    if (direction === 'up' && index > 0) {
      [newBanners[index], newBanners[index - 1]] = [newBanners[index - 1], newBanners[index]]
    } else if (direction === 'down' && index < banners.length - 1) {
      [newBanners[index], newBanners[index + 1]] = [newBanners[index + 1], newBanners[index]]
    }
    
    setBanners(newBanners)
  }

  const columns = [
    {
      key: 'title',
      label: 'Título',
      sortable: true,
      render: (value) => <span className="font-medium">{value}</span>,
    },
    {
      key: 'imageUrl',
      label: 'Imagem',
      render: (value) => (
        <img 
          src={value} 
          alt="Banner" 
          className="h-10 w-20 object-cover rounded"
        />
      ),
    },
    {
      key: 'status',
      label: 'Status',
      render: (value) => (
        <Badge variant={value === 'ativo' ? 'success' : 'error'}>
          {value === 'ativo' ? '🟢 Ativo' : '🔴 Inativo'}
        </Badge>
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
      onClick: (item) => handleEditBanner(item),
    },
    {
      label: 'Deletar',
      icon: FiTrash2,
      variant: 'danger',
      onClick: (item) => handleDeleteBanner(item),
    },
  ]

  return (
    <Container>
      <PageHeader
        title="🖼️ Banners"
        subtitle="Gerencie os banners da página inicial"
        actions={[
          <Button
            key="create"
            variant="primary"
            size="md"
            icon={FiPlus}
            onClick={handleCreateBanner}
          >
            Novo Banner
          </Button>,
        ]}
      />

      <Section>
        <Table
          columns={columns}
          data={banners}
          loading={loading}
          actions={actions}
          paginated={true}
          pageSize={10}
        />
      </Section>

      {/* Modal */}
      <Modal
        isOpen={isModalOpen}
        title={isCreateMode ? 'Novo Banner' : `Editar: ${selectedBanner?.title}`}
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
              onClick={handleSaveBanner}
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
            placeholder="Digite o título do banner"
            required
          />

          <Input
            label="Subtítulo"
            value={formData.subtitle}
            onChange={(e) => setFormData({ ...formData, subtitle: e.target.value })}
            placeholder="Digite o subtítulo (opcional)"
          />

          <Input
            label="URL da Imagem"
            type="url"
            value={formData.imageUrl}
            onChange={(e) => setFormData({ ...formData, imageUrl: e.target.value })}
            placeholder="https://..."
            required
          />

          <Input
            label="URL do Link"
            type="url"
            value={formData.linkUrl}
            onChange={(e) => setFormData({ ...formData, linkUrl: e.target.value })}
            placeholder="https://... (opcional)"
          />

          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Data de Início"
              type="datetime-local"
              value={formData.startDate}
              onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
            />
            <Input
              label="Data de Término"
              type="datetime-local"
              value={formData.endDate}
              onChange={(e) => setFormData({ ...formData, endDate: e.target.value })}
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

export default BannersPage
