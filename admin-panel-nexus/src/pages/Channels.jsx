import React, { useState, useEffect } from 'react'
import { FiPlus, FiEdit, FiTrash2, FiLock, FiUnlock, FiTv } from 'react-icons/fi'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Input, Select, Modal, Badge, Textarea, Alert, EmptyState, Loading } from '../components/ui'
import { Table, FilterBar } from '../components/Table'
import { channelsAPI } from '../api/endpoints'

const RATING_OPTIONS = [
  { label: 'Livre', value: 'LIVRE' },
  { label: '10+', value: '10' },
  { label: '12+', value: '12' },
  { label: '14+', value: '14' },
  { label: '16+', value: '16' },
  { label: '18+', value: '18' },
]

const ChannelsPage = () => {
  const [channels, setChannels] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const [selectedChannel, setSelectedChannel] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [isCreateMode, setIsCreateMode] = useState(false)
  const [formData, setFormData] = useState({
    name: '',
    category: '',
    status: 'ativo',
    streamUrl: '',
    logo: '',
    rating: 'LIVRE',
    is_adult: false,
    is_blocked: false,
  })

  useEffect(() => {
    fetchChannels()
  }, [])

  const fetchChannels = async () => {
    try {
      setLoading(true)
      setError(null)
      const res = await channelsAPI.list(1, 100)
      const data = Array.isArray(res.data) ? res.data : (res.data?.data || [])
      setChannels(data.map((c) => ({
        id: c.id,
        name: c.name,
        category: c.category || '',
        status: c.is_active ? 'ativo' : 'inativo',
        streamUrl: c.url || '',
        logo: c.logo_url || '',
        rating: c.rating || 'LIVRE',
        is_adult: c.is_adult || false,
        is_blocked: c.is_blocked || false,
      })))
    } catch (err) {
      console.error('Erro ao carregar canais:', err)
      setError('Não foi possível carregar os canais. Verifique a API.')
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
      rating: 'LIVRE',
      is_adult: false,
      is_blocked: false,
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
      try {
        await channelsAPI.delete(item.id)
        setChannels(channels.filter((c) => c.id !== item.id))
      } catch (err) {
        console.error('Erro ao deletar canal:', err)
      }
    }
  }

  const handleSaveChannel = async () => {
    try {
      const payload = {
        name: formData.name,
        category: formData.category,
        is_active: formData.status === 'ativo',
        url: formData.streamUrl,
        logo_url: formData.logo,
        rating: formData.rating,
        is_adult: formData.is_adult,
      }
      if (isCreateMode) {
        const res = await channelsAPI.create(payload)
        const created = {
          id: res.data?.id || Date.now(),
          ...formData,
          id: res.data?.id || Date.now(),
        }
        setChannels([...channels, created])
      } else {
        await channelsAPI.update(formData.id, payload)
        setChannels(channels.map((c) => c.id === formData.id ? { ...c, ...formData } : c))
      }
      setIsModalOpen(false)
    } catch (err) {
      console.error('Erro ao salvar canal:', err)
      setError('Erro ao salvar canal. Verifique os dados.')
    }
  }

  const handleToggleBlock = async (item) => {
    try {
      if (item.is_blocked) {
        await channelsAPI.unblock(item.id)
        item.is_blocked = false
      } else {
        await channelsAPI.block(item.id)
        item.is_blocked = true
      }
      setChannels(channels.map((c) => c.id === item.id ? item : c))
    } catch (err) {
      console.error('Erro ao bloquear/desbloquear canal:', err)
    }
  }

  const columns = [
    {
      key: 'name',
      label: 'Canal',
      sortable: true,
      render: (value, row) => (
        <div className="flex items-center gap-3">
          <span className="font-medium">{value}</span>
          {row.is_blocked && (
            <Badge variant="error">🔒 Bloqueado</Badge>
          )}
          {row.is_adult && (
            <Badge variant="warning">18+</Badge>
          )}
        </div>
      ),
    },
    {
      key: 'category',
      label: 'Categoria',
      render: (value) => <Badge variant="secondary">{value || '—'}</Badge>,
    },
    {
      key: 'rating',
      label: 'Classificação',
      render: (value, row) => (
        <Badge variant={row.is_adult ? 'error' : 'primary'}>
          {row.is_adult || value === '18' ? '18+' : value}
        </Badge>
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
  ]

  const actions = [
    {
      label: 'Bloquear/Desbloquear',
      icon: FiLock,
      onClick: (item) => handleToggleBlock(item),
    },
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
        subtitle="Gerencie canais, classificação indicativa e bloqueio parental"
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

      {error && (
        <Alert
          variant="warning"
          title="Aviso"
          message={error}
          onClose={() => setError(null)}
          className="mb-6"
        />
      )}

      <Section>
        {loading ? (
          <div className="flex justify-center py-12">
            <Loading />
          </div>
        ) : channels.length === 0 ? (
          <EmptyState
            icon={FiTv}
            title="Nenhum canal encontrado"
            message="Crie um novo canal ou importe via M3U."
          />
        ) : (
          <Table
            columns={columns}
            data={channels}
            loading={loading}
            actions={actions}
            paginated={true}
            pageSize={10}
          />
        )}
      </Section>

      {/* Modal */}
      <Modal
        isOpen={isModalOpen}
        title={isCreateMode ? 'Novo Canal' : `Editar: ${selectedChannel?.name}`}
        size="lg"
        onClose={() => setIsModalOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setIsModalOpen(false)}>
              Cancelar
            </Button>
            <Button variant="primary" onClick={handleSaveChannel}>
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
                { label: 'Premium', value: 'Premium' },
                { label: 'Aberta', value: 'Aberta' },
                { label: 'Infantil', value: 'Infantil' },
                { label: 'Documentário', value: 'Documentário' },
                { label: 'Filmes', value: 'Filmes' },
                { label: 'Esportes', value: 'Esportes' },
                { label: 'Notícias', value: 'Notícias' },
                { label: 'Adulto', value: 'Adulto' },
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

          <div className="grid grid-cols-2 gap-4">
            <Select
              label="Classificação Indicativa"
              value={formData.rating}
              onChange={(e) => setFormData({ ...formData, rating: e.target.value, is_adult: e.target.value === '18' })}
              options={RATING_OPTIONS}
              required
            />
            <div className="flex items-end">
              <label className="flex items-center gap-3 p-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={formData.is_adult}
                  onChange={(e) => setFormData({ ...formData, is_adult: e.target.checked })}
                  className="w-4 h-4 accent-purple-600"
                />
                <span className="text-sm font-medium text-nexus-text">Canal Adulto (+18)</span>
              </label>
            </div>
          </div>

          <div className="flex items-center gap-3 p-3 rounded-lg bg-nexus-error/10 border border-nexus-error/30">
            <input
              type="checkbox"
              checked={formData.is_blocked}
              onChange={(e) => setFormData({ ...formData, is_blocked: e.target.checked })}
              className="w-4 h-4 accent-red-600"
            />
            <span className="text-sm font-medium text-nexus-text">
              Bloquear canal (exigirá PIN para acesso)
            </span>
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
