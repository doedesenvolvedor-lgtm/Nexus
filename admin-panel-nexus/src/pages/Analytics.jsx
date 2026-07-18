import React, { useState, useEffect } from 'react'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Tabs, Badge } from '../components/ui'
import { Table, FilterBar } from '../components/Table'
import { StatCard, SimpleLineChart, SimpleBarChart } from '../components/Charts'
import { analyticsAPI } from '../api/endpoints'
import { FiUsers, FiActivity, FiClock, FiTrendingUp, FiSmartphone } from 'react-icons/fi'

const AnalyticsPage = () => {
  const [loading, setLoading] = useState(false)
  const [analyticsData, setAnalyticsData] = useState({
    users: [],
    topContent: [],
    devices: [],
  })

  useEffect(() => {
    fetchAnalytics()
  }, [])

  const fetchAnalytics = async () => {
    try {
      setLoading(true)
      const [usersRes, topContentRes, devicesRes] = await Promise.all([
        analyticsAPI.getUsers('month'),
        analyticsAPI.getTopContent('movies', 10),
        analyticsAPI.getDevices(),
      ])
      setAnalyticsData({
        users: usersRes.data,
        topContent: topContentRes.data,
        devices: devicesRes.data,
      })
    } catch (error) {
      console.error('Erro ao carregar analytics:', error)
    } finally {
      setLoading(false)
    }
  }

  const usersTab = {
    label: '👥 Usuários',
    content: (
      <div className="space-y-6">
        <Section>
          <SimpleLineChart
            data={analyticsData.users}
            title="Crescimento de Usuários (30 dias)"
            xKey="date"
            yKey="count"
          />
        </Section>
      </div>
    ),
  }

  const contentTab = {
    label: '🎬 Conteúdo',
    content: (
      <Section>
        <Table
          columns={[
            { key: 'title', label: 'Título', sortable: true },
            { key: 'views', label: 'Visualizações', sortable: true, render: (v) => v.toLocaleString() },
            { key: 'watch_time', label: 'Tempo Assistido', render: (v) => `${v} min` },
          ]}
          data={analyticsData.topContent}
          loading={loading}
          paginated={true}
          pageSize={10}
        />
      </Section>
    ),
  }

  const devicesTab = {
    label: '📱 Dispositivos',
    content: (
      <Section>
        <Table
          columns={[
            {
              key: 'device',
              label: 'Dispositivo',
              render: (v) => <Badge variant="primary">{v}</Badge>,
            },
            { key: 'percentage', label: 'Percentual', render: (v) => `${v.toFixed(2)}%` },
            { key: 'count', label: 'Quantidade', render: (v) => v.toLocaleString() },
          ]}
          data={analyticsData.devices}
          paginated={false}
        />
      </Section>
    ),
  }

  return (
    <Container>
      <PageHeader
        title="📈 Analytics"
        subtitle="Análise detalhada de usuários, conteúdo e dispositivos"
      />

      <Section className="mb-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <StatCard
            icon={FiUsers}
            title="Usuários Ativos"
            value="12.543"
            color="primary"
          />
          <StatCard
            icon={FiActivity}
            title="Sessões"
            value="45.234"
            color="secondary"
          />
          <StatCard
            icon={FiClock}
            title="Tempo Médio"
            value="2h 34m"
            color="success"
          />
          <StatCard
            icon={FiSmartphone}
            title="Dispositivos"
            value="8.923"
            color="warning"
          />
        </div>
      </Section>

      <Section>
        <Tabs tabs={[usersTab, contentTab, devicesTab]} />
      </Section>
    </Container>
  )
}

export default AnalyticsPage
