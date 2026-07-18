import React, { useState, useEffect } from 'react'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Input, Select, Textarea, Modal, Badge } from '../components/ui'
import { FiPlus } from 'react-icons/fi'
import { notificationsAPI } from '../api/endpoints'

const NotificationsPage = () => {
  const [notifications, setNotifications] = useState([])
  const [loading, setLoading] = useState(false)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [formData, setFormData] = useState({
    title: '',
    message: '',
    target: 'all',
    schedule: false,
    scheduledTime: '',
  })

  useEffect(() => {
    fetchNotifications()
  }, [])

  const fetchNotifications = async () => {
    try {
      setLoading(true)
      const response = await notificationsAPI.getHistory()
      setNotifications(response.data.data || [])
    } catch (error) {
      console.error('Erro ao carregar notificações:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSendNotification = async () => {
    try {
      if (formData.schedule) {
        await notificationsAPI.schedule(formData)
      } else {
        await notificationsAPI.send(formData)
      }
      setIsModalOpen(false)
      fetchNotifications()
      setFormData({
        title: '',
        message: '',
        target: 'all',
        schedule: false,
        scheduledTime: '',
      })
    } catch (error) {
      console.error('Erro ao enviar notificação:', error)
    }
  }

  const targetOptions = [
    { label: 'Todos', value: 'all' },
    { label: 'Premium', value: 'premium' },
    { label: 'Trial', value: 'trial' },
    { label: 'Básico', value: 'basic' },
    { label: 'Standard', value: 'standard' },
  ]

  return (
    <Container>
      <PageHeader
        title="🔔 Notificações"
        subtitle="Envie notificações para os usuários da plataforma"
        actions={[
          <Button
            key="create"
            variant="primary"
            size="md"
            icon={FiPlus}
            onClick={() => setIsModalOpen(true)}
          >
            Nova Notificação
          </Button>,
        ]}
      />

      <Section>
        <div className="space-y-4">
          {notifications.length === 0 ? (
            <p className="text-center text-nexus-text-secondary py-8">
              Nenhuma notificação enviada ainda
            </p>
          ) : (
            notifications.map((notif, idx) => (
              <div
                key={idx}
                className="p-4 bg-nexus-bg border border-nexus-border rounded-lg flex justify-between items-start"
              >
                <div>
                  <h4 className="font-semibold text-nexus-text">{notif.title}</h4>
                  <p className="text-sm text-nexus-text-secondary">{notif.message}</p>
                  <div className="flex gap-2 mt-2">
                    <Badge variant="primary">{notif.target}</Badge>
                    <Badge variant="secondary">
                      {new Date(notif.sent_at).toLocaleDateString('pt-BR')}
                    </Badge>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </Section>

      <Modal
        isOpen={isModalOpen}
        title="Nova Notificação"
        size="lg"
        onClose={() => setIsModalOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setIsModalOpen(false)}>
              Cancelar
            </Button>
            <Button variant="primary" onClick={handleSendNotification}>
              Enviar
            </Button>
          </>
        }
      >
        <div className="space-y-6">
          <Input
            label="Título"
            value={formData.title}
            onChange={(e) => setFormData({ ...formData, title: e.target.value })}
            placeholder="Título da notificação"
            required
          />

          <Textarea
            label="Mensagem"
            value={formData.message}
            onChange={(e) => setFormData({ ...formData, message: e.target.value })}
            placeholder="Conteúdo da notificação"
            required
          />

          <Select
            label="Enviar para"
            value={formData.target}
            onChange={(e) => setFormData({ ...formData, target: e.target.value })}
            options={targetOptions}
          />

          <div className="flex items-center gap-3">
            <input
              type="checkbox"
              id="schedule"
              checked={formData.schedule}
              onChange={(e) => setFormData({ ...formData, schedule: e.target.checked })}
              className="w-4 h-4 rounded"
            />
            <label htmlFor="schedule" className="text-sm text-nexus-text">
              Agendar envio
            </label>
          </div>

          {formData.schedule && (
            <Input
              label="Data e Hora"
              type="datetime-local"
              value={formData.scheduledTime}
              onChange={(e) => setFormData({ ...formData, scheduledTime: e.target.value })}
              required
            />
          )}
        </div>
      </Modal>
    </Container>
  )
}

export default NotificationsPage
