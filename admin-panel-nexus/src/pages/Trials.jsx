import React, { useState, useEffect } from 'react'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Badge, Tabs } from '../components/ui'
import { Table } from '../components/Table'
import { StatCard } from '../components/Charts'
import { trialsAPI } from '../api/endpoints'
import { FiClock, FiUser, FiTrendingUp } from 'react-icons/fi'

const TrialsPage = () => {
  const [trials, setTrials] = useState([])
  const [stats, setStats] = useState(null)
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    try {
      setLoading(true)
      const [trialsResponse, statsResponse] = await Promise.all([
        trialsAPI.list(1, 20),
        trialsAPI.getStats(),
      ])
      setTrials(trialsResponse.data.data || [])
      setStats(statsResponse.data)
    } catch (error) {
      console.error('Erro ao carregar dados:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleExtendTrial = async (userId) => {
    try {
      await trialsAPI.extend(userId, 3)
      fetchData()
    } catch (error) {
      console.error('Erro ao estender trial:', error)
    }
  }

  const handleCancelTrial = async (userId) => {
    if (window.confirm('Deseja cancelar este trial?')) {
      try {
        await trialsAPI.cancel(userId)
        fetchData()
      } catch (error) {
        console.error('Erro ao cancelar trial:', error)
      }
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
      key: 'days_remaining',
      label: 'Dias Restantes',
      render: (value) => {
        let variant = 'success'
        if (value <= 1) variant = 'error'
        else if (value <= 3) variant = 'warning'
        return <Badge variant={variant}>{value} dias</Badge>
      },
    },
    {
      key: 'status',
      label: 'Status',
      render: (value) => {
        const colors = {
          active: 'success',
          expired: 'error',
          converted: 'primary',
        }
        return <Badge variant={colors[value] || 'primary'}>{value}</Badge>
      },
    },
    {
      key: 'created_at',
      label: 'Criado em',
      render: (value) => new Date(value).toLocaleDateString('pt-BR'),
    },
  ]

  const actions = [
    {
      label: 'Estender',
      onClick: (trial) => handleExtendTrial(trial.user_id),
    },
    {
      label: 'Cancelar',
      variant: 'danger',
      onClick: (trial) => handleCancelTrial(trial.user_id),
    },
  ]

  const trialsTab = {
    label: '📋 Lista de Trials',
    content: (
      <Table
        columns={columns}
        data={trials}
        loading={loading}
        actions={actions}
        paginated={true}
        pageSize={10}
      />
    ),
  }

  const statsTab = {
    label: '📊 Estatísticas',
    content: stats ? (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <StatCard
          icon={FiUser}
          title="Total de Trials"
          value={stats.total_trials}
          color="primary"
        />
        <StatCard
          icon={FiClock}
          title="Trials Ativos"
          value={stats.active_trials}
          color="success"
        />
        <StatCard
          icon={FiTrendingUp}
          title="Taxa de Conversão"
          value={`${stats.conversion_rate.toFixed(2)}%`}
          color="secondary"
        />
      </div>
    ) : null,
  }

  return (
    <Container>
      <PageHeader
        title="⏳ Trials"
        subtitle="Gerencie o sistema de testes gratuitos de 3 dias"
      />

      {stats && (
        <Section className="mb-6">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            <StatCard
              title="Total de Usuários"
              value={stats.total_users}
              color="primary"
            />
            <StatCard
              title="Trials Ativos"
              value={stats.active_trials}
              color="success"
            />
            <StatCard
              title="Trials Expirados"
              value={stats.expired_trials}
              color="warning"
            />
            <StatCard
              title="Taxa de Conversão"
              value={`${stats.conversion_rate.toFixed(2)}%`}
              color="secondary"
            />
          </div>
        </Section>
      )}

      <Section>
        <Tabs tabs={[trialsTab, statsTab]} />
      </Section>
    </Container>
  )
}

export default TrialsPage
