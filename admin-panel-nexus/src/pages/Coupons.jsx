import React, { useState, useEffect } from 'react'
import { FiPlus, FiEdit, FiTrash2, FiCopy } from 'react-icons/fi'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Input, Select, Modal, Badge, Textarea } from '../components/ui'
import { Table } from '../components/Table'

const CouponsPage = () => {
  const [coupons, setCoupons] = useState([])
  const [loading, setLoading] = useState(false)
  const [selectedCoupon, setSelectedCoupon] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [isCreateMode, setIsCreateMode] = useState(false)
  const [formData, setFormData] = useState({
    code: '',
    description: '',
    discountType: 'percentage',
    discountValue: '',
    maxUses: '',
    currentUses: 0,
    expiryDate: '',
    applicablePlans: [],
  })

  useEffect(() => {
    fetchCoupons()
  }, [])

  const fetchCoupons = async () => {
    try {
      setLoading(true)
      setCoupons([
        { id: 1, code: 'NEXUS2024', discountType: 'percentage', discountValue: 20, uses: 45, maxUses: 100, status: 'ativo' },
        { id: 2, code: 'WELCOME', discountType: 'fixed', discountValue: 10, uses: 120, maxUses: 200, status: 'ativo' },
      ])
    } catch (error) {
      console.error('Erro ao carregar cupons:', error)
    } finally {
      setLoading(false)
    }
  }

  const generateCode = () => {
    const code = 'NEXUS' + Math.random().toString(36).substr(2, 8).toUpperCase()
    setFormData({ ...formData, code })
  }

  const handleCreateCoupon = () => {
    setIsCreateMode(true)
    setFormData({
      code: '',
      description: '',
      discountType: 'percentage',
      discountValue: '',
      maxUses: '',
      currentUses: 0,
      expiryDate: '',
      applicablePlans: [],
    })
    setIsModalOpen(true)
  }

  const handleEditCoupon = (item) => {
    setIsCreateMode(false)
    setSelectedCoupon(item)
    setFormData(item)
    setIsModalOpen(true)
  }

  const handleDeleteCoupon = async (item) => {
    if (window.confirm(`Deseja deletar o cupom "${item.code}"?`)) {
      setCoupons(coupons.filter(c => c.id !== item.id))
    }
  }

  const handleSaveCoupon = async () => {
    try {
      if (isCreateMode) {
        setCoupons([...coupons, { ...formData, id: Date.now(), uses: 0 }])
      } else {
        setCoupons(coupons.map(c => c.id === selectedCoupon.id ? { ...selectedCoupon, ...formData } : c))
      }
      setIsModalOpen(false)
    } catch (error) {
      console.error('Erro ao salvar cupom:', error)
    }
  }

  const columns = [
    {
      key: 'code',
      label: 'Código',
      sortable: true,
      render: (value) => <span className="font-mono font-bold text-nexus-primary">{value}</span>,
    },
    {
      key: 'discountType',
      label: 'Tipo',
      render: (value) => <Badge variant="secondary">{value === 'percentage' ? '%' : 'R$'}</Badge>,
    },
    {
      key: 'discountValue',
      label: 'Desconto',
      render: (value, row) => (
        <span className="font-semibold">
          {row.discountType === 'percentage' ? `${value}%` : `R$ ${value}`}
        </span>
      ),
    },
    {
      key: 'uses',
      label: 'Usos',
      render: (value, row) => (
        <span>{value} / {row.maxUses || 'Ilimitado'}</span>
      ),
    },
    {
      key: 'status',
      label: 'Status',
      render: (value) => (
        <Badge variant={value === 'ativo' ? 'success' : 'error'}>
          {value === 'ativo' ? '🟢 Ativo' : '🔴 Expirado'}
        </Badge>
      ),
    },
  ]

  const actions = [
    {
      label: 'Editar',
      icon: FiEdit,
      onClick: (item) => handleEditCoupon(item),
    },
    {
      label: 'Deletar',
      icon: FiTrash2,
      variant: 'danger',
      onClick: (item) => handleDeleteCoupon(item),
    },
  ]

  return (
    <Container>
      <PageHeader
        title="🎟️ Cupons"
        subtitle="Gerencie os cupons de desconto"
        actions={[
          <Button
            key="create"
            variant="primary"
            size="md"
            icon={FiPlus}
            onClick={handleCreateCoupon}
          >
            Novo Cupom
          </Button>,
        ]}
      />

      <Section>
        <Table
          columns={columns}
          data={coupons}
          loading={loading}
          actions={actions}
          paginated={true}
          pageSize={10}
        />
      </Section>

      {/* Modal */}
      <Modal
        isOpen={isModalOpen}
        title={isCreateMode ? 'Novo Cupom' : `Editar: ${selectedCoupon?.code}`}
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
              onClick={handleSaveCoupon}
            >
              {isCreateMode ? 'Criar' : 'Atualizar'}
            </Button>
          </>
        }
      >
        <div className="space-y-6">
          <div className="flex gap-2">
            <Input
              label="Código"
              value={formData.code}
              onChange={(e) => setFormData({ ...formData, code: e.target.value.toUpperCase() })}
              placeholder="CUPOM2024"
              required
            />
            <div className="flex items-end pb-0">
              <Button
                variant="secondary"
                size="sm"
                icon={FiCopy}
                onClick={generateCode}
              >
                Gerar
              </Button>
            </div>
          </div>

          <Textarea
            label="Descrição"
            value={formData.description}
            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
            placeholder="Descreva o cupom"
            rows={3}
          />

          <div className="grid grid-cols-2 gap-4">
            <Select
              label="Tipo de Desconto"
              value={formData.discountType}
              onChange={(e) => setFormData({ ...formData, discountType: e.target.value })}
              options={[
                { label: 'Percentual (%)', value: 'percentage' },
                { label: 'Valor Fixo (R$)', value: 'fixed' },
              ]}
              required
            />
            <Input
              label={formData.discountType === 'percentage' ? 'Desconto (%)' : 'Desconto (R$)'}
              type="number"
              value={formData.discountValue}
              onChange={(e) => setFormData({ ...formData, discountValue: e.target.value })}
              required
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Máximo de Usos"
              type="number"
              value={formData.maxUses}
              onChange={(e) => setFormData({ ...formData, maxUses: e.target.value })}
              placeholder="Deixar em branco para ilimitado"
            />
            <Input
              label="Data de Expiração"
              type="date"
              value={formData.expiryDate}
              onChange={(e) => setFormData({ ...formData, expiryDate: e.target.value })}
            />
          </div>

          <Select
            label="Planos Aplicáveis"
            value={formData.applicablePlans.join(',')}
            onChange={(e) => setFormData({ ...formData, applicablePlans: e.target.value.split(',').filter(Boolean) })}
            options={[
              { label: 'Todos os planos', value: 'all' },
              { label: 'Apenas Básico', value: 'basic' },
              { label: 'Apenas Standard', value: 'standard' },
              { label: 'Apenas Premium', value: 'premium' },
            ]}
          />
        </div>
      </Modal>
    </Container>
  )
}

export default CouponsPage
