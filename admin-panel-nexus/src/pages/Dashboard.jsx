import React, { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import {
  FiUsers,
  FiTrendingUp,
  FiDollarSign,
  FiPlay,
  FiTv,
  FiZap,
  FiCpu,
  FiGlobe,
} from 'react-icons/fi'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Card, Tabs } from '../components/ui'
import {
  StatCard,
  SimpleLineChart,
  SimpleBarChart,
  SimplePieChart,
  ProgressBar,
} from '../components/Charts'
import { dashboardAPI } from '../api/endpoints'

const Dashboard = () => {
  const [loading, setLoading] = useState(true)
  const [stats, setStats] = useState(null)

  useEffect(() => {
    fetchStats()
  }, [])

  const fetchStats = async () => {
    try {
      setLoading(true)
      const response = await dashboardAPI.getStats()
      setStats(response.data)
    } catch (error) {
      console.error('Erro ao carregar estatísticas:', error)
    } finally {
      setLoading(false)
    }
  }

  // Sample data for charts
  const revenueData = [
    { name: 'Jan', revenue: 4000 },
    { name: 'Fev', revenue: 3000 },
    { name: 'Mar', revenue: 2000 },
    { name: 'Abr', revenue: 2780 },
    { name: 'Mai', revenue: 1890 },
    { name: 'Jun', revenue: 2390 },
  ]

  const newUsersData = [
    { name: 'Seg', users: 400 },
    { name: 'Ter', users: 300 },
    { name: 'Qua', users: 200 },
    { name: 'Qui', users: 278 },
    { name: 'Sex', users: 189 },
    { name: 'Sab', users: 239 },
    { name: 'Dom', users: 200 },
  ]

  const subscriptionData = [
    { name: 'Trial', value: 450 },
    { name: 'Básico', value: 300 },
    { name: 'Standard', value: 200 },
    { name: 'Premium', value: 150 },
  ]

  const deviceData = [
    { name: 'Android', value: 35 },
    { name: 'iOS', value: 30 },
    { name: 'Web', value: 25 },
    { name: 'Smart TV', value: 10 },
  ]

  const dashboardTabs = [
    {
      label: '📊 Visão Geral',
      content: (
        <div className="space-y-8">
          {/* KPI Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <StatCard
              icon={FiUsers}
              title="Total de Usuários"
              value="12.543"
              change="+12% vs mês anterior"
              color="primary"
            />
            <StatCard
              icon={FiZap}
              title="Usuários Online"
              value="1.234"
              change="+5.2% vs semana anterior"
              color="secondary"
            />
            <StatCard
              icon={FiDollarSign}
              title="Receita Mensal"
              value="R$ 98.543"
              change="+23.5% vs mês anterior"
              color="success"
            />
            <StatCard
              icon={FiTrendingUp}
              title="Assinantes Ativos"
              value="8.923"
              change="+8.3% vs mês anterior"
              color="warning"
            />
          </div>

          {/* Charts */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card>
              <SimpleLineChart
                data={revenueData}
                title="Receita Mensal"
                xKey="name"
                yKey="revenue"
                color="#6D28FF"
              />
            </Card>
            <Card>
              <SimpleBarChart
                data={newUsersData}
                title="Novos Usuários (Esta Semana)"
                xKey="name"
                yKey="users"
                color="#2B7FFF"
              />
            </Card>
          </div>

          {/* More Stats */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <StatCard
              icon={FiPlay}
              title="Filmes"
              value="1.234"
              color="primary"
            />
            <StatCard
              icon={FiTv}
              title="Séries"
              value="456"
              color="secondary"
            />
          </div>
        </div>
      ),
    },
    {
      label: '💳 Assinaturas',
      content: (
        <div className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card>
              <SimplePieChart
                data={subscriptionData}
                title="Distribuição de Planos"
                nameKey="name"
                valueKey="value"
              />
            </Card>
            <Card>
              <div className="space-y-6">
                {subscriptionData.map((item) => (
                  <ProgressBar
                    key={item.name}
                    label={item.name}
                    value={item.value}
                    max={500}
                    color="primary"
                  />
                ))}
              </div>
            </Card>
          </div>
        </div>
      ),
    },
    {
      label: '📱 Dispositivos',
      content: (
        <div className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card>
              <SimplePieChart
                data={deviceData}
                title="Distribuição de Dispositivos"
                nameKey="name"
                valueKey="value"
              />
            </Card>
            <Card>
              <div className="space-y-6">
                {deviceData.map((item) => (
                  <ProgressBar
                    key={item.name}
                    label={item.name}
                    value={item.value}
                    max={100}
                    color="secondary"
                  />
                ))}
              </div>
            </Card>
          </div>
        </div>
      ),
    },
  ]

  return (
    <Container>
      <PageHeader
        title="Dashboard"
        subtitle="Bem-vindo ao painel administrativo da Nexustwos"
        actions={[
          <Button key="refresh" variant="secondary" size="md" onClick={fetchStats}>
            🔄 Atualizar
          </Button>,
          <Button key="export" variant="ghost" size="md">
            📥 Exportar
          </Button>,
        ]}
      />

      <Tabs tabs={dashboardTabs} />
    </Container>
  )
}

export default Dashboard
