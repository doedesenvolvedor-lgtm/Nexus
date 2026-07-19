import React, { useState, useEffect } from 'react'
import { FiPlus, FiEdit, FiTrash2, FiLock } from 'react-icons/fi'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Input, Select, Modal, Badge } from '../components/ui'
import { Table } from '../components/Table'

const ProfilesPage = () => {
  const [profiles, setProfiles] = useState([])
  const [loading, setLoading] = useState(false)
  const [selectedProfile, setSelectedProfile] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [isCreateMode, setIsCreateMode] = useState(false)
  const [formData, setFormData] = useState({
    name: '',
    avatar: '',
    parentalControl: false,
    pin: '',
    language: 'Português',
  })

  useEffect(() => {
    fetchProfiles()
  }, [])

  const fetchProfiles = async () => {
    try {
      setLoading(true)
      setProfiles([
        { id: 1, name: 'Perfil Principal', avatar: '👤', parentalControl: false, user: 'admin@nexus.com' },
        { id: 2, name: 'Infantil', avatar: '👶', parentalControl: true, user: 'admin@nexus.com' },
      ])
    } catch (error) {
      console.error('Erro ao carregar perfis:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleCreateProfile = () => {
    setIsCreateMode(true)
    setFormData({
      name: '',
      avatar: '',
      parentalControl: false,
      pin: '',
      language: 'Português',
    })
    setIsModalOpen(true)
  }

  const handleEditProfile = (item) => {
    setIsCreateMode(false)
    setSelectedProfile(item)
    setFormData(item)
    setIsModalOpen(true)
  }

  const handleDeleteProfile = async (item) => {
    if (window.confirm(`Deseja deletar o perfil "${item.name}"?`)) {
      setProfiles(profiles.filter(p => p.id !== item.id))
    }
  }

  const handleSaveProfile = async () => {
    try {
      if (isCreateMode) {
        setProfiles([...profiles, { ...formData, id: Date.now() }])
      } else {
        setProfiles(profiles.map(p => p.id === selectedProfile.id ? { ...selectedProfile, ...formData } : p))
      }
      setIsModalOpen(false)
    } catch (error) {
      console.error('Erro ao salvar perfil:', error)
    }
  }

  const columns = [
    {
      key: 'avatar',
      label: 'Avatar',
      render: (value) => <span className="text-2xl">{value}</span>,
    },
    {
      key: 'name',
      label: 'Nome',
      sortable: true,
      render: (value) => <span className="font-medium">{value}</span>,
    },
    {
      key: 'user',
      label: 'Usuário',
    },
    {
      key: 'parentalControl',
      label: 'Controle Parental',
      render: (value) => (
        <Badge variant={value ? 'warning' : 'secondary'}>
          {value ? '🔒 Ativado' : '🔓 Desativado'}
        </Badge>
      ),
    },
  ]

  const actions = [
    {
      label: 'Editar',
      icon: FiEdit,
      onClick: (item) => handleEditProfile(item),
    },
    {
      label: 'Deletar',
      icon: FiTrash2,
      variant: 'danger',
      onClick: (item) => handleDeleteProfile(item),
    },
  ]

  return (
    <Container>
      <PageHeader
        title="👤 Perfis"
        subtitle="Gerencie os perfis de usuários"
        actions={[
          <Button
            key="create"
            variant="primary"
            size="md"
            icon={FiPlus}
            onClick={handleCreateProfile}
          >
            Novo Perfil
          </Button>,
        ]}
      />

      <Section>
        <Table
          columns={columns}
          data={profiles}
          loading={loading}
          actions={actions}
          paginated={true}
          pageSize={10}
        />
      </Section>

      {/* Modal */}
      <Modal
        isOpen={isModalOpen}
        title={isCreateMode ? 'Novo Perfil' : `Editar: ${selectedProfile?.name}`}
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
              onClick={handleSaveProfile}
            >
              {isCreateMode ? 'Criar' : 'Atualizar'}
            </Button>
          </>
        }
      >
        <div className="space-y-6">
          <Input
            label="Nome do Perfil"
            value={formData.name}
            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            placeholder="Ex: Perfil Principal, Infantil"
            required
          />

          <Input
            label="Avatar (Emoji)"
            value={formData.avatar}
            onChange={(e) => setFormData({ ...formData, avatar: e.target.value })}
            placeholder="👤"
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

          <div className="border-t border-nexus-card pt-6">
            <h3 className="text-sm font-semibold mb-4 text-nexus-text">Controle Parental</h3>
            <label className="flex items-center gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={formData.parentalControl}
                onChange={(e) => setFormData({ ...formData, parentalControl: e.target.checked })}
                className="w-4 h-4"
              />
              <span className="text-sm text-nexus-text">Ativar controle parental</span>
            </label>
          </div>

          {formData.parentalControl && (
            <Input
              label="PIN (4 dígitos)"
              type="password"
              value={formData.pin}
              onChange={(e) => setFormData({ ...formData, pin: e.target.value })}
              placeholder="****"
              maxLength="4"
              required
            />
          )}
        </div>
      </Modal>
    </Container>
  )
}

export default ProfilesPage
