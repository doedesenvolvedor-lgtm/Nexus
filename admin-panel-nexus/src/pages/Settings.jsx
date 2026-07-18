import React, { useState, useEffect } from 'react'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Input, Select, Textarea } from '../components/ui'
import { logsAPI, settingsAPI } from '../api/endpoints'
import { FiDownload, FiSave, FiRefreshCw } from 'react-icons/fi'

const SettingsPage = () => {
  const [loading, setLoading] = useState(false)
  const [settings, setSettings] = useState({
    platformName: 'Nexustwos',
    domain: 'https://nexustwos.com',
    emailFrom: 'noreply@nexustwos.com',
    smtpHost: '',
    smtpPort: '',
    smtpUser: '',
    smtpPassword: '',
    firebaseApiKey: '',
    tmdbApiKey: '',
    mercadopagoAccessToken: '',
  })

  useEffect(() => {
    fetchSettings()
  }, [])

  const fetchSettings = async () => {
    try {
      setLoading(true)
      const response = await settingsAPI.get()
      setSettings(response.data)
    } catch (error) {
      console.error('Erro ao carregar configurações:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSaveSettings = async () => {
    try {
      setLoading(true)
      await settingsAPI.update(settings)
      alert('Configurações salvas com sucesso!')
    } catch (error) {
      console.error('Erro ao salvar configurações:', error)
      alert('Erro ao salvar configurações')
    } finally {
      setLoading(false)
    }
  }

  const handleBackupDatabase = async () => {
    try {
      await settingsAPI.backupDatabase()
      alert('Backup criado com sucesso!')
    } catch (error) {
      console.error('Erro ao criar backup:', error)
    }
  }

  const handleTestEmail = async () => {
    try {
      await settingsAPI.testEmail(settings.emailFrom)
      alert('Email de teste enviado com sucesso!')
    } catch (error) {
      console.error('Erro ao enviar email:', error)
    }
  }

  return (
    <Container>
      <PageHeader
        title="⚙️ Configurações"
        subtitle="Configure todos os aspectos da plataforma"
      />

      {/* Basic Settings */}
      <Section title="🌐 Configurações Gerais" className="mb-6">
        <div className="space-y-6">
          <Input
            label="Nome da Plataforma"
            value={settings.platformName}
            onChange={(e) => setSettings({ ...settings, platformName: e.target.value })}
          />
          <Input
            label="Domínio"
            type="url"
            value={settings.domain}
            onChange={(e) => setSettings({ ...settings, domain: e.target.value })}
          />
        </div>
      </Section>

      {/* Email Settings */}
      <Section title="📧 Configurações de Email" className="mb-6">
        <div className="space-y-6">
          <Input
            label="Email Remetente"
            type="email"
            value={settings.emailFrom}
            onChange={(e) => setSettings({ ...settings, emailFrom: e.target.value })}
          />
          <Input
            label="Host SMTP"
            value={settings.smtpHost}
            onChange={(e) => setSettings({ ...settings, smtpHost: e.target.value })}
          />
          <Input
            label="Porta SMTP"
            type="number"
            value={settings.smtpPort}
            onChange={(e) => setSettings({ ...settings, smtpPort: e.target.value })}
          />
          <Input
            label="Usuário SMTP"
            value={settings.smtpUser}
            onChange={(e) => setSettings({ ...settings, smtpUser: e.target.value })}
          />
          <Input
            label="Senha SMTP"
            type="password"
            value={settings.smtpPassword}
            onChange={(e) => setSettings({ ...settings, smtpPassword: e.target.value })}
          />
          <Button
            variant="secondary"
            size="md"
            onClick={handleTestEmail}
            loading={loading}
          >
            Testar Email
          </Button>
        </div>
      </Section>

      {/* API Settings */}
      <Section title="🔑 Chaves de API" className="mb-6">
        <div className="space-y-6">
          <Input
            label="Firebase API Key"
            value={settings.firebaseApiKey}
            onChange={(e) => setSettings({ ...settings, firebaseApiKey: e.target.value })}
            type="password"
          />
          <Input
            label="TMDb API Key"
            value={settings.tmdbApiKey}
            onChange={(e) => setSettings({ ...settings, tmdbApiKey: e.target.value })}
            type="password"
          />
          <Input
            label="Mercado Pago Access Token"
            value={settings.mercadopagoAccessToken}
            onChange={(e) => setSettings({ ...settings, mercadopagoAccessToken: e.target.value })}
            type="password"
          />
        </div>
      </Section>

      {/* Backup & Security */}
      <Section title="💾 Backup e Segurança" className="mb-6">
        <div className="space-y-4">
          <Button
            variant="primary"
            size="lg"
            icon={FiRefreshCw}
            onClick={handleBackupDatabase}
            loading={loading}
          >
            Criar Backup do Banco de Dados
          </Button>
          <Button variant="secondary" size="lg" icon={FiDownload}>
            Baixar Últimos Backups
          </Button>
        </div>
      </Section>

      {/* Save Button */}
      <div className="flex justify-end gap-3">
        <Button variant="ghost" onClick={fetchSettings}>
          Cancelar
        </Button>
        <Button
          variant="primary"
          size="lg"
          icon={FiSave}
          onClick={handleSaveSettings}
          loading={loading}
        >
          Salvar Configurações
        </Button>
      </div>
    </Container>
  )
}

export default SettingsPage
