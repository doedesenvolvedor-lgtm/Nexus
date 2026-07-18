import React, { useState, useEffect } from 'react'
import { FiDownload } from 'react-icons/fi'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Badge } from '../components/ui'
import { Table, FilterBar } from '../components/Table'
import { StatCard } from '../components/Charts'
import { paymentsAPI } from '../api/endpoints'

const PaymentsPage = () => {
  const [payments, setPayments] = useState([])
  const [stats, setStats] = useState(null)
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    try {
      setLoading(true)
      const [paymentsResponse, statsResponse] = await Promise.all([
        paymentsAPI.list(1, 20),
        paymentsAPI.getStats(),
      ])
      setPayments(paymentsResponse.data.data || [])
      setStats(statsResponse.data)
    } catch (error) {
      console.error('Erro ao carregar dados:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleRefund = async (paymentId) => {
    if (window.confirm('Deseja reembolsar este pagamento?')) {
      try {
        await paymentsAPI.refund(paymentId)
        fetchData()
      } catch (error) {
        console.error('Erro ao reembolsar:', error)
      }
    }
  }

  const columns = [
    {
      key: 'id',
      label: 'ID',
      sortable: true,
    },
    {
      key: 'user_email',
      label: 'Usuário',
      sortable: true,
    },
    {
      key: 'amount',
      label: 'Valor',
      render: (value) => `R$ ${(value / 100).toFixed(2)}`,
    },
    {
      key: 'method',
      label: 'Método',
      render: (value) => <Badge variant="primary">{value}</Badge>,
    },
    {
      key: 'status',
      label: 'Status',
      render: (value) => {
        const colors = {
          approved: 'success',
          pending: 'warning',
          failed: 'error',
          refunded: 'secondary',
        }
        return <Badge variant={colors[value] || 'primary'}>{value}</Badge>
      },
    },
    {
      key: 'created_at',
      label: 'Data',
      render: (value) => new Date(value).toLocaleDateString('pt-BR'),
    },
  ]

  const actions = [
    {
      label: 'Reembolsar',
      variant: 'danger',
      onClick: (payment) => handleRefund(payment.id),
    },
  ]

  const filters = [
    {
      key: 'status',
      type: 'select',
      placeholder: 'Filtrar por status',
      options: [
        { label: 'Aprovado', value: 'approved' },
        { label: 'Pendente', value: 'pending' },
        { label: 'Falhou', value: 'failed' },
        { label: 'Reembolsado', value: 'refunded' },
      ],
    },
    {
      key: 'method',
      type: 'select',
      placeholder: 'Filtrar por método',
      options: [
        { label: 'Cartão', value: 'card' },
        { label: 'PIX', value: 'pix' },
        { label: 'Boleto', value: 'boleto' },
        { label: 'Mercado Pago', value: 'mercadopago' },
      ],
    },
  ]

  return (
    <Container>
      <PageHeader
        title="💰 Pagamentos"
        subtitle="Gerencie todos os pagamentos da plataforma"
        actions={[
          <Button key="export" variant="secondary" size="md" icon={FiDownload}>
            Exportar
          </Button>,
        ]}
      />

      {stats && (
        <Section className="mb-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <StatCard
              title="Receita Total"
              value={`R$ ${(stats.total_revenue / 100).toFixed(2)}`}
              color="success"
            />
            <StatCard
              title="Pagamentos Pendentes"
              value={stats.pending_count}
              color="warning"
            />
            <StatCard
              title="Reembolsos"
              value={`R$ ${(stats.refunded_amount / 100).toFixed(2)}`}
              color="error"
            />
          </div>
        </Section>
      )}

      <Section className="mb-6">
        <FilterBar filters={filters} />
      </Section>

      <Section>
        <Table
          columns={columns}
          data={payments}
          loading={loading}
          actions={actions}
          paginated={true}
          pageSize={10}
        />
      </Section>
    </Container>
  )
}

export default PaymentsPage
