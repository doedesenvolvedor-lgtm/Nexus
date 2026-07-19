import React, { useState, useEffect } from 'react'
import { FiPlus, FiEdit, FiTrash2 } from 'react-icons/fi'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Input, Select, Modal, Badge, Textarea } from '../components/ui'
import { Table, FilterBar } from '../components/Table'

const ChannelsPage = () => {
  const [channels, setChannels] = useState([])
  const [loading, setLoading] = useState(false)
  const [selectedChannel, setSelectedChannel] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [isCreateMode, setIsCreateMode] = useState(false)
  const [formData, setFormData] = useState({
    name: '',
    category: '',
    status: 'ativo',
    streamUrl: '',
    logo: '',
  })

  useEffect(() => {
    fetchChannels()
  }, [])

  const fetchChannels = async () => {
    try {
      setLoading(true)
      // Mock data
      setChannels([
        { id: 1, name: 'HBO', category: 'Premium', status: 'ativo', streamUrl: 'http://...', logo: 'hbo.png' },
        { id: 2, name: 'Globo', category: 'Aberta', status: 'ativo', streamUrl: 'http://...', logo: 'globo.png' },
      ])
    } catch (error) {
      console.error('Erro ao carregar canais:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleCreateChannel = () => {
    setIsCreateMode(true)
    setFormData({
      name: '',
      category: '',
      status: 'ativo',
      streamUrl: '',
      logo: '',
    })
    setIsModalOpen(true)
  }

  const handleEditChannel = (item) => {
    setIsCreateMode(false)
    setSelectedChannel(item)
    setFormData(item)
    setIsModalOpen(true)
  }

  const handleDeleteChannel = async (item) => {
    if (window.confirm(`Deseja deletar o canal "${item.name}"?`)) {
      setChannels(channels.filter(c => c.id !== item.id))
    }
  }

  const handleSaveChannel = async () => {
    try {
      if (isCreateMode) {
        setChannels([...channels, { ...formData, id: Date.now() }])
      } else {
        setChannels(channels.map(c => c.id === selectedChannel.id ? { ...selectedChannel, ...formData } : c))
      }
      setIsModalOpen(false)
    } catch (error) {
      console.error('Erro ao salvar canal:', error)
    }
  }

  const columns = [
    {
      key: 'name',
      label: 'Canal',
      sortable: true,
      render: (value) => <span className="font-medium">{value}</span>,
    },
    {
      key: 'category',
      label: 'Categoria',
      render: (value) => <Badge variant="secondary">{value}</Badge>,
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
  ]

  const actions = [
    {
      label: 'Editar',
      icon: FiEdit,
      onClick: (item) => handleEditChannel(item),
    },
    {
      label: 'Deletar',
      icon: FiTrash2,
      variant: 'danger',
      onClick: (item) => handleDeleteChannel(item),
    },
  ]

  return (
    <Container>
      <PageHeader
        title="📡 Canais ao Vivo"
        subtitle="Gerencie os canais ao vivo disponíveis"
        actions={[
          <Button
            key="create"
            variant="primary"
            size="md"
            icon={FiPlus}
            onClick={handleCreateChannel}
          >
            Novo Canal
          </Button>,
        ]}
      />

      <Section>
        <Table
          columns={columns}
          data={channels}
          loading={loading}
          actions={actions}
          paginated={true}
          pageSize={10}
        />
      </Section>

      {/* Modal */}
      <Modal
        isOpen={isModalOpen}
        title={isCreateMode ? 'Novo Canal' : `Editar: ${selectedChannel?.name}`}
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
              onClick={handleSaveChannel}
            >
              {isCreateMode ? 'Criar' : 'Atualizar'}
            </Button>
          </>
        }
      >
        <div className="space-y-6">
          <Input
            label="Nome do Canal"
            value={formData.name}
            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            placeholder="Ex: HBO, Globo, Netflix"
            required
          />

          <div className="grid grid-cols-2 gap-4">
            <Select
              label="Categoria"
              value={formData.category}
              onChange={(e) => setFormData({ ...formData, category: e.target.value })}
              options={[
                { label: 'Premium', value: 'premium' },
                { label: 'Aberta', value: 'aberta' },
                { label: 'Infantil', value: 'infantil' },
                { label: 'Documentário', value: 'documentario' },
              ]}
              required
            />
            <Select
              label="Status"
              value={formData.status}
              onChange={(e) => setFormData({ ...formData, status: e.target.value })}
              options={[
                { label: 'Ativo', value: 'ativo' },
                { label: 'Inativo', value: 'inativo' },
              ]}
              required
            />
          </div>

          <Input
            label="URL do Stream (M3U8)"
            value={formData.streamUrl}
            onChange={(e) => setFormData({ ...formData, streamUrl: e.target.value })}
            placeholder="https://..."
            type="url"
            required
          />

          <Input
            label="Logo (URL)"
            value={formData.logo}
            onChange={(e) => setFormData({ ...formData, logo: e.target.value })}
            placeholder="https://..."
            type="url"
          />
        </div>
      </Modal>
    </Container>
  )
}

export default ChannelsPage
