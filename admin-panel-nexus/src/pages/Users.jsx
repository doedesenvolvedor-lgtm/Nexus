import React, { useState, useEffect } from 'react'
import { FiPlus, FiEdit, FiTrash2 } from 'react-icons/fi'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Input, Select, Modal, Badge } from '../components/ui'
import { Table, FilterBar } from '../components/Table'
import { usersAPI } from '../api/endpoints'

const UsersPage = () => {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(false)
  const [selectedUser, setSelectedUser] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [formData, setFormData] = useState({
    username: '',
    email: '',
    plan: 'trial',
    status: 'active',
  })

  useEffect(() => {
    fetchUsers()
  }, [])

  const fetchUsers = async () => {
    try {
      setLoading(true)
      const response = await usersAPI.list(1, 20)
      setUsers(response.data.data || [])
    } catch (error) {
      console.error('Erro ao carregar usuários:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleEditUser = (user) => {
    setSelectedUser(user)
    setFormData(user)
    setIsModalOpen(true)
  }

  const handleDeleteUser = async (user) => {
    if (window.confirm(`Deseja deletar o usuário "${user.email}"?`)) {
      try {
        await usersAPI.delete(user.id)
        setUsers(users.filter(u => u.id !== user.id))
      } catch (error) {
        console.error('Erro ao deletar usuário:', error)
      }
    }
  }

  const handleBlockUser = async (user) => {
    try {
      await usersAPI.block(user.id)
      setUsers(users.map(u => u.id === user.id ? { ...u, status: 'blocked' } : u))
    } catch (error) {
      console.error('Erro ao bloquear usuário:', error)
    }
  }

  const handleChangePlan = async (userId, newPlan) => {
    try {
      await usersAPI.changePlan(userId, newPlan)
      setUsers(users.map(u => u.id === userId ? { ...u, plan: newPlan } : u))
    } catch (error) {
      console.error('Erro ao alterar plano:', error)
    }
  }

  const columns = [
    {
      key: 'email',
      label: 'Email',
      sortable: true,
    },
    {
      key: 'username',
      label: 'Username',
      sortable: true,
    },
    {
      key: 'plan',
      label: 'Plano',
      render: (value) => {
        const colors = {
          trial: 'warning',
          basic: 'primary',
          standard: 'secondary',
          premium: 'success',
        }
        return <Badge variant={colors[value] || 'primary'}>{value}</Badge>
      },
    },
    {
      key: 'status',
      label: 'Status',
      render: (value) => {
        const colors = {
          active: 'success',
          inactive: 'warning',
          blocked: 'error',
        }
        return <Badge variant={colors[value] || 'primary'}>{value}</Badge>
      },
    },
    {
      key: 'created_at',
      label: 'Data de Criação',
      render: (value) => new Date(value).toLocaleDateString('pt-BR'),
    },
  ]

  const actions = [
    {
      label: 'Editar',
      icon: FiEdit,
      onClick: (user) => handleEditUser(user),
    },
    {
      label: 'Deletar',
      icon: FiTrash2,
      variant: 'danger',
      onClick: (user) => handleDeleteUser(user),
    },
  ]

  const filters = [
    {
      key: 'search',
      type: 'text',
      placeholder: 'Buscar por email ou username...',
    },
    {
      key: 'plan',
      type: 'select',
      placeholder: 'Filtrar por plano',
      options: [
        { label: 'Trial', value: 'trial' },
        { label: 'Básico', value: 'basic' },
        { label: 'Standard', value: 'standard' },
        { label: 'Premium', value: 'premium' },
      ],
    },
    {
      key: 'status',
      type: 'select',
      placeholder: 'Filtrar por status',
      options: [
        { label: 'Ativo', value: 'active' },
        { label: 'Inativo', value: 'inactive' },
        { label: 'Bloqueado', value: 'blocked' },
      ],
    },
  ]

  return (
    <Container>
      <PageHeader
        title="👥 Usuários"
        subtitle="Gerencie todos os usuários da plataforma"
        actions={[]}
      />

      <Section className="mb-6">
        <FilterBar
          filters={filters}
        />
      </Section>

      <Section>
        <Table
          columns={columns}
          data={users}
          loading={loading}
          actions={actions}
          paginated={true}
          pageSize={10}
        />
      </Section>

      {/* Modal */}
      <Modal
        isOpen={isModalOpen}
        title={`Editar: ${selectedUser?.email}`}
        size="md"
        onClose={() => setIsModalOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setIsModalOpen(false)}>
              Cancelar
            </Button>
            <Button
              variant="primary"
              onClick={() => setIsModalOpen(false)}
            >
              Atualizar
            </Button>
          </>
        }
      >
        <div className="space-y-6">
          <Input
            label="Email"
            value={formData.email}
            onChange={(e) => setFormData({ ...formData, email: e.target.value })}
            disabled
          />

          <Input
            label="Username"
            value={formData.username}
            onChange={(e) => setFormData({ ...formData, username: e.target.value })}
          />

          <Select
            label="Plano"
            value={formData.plan}
            onChange={(e) => setFormData({ ...formData, plan: e.target.value })}
            options={[
              { label: 'Trial', value: 'trial' },
              { label: 'Básico', value: 'basic' },
              { label: 'Standard', value: 'standard' },
              { label: 'Premium', value: 'premium' },
            ]}
          />

          <Select
            label="Status"
            value={formData.status}
            onChange={(e) => setFormData({ ...formData, status: e.target.value })}
            options={[
              { label: 'Ativo', value: 'active' },
              { label: 'Inativo', value: 'inactive' },
              { label: 'Bloqueado', value: 'blocked' },
            ]}
          />
        </div>
      </Modal>
    </Container>
  )
}

export default UsersPage
