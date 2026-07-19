import React, { useState, useEffect } from 'react'
import { FiEye, FiDownload } from 'react-icons/fi'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Select, Input, Modal, Badge } from '../components/ui'
import { Table, FilterBar } from '../components/Table'
import toast from 'react-hot-toast'

const LogsPage = () => {
  const [logs, setLogs] = useState([])
  const [loading, setLoading] = useState(false)
  const [selectedLog, setSelectedLog] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [logType, setLogType] = useState('all')

  useEffect(() => {
    fetchLogs()
  }, [])

  const fetchLogs = async () => {
    try {
      setLoading(true)
      setLogs([
        {
          id: 1,
          type: 'login',
          user: 'admin@nexus.com',
          action: 'Login bem-sucedido',
          status: 'sucesso',
          timestamp: '2024-01-15 10:30:45',
          ip: '192.168.1.1',
          details: 'Autenticação bem-sucedida',
        },
        {
          id: 2,
          type: 'movie_create',
          user: 'admin@nexus.com',
          action: 'Novo filme adicionado',
          status: 'sucesso',
          timestamp: '2024-01-15 09:15:22',
          ip: '192.168.1.1',
          details: 'Filme: Breaking Bad',
        },
        {
          id: 3,
          type: 'payment',
          user: 'user@email.com',
          action: 'Pagamento processado',
          status: 'sucesso',
          timestamp: '2024-01-14 18:45:10',
          ip: '192.168.1.5',
          details: 'Cartão crédito - R$ 29,90',
        },
        {
          id: 4,
          type: 'error',
          user: 'user@email.com',
          action: 'Erro ao fazer login',
          status: 'erro',
          timestamp: '2024-01-14 15:20:33',
          ip: '192.168.1.8',
          details: 'Senha incorreta',
        },
        {
          id: 5,
          type: 'settings_update',
          user: 'admin@nexus.com',
          action: 'Configurações atualizadas',
          status: 'sucesso',
          timestamp: '2024-01-14 11:50:00',
          ip: '192.168.1.1',
          details: 'SMTP configurado',
        },
      ])
    } catch (error) {
      console.error('Erro ao carregar logs:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleExportLogs = async () => {
    try {
      const csv = [
        ['ID', 'Tipo', 'Usuário', 'Ação', 'Status', 'Data/Hora', 'IP', 'Detalhes'],
        ...logs.map(log => [
          log.id,
          log.type,
          log.user,
          log.action,
          log.status,
          log.timestamp,
          log.ip,
          log.details,
        ]),
      ]
        .map(row => row.map(cell => `"${cell}"`).join(','))
        .join('\n')

      const blob = new Blob([csv], { type: 'text/csv' })
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `logs_${new Date().toISOString().split('T')[0]}.csv`
      a.click()
      
      toast.success('Logs exportados!')
    } catch (error) {
      toast.error('Erro ao exportar logs')
    }
  }

  const columns = [
    {
      key: 'timestamp',
      label: 'Data/Hora',
      sortable: true,
      render: (value) => <span className="text-sm">{value}</span>,
    },
    {
      key: 'type',
      label: 'Tipo',
      render: (value) => {
        const colors = {
          login: 'primary',
          logout: 'secondary',
          movie_create: 'success',
          payment: 'success',
          error: 'error',
          settings_update: 'warning',
        }
        return <Badge variant={colors[value] || 'secondary'}>{value}</Badge>
      },
    },
    {
      key: 'user',
      label: 'Usuário',
      sortable: true,
      render: (value) => <span className="text-sm">{value}</span>,
    },
    {
      key: 'action',
      label: 'Ação',
      render: (value) => <span className="text-sm">{value}</span>,
    },
    {
      key: 'status',
      label: 'Status',
      render: (value) => (
        <Badge variant={value === 'sucesso' ? 'success' : 'error'}>
          {value === 'sucesso' ? '✓' : '✗'} {value}
        </Badge>
      ),
    },
    {
      key: 'ip',
      label: 'IP',
      render: (value) => <span className="text-xs font-mono">{value}</span>,
    },
  ]

  const actions = [
    {
      label: 'Detalhes',
      icon: FiEye,
      onClick: (log) => {
        setSelectedLog(log)
        setIsModalOpen(true)
      },
    },
  ]

  const filters = [
    {
      key: 'type',
      type: 'select',
      placeholder: 'Tipo de log',
      options: [
        { label: 'Todos', value: 'all' },
        { label: 'Login', value: 'login' },
        { label: 'Logout', value: 'logout' },
        { label: 'Filme', value: 'movie_create' },
        { label: 'Pagamento', value: 'payment' },
        { label: 'Erro', value: 'error' },
      ],
    },
  ]

  return (
    <Container>
      <PageHeader
        title="📋 Logs"
        subtitle="Registre e monitore todas as atividades"
        actions={[
          <Button
            key="export"
            variant="secondary"
            size="md"
            icon={FiDownload}
            onClick={handleExportLogs}
          >
            Exportar CSV
          </Button>,
        ]}
      />

      <Section className="mb-6">
        <FilterBar
          filters={filters}
          onFilterChange={(key, value) => setLogType(value)}
        />
      </Section>

      <Section>
        <Table
          columns={columns}
          data={logs}
          loading={loading}
          actions={actions}
          paginated={true}
          pageSize={15}
        />
      </Section>

      {/* Modal de Detalhes */}
      <Modal
        isOpen={isModalOpen}
        title="Detalhes do Log"
        size="lg"
        onClose={() => setIsModalOpen(false)}
        footer={
          <Button
            variant="ghost"
            onClick={() => setIsModalOpen(false)}
          >
            Fechar
          </Button>
        }
      >
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-xs font-semibold text-nexus-text-secondary mb-1">Tipo</p>
              <Badge variant="primary">{selectedLog?.type}</Badge>
            </div>
            <div>
              <p className="text-xs font-semibold text-nexus-text-secondary mb-1">Status</p>
              <Badge variant={selectedLog?.status === 'sucesso' ? 'success' : 'error'}>
                {selectedLog?.status}
              </Badge>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-xs font-semibold text-nexus-text-secondary mb-1">Usuário</p>
              <p className="text-nexus-text text-sm">{selectedLog?.user}</p>
            </div>
            <div>
              <p className="text-xs font-semibold text-nexus-text-secondary mb-1">IP</p>
              <p className="text-nexus-text text-sm font-mono">{selectedLog?.ip}</p>
            </div>
          </div>

          <div>
            <p className="text-xs font-semibold text-nexus-text-secondary mb-1">Data/Hora</p>
            <p className="text-nexus-text text-sm">{selectedLog?.timestamp}</p>
          </div>

          <div>
            <p className="text-xs font-semibold text-nexus-text-secondary mb-1">Ação</p>
            <p className="text-nexus-text">{selectedLog?.action}</p>
          </div>

          <div className="border-t border-nexus-card pt-4">
            <p className="text-xs font-semibold text-nexus-text-secondary mb-2">Detalhes</p>
            <div className="bg-nexus-card rounded p-3">
              <p className="text-nexus-text text-sm whitespace-pre-wrap">
                {selectedLog?.details}
              </p>
            </div>
          </div>
        </div>
      </Modal>
    </Container>
  )
}

export default LogsPage
