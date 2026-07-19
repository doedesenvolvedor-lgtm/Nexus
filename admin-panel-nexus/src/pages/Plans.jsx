import React, { useState, useEffect } from 'react'
import { FiPlus, FiEdit, FiTrash2 } from 'react-icons/fi'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Input, Select, Modal, Badge, Textarea } from '../components/ui'
import { Table } from '../components/Table'

const PlansPage = () => {
  const [plans, setPlans] = useState([])
  const [loading, setLoading] = useState(false)
  const [selectedPlan, setSelectedPlan] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [isCreateMode, setIsCreateMode] = useState(false)
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    price: '',
    screens: 1,
    quality: '1080p',
    features: '',
    downloadable: false,
    priority: false,
  })

  useEffect(() => {
    fetchPlans()
  }, [])

  const fetchPlans = async () => {
    try {
      setLoading(true)
      setPlans([
        { id: 1, name: 'Básico', price: 'R$ 10/mês', screens: 2, quality: '1080p', users: 1245 },
        { id: 2, name: 'Standard', price: 'R$ 20/mês', screens: 4, quality: '1080p', users: 2890 },
        { id: 3, name: 'Premium', price: 'R$ 30/mês', screens: 6, quality: '4K', users: 5670 },
      ])
    } catch (error) {
      console.error('Erro ao carregar planos:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleCreatePlan = () => {
    setIsCreateMode(true)
    setFormData({
      name: '',
      description: '',
      price: '',
      screens: 1,
      quality: '1080p',
      features: '',
      downloadable: false,
      priority: false,
    })
    setIsModalOpen(true)
  }

  const handleEditPlan = (item) => {
    setIsCreateMode(false)
    setSelectedPlan(item)
    setFormData(item)
    setIsModalOpen(true)
  }

  const handleDeletePlan = async (item) => {
    if (window.confirm(`Deseja deletar o plano "${item.name}"?`)) {
      setPlans(plans.filter(p => p.id !== item.id))
    }
  }

  const handleSavePlan = async () => {
    try {
      if (isCreateMode) {
        setPlans([...plans, { ...formData, id: Date.now() }])
      } else {
        setPlans(plans.map(p => p.id === selectedPlan.id ? { ...selectedPlan, ...formData } : p))
      }
      setIsModalOpen(false)
    } catch (error) {
      console.error('Erro ao salvar plano:', error)
    }
  }

  const columns = [
    {
      key: 'name',
      label: 'Plano',
      sortable: true,
      render: (value) => <span className="font-medium">{value}</span>,
    },
    {
      key: 'price',
      label: 'Preço',
      render: (value) => <Badge variant="primary">{value}</Badge>,
    },
    {
      key: 'screens',
      label: 'Telas',
      render: (value) => <span>{value} simultânea(s)</span>,
    },
    {
      key: 'quality',
      label: 'Qualidade',
      render: (value) => <Badge variant="success">{value}</Badge>,
    },
    {
      key: 'users',
      label: 'Assinantes',
      render: (value) => <span className="font-semibold">{value?.toLocaleString()}</span>,
    },
  ]

  const actions = [
    {
      label: 'Editar',
      icon: FiEdit,
      onClick: (item) => handleEditPlan(item),
    },
    {
      label: 'Deletar',
      icon: FiTrash2,
      variant: 'danger',
      onClick: (item) => handleDeletePlan(item),
    },
  ]

  return (
    <Container>
      <PageHeader
        title="💎 Planos"
        subtitle="Gerencie os planos de assinatura"
        actions={[
          <Button
            key="create"
            variant="primary"
            size="md"
            icon={FiPlus}
            onClick={handleCreatePlan}
          >
            Novo Plano
          </Button>,
        ]}
      />

      <Section>
        <Table
          columns={columns}
          data={plans}
          loading={loading}
          actions={actions}
          paginated={true}
          pageSize={10}
        />
      </Section>

      {/* Modal */}
      <Modal
        isOpen={isModalOpen}
        title={isCreateMode ? 'Novo Plano' : `Editar: ${selectedPlan?.name}`}
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
              onClick={handleSavePlan}
            >
              {isCreateMode ? 'Criar' : 'Atualizar'}
            </Button>
          </>
        }
      >
        <div className="space-y-6">
          <Input
            label="Nome do Plano"
            value={formData.name}
            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            placeholder="Ex: Básico, Standard, Premium"
            required
          />

          <Textarea
            label="Descrição"
            value={formData.description}
            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
            placeholder="Descreva o plano"
            rows={3}
            required
          />

          <Input
            label="Preço (ex: R$ 10/mês)"
            value={formData.price}
            onChange={(e) => setFormData({ ...formData, price: e.target.value })}
            placeholder="R$ X/mês"
            required
          />

          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Telas Simultâneas"
              type="number"
              value={formData.screens}
              onChange={(e) => setFormData({ ...formData, screens: e.target.value })}
              required
            />
            <Select
              label="Qualidade Máxima"
              value={formData.quality}
              onChange={(e) => setFormData({ ...formData, quality: e.target.value })}
              options={[
                { label: '720p', value: '720p' },
                { label: '1080p', value: '1080p' },
                { label: '4K', value: '4k' },
              ]}
              required
            />
          </div>

          <Textarea
            label="Recursos (um por linha)"
            value={formData.features}
            onChange={(e) => setFormData({ ...formData, features: e.target.value })}
            placeholder="HD&#10;Sem anúncios&#10;Downloads"
            rows={4}
          />

          <div className="space-y-3 border-t border-nexus-card pt-6">
            <label className="flex items-center gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={formData.downloadable}
                onChange={(e) => setFormData({ ...formData, downloadable: e.target.checked })}
                className="w-4 h-4"
              />
              <span className="text-sm text-nexus-text">Permite downloads</span>
            </label>
            <label className="flex items-center gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={formData.priority}
                onChange={(e) => setFormData({ ...formData, priority: e.target.checked })}
                className="w-4 h-4"
              />
              <span className="text-sm text-nexus-text">Prioridade na plataforma</span>
            </label>
          </div>
        </div>
      </Modal>
    </Container>
  )
}

export default PlansPage
