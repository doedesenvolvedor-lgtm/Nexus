import React, { useState, useEffect } from 'react'
import { FiPlus, FiEdit, FiTrash2 } from 'react-icons/fi'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Input, Select, Modal, Badge } from '../components/ui'
import { Table, FilterBar } from '../components/Table'
import { subscriptionsAPI, plansAPI } from '../api/endpoints'

const SubscriptionsPage = () => {
  const [subscriptions, setSubscriptions] = useState([])
  const [plans, setPlans] = useState([])
  const [loading, setLoading] = useState(false)
  const [selectedSubscription, setSelectedSubscription] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [formData, setFormData] = useState({
    plan: '',
    status: 'active',
  })

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    try {
      setLoading(true)
      const [subsResponse, plansResponse] = await Promise.all([
        subscriptionsAPI.list(1, 20),
        plansAPI.list(),
      ])
      setSubscriptions(subsResponse.data.data || [])
      setPlans(plansResponse.data || [])
    } catch (error) {
      console.error('Erro ao carregar dados:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleEditSubscription = (subscription) => {
    setSelectedSubscription(subscription)
    setFormData({
      plan: subscription.plan_id,
      status: subscription.status,
    })
    setIsModalOpen(true)
  }

  const handleCancelSubscription = async (subscription) => {
    if (window.confirm('Deseja cancelar essa assinatura?')) {
      try {
        await subscriptionsAPI.cancel(subscription.id)
        setSubscriptions(subscriptions.filter(s => s.id !== subscription.id))
      } catch (error) {
        console.error('Erro ao cancelar assinatura:', error)
      }
    }
  }

  const columns = [
    {
      key: 'user_email',
      label: 'Usuário',
      sortable: true,
    },
    {
      key: 'plan_name',
      label: 'Plano',
      render: (value) => <Badge variant="primary">{value}</Badge>,
    },
    {
      key: 'status',
      label: 'Status',
      render: (value) => {
        const colors = {
          active: 'success',
          inactive: 'warning',
          cancelled: 'error',
        }
        return <Badge variant={colors[value] || 'primary'}>{value}</Badge>
      },
    },
    {
      key: 'start_date',
      label: 'Data de Início',
      render: (value) => new Date(value).toLocaleDateString('pt-BR'),
    },
    {
      key: 'renewal_date',
      label: 'Próxima Renovação',
      render: (value) => new Date(value).toLocaleDateString('pt-BR'),
    },
  ]

  const actions = [
    {
      label: 'Editar',
      icon: FiEdit,
      onClick: (subscription) => handleEditSubscription(subscription),
    },
    {
      label: 'Cancelar',
      icon: FiTrash2,
      variant: 'danger',
      onClick: (subscription) => handleCancelSubscription(subscription),
    },
  ]

  const filters = [
    {
      key: 'search',
      type: 'text',
      placeholder: 'Buscar por email...',
    },
    {
      key: 'plan',
      type: 'select',
      placeholder: 'Filtrar por plano',
      options: [
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
        { label: 'Cancelado', value: 'cancelled' },
      ],
    },
  ]

  return (
    <Container>
      <PageHeader
        title="📊 Assinaturas"
        subtitle="Gerencie todas as assinaturas da plataforma"
      />

      <Section className="mb-6">
        <FilterBar filters={filters} />
      </Section>

      <Section>
        <Table
          columns={columns}
          data={subscriptions}
          loading={loading}
          actions={actions}
          paginated={true}
          pageSize={10}
        />
      </Section>

      {/* Modal */}
      <Modal
        isOpen={isModalOpen}
        title={`Editar Assinatura`}
        size="md"
        onClose={() => setIsModalOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setIsModalOpen(false)}>
              Cancelar
            </Button>
            <Button variant="primary" onClick={() => setIsModalOpen(false)}>
              Atualizar
            </Button>
          </>
        }
      >
        <div className="space-y-6">
          <Select
            label="Plano"
            value={formData.plan}
            onChange={(e) => setFormData({ ...formData, plan: e.target.value })}
            options={plans.map(plan => ({ label: plan.name, value: plan.id }))}
          />

          <Select
            label="Status"
            value={formData.status}
            onChange={(e) => setFormData({ ...formData, status: e.target.value })}
            options={[
              { label: 'Ativo', value: 'active' },
              { label: 'Inativo', value: 'inactive' },
              { label: 'Cancelado', value: 'cancelled' },
            ]}
          />
        </div>
      </Modal>
    </Container>
  )
}

export default SubscriptionsPage
