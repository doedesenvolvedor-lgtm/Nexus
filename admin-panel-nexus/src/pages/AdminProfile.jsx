import React, { useState } from 'react'
import { FiEdit, FiLock, FiLogOut } from 'react-icons/fi'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Input, Select, Modal } from '../components/ui'
import toast from 'react-hot-toast'

const AdminProfilePage = () => {
  const [isEditMode, setIsEditMode] = useState(false)
  const [isPasswordModalOpen, setIsPasswordModalOpen] = useState(false)
  const [formData, setFormData] = useState({
    name: 'Administrador Nexus',
    email: 'admin@nexus.com',
    phone: '+55 (11) 98765-4321',
    department: 'Administração',
    language: 'pt-BR',
    theme: 'dark',
    notifications: true,
  })

  const [passwords, setPasswords] = useState({
    current: '',
    new: '',
    confirm: '',
  })

  const handleSaveProfile = async () => {
    try {
      toast.success('Perfil atualizado com sucesso!')
      setIsEditMode(false)
    } catch (error) {
      toast.error('Erro ao atualizar perfil')
    }
  }

  const handleChangePassword = async () => {
    if (passwords.new !== passwords.confirm) {
      toast.error('As senhas não coincidem')
      return
    }

    if (passwords.new.length < 8) {
      toast.error('A senha deve ter no mínimo 8 caracteres')
      return
    }

    try {
      toast.success('Senha alterada com sucesso!')
      setPasswords({ current: '', new: '', confirm: '' })
      setIsPasswordModalOpen(false)
    } catch (error) {
      toast.error('Erro ao alterar senha')
    }
  }

  const handleLogout = () => {
    if (window.confirm('Deseja sair da conta?')) {
      localStorage.removeItem('token')
      window.location.href = '/login'
    }
  }

  return (
    <Container>
      <PageHeader
        title="👤 Meu Perfil"
        subtitle="Gerencie suas informações de administrador"
        actions={[
          <Button
            key="logout"
            variant="danger"
            size="md"
            icon={FiLogOut}
            onClick={handleLogout}
          >
            Sair
          </Button>,
        ]}
      />

      {/* Seção Principal de Perfil */}
      <Section className="mb-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
          {/* Avatar */}
          <div className="md:col-span-1 flex flex-col items-center">
            <div className="w-32 h-32 bg-gradient-to-br from-nexus-primary to-nexus-secondary rounded-full flex items-center justify-center mb-4">
              <span className="text-6xl">👤</span>
            </div>
            <h2 className="text-2xl font-bold text-nexus-text">{formData.name}</h2>
            <p className="text-nexus-text-secondary text-sm mt-1">{formData.email}</p>
            <Button
              variant="secondary"
              size="sm"
              className="mt-4"
            >
              Alterar Avatar
            </Button>
          </div>

          {/* Informações */}
          <div className="md:col-span-2 bg-nexus-card border border-nexus-card rounded-xl p-6">
            {isEditMode ? (
              <div className="space-y-4">
                <Input
                  label="Nome Completo"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                />

                <Input
                  label="Email"
                  type="email"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                />

                <Input
                  label="Telefone"
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                />

                <Input
                  label="Departamento"
                  value={formData.department}
                  onChange={(e) => setFormData({ ...formData, department: e.target.value })}
                />

                <div className="flex gap-2 justify-end">
                  <Button
                    variant="ghost"
                    onClick={() => setIsEditMode(false)}
                  >
                    Cancelar
                  </Button>
                  <Button
                    variant="primary"
                    onClick={handleSaveProfile}
                  >
                    Salvar
                  </Button>
                </div>
              </div>
            ) : (
              <div className="space-y-4">
                <div>
                  <p className="text-xs font-semibold text-nexus-text-secondary mb-1">Nome Completo</p>
                  <p className="text-nexus-text">{formData.name}</p>
                </div>

                <div>
                  <p className="text-xs font-semibold text-nexus-text-secondary mb-1">Email</p>
                  <p className="text-nexus-text">{formData.email}</p>
                </div>

                <div>
                  <p className="text-xs font-semibold text-nexus-text-secondary mb-1">Telefone</p>
                  <p className="text-nexus-text">{formData.phone}</p>
                </div>

                <div>
                  <p className="text-xs font-semibold text-nexus-text-secondary mb-1">Departamento</p>
                  <p className="text-nexus-text">{formData.department}</p>
                </div>

                <Button
                  variant="secondary"
                  icon={FiEdit}
                  onClick={() => setIsEditMode(true)}
                  fullWidth
                >
                  Editar Informações
                </Button>
              </div>
            )}
          </div>
        </div>
      </Section>

      {/* Preferências */}
      <Section className="mb-6">
        <h2 className="text-xl font-bold text-nexus-text mb-6">⚙️ Preferências</h2>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="bg-nexus-card border border-nexus-card rounded-xl p-6">
            <h3 className="text-lg font-bold text-nexus-text mb-4">Idioma e Tema</h3>
            <div className="space-y-4">
              <Select
                label="Idioma"
                value={formData.language}
                onChange={(e) => setFormData({ ...formData, language: e.target.value })}
                options={[
                  { label: 'Português (Brasil)', value: 'pt-BR' },
                  { label: 'English (US)', value: 'en-US' },
                  { label: 'Español (España)', value: 'es-ES' },
                ]}
              />

              <Select
                label="Tema"
                value={formData.theme}
                onChange={(e) => setFormData({ ...formData, theme: e.target.value })}
                options={[
                  { label: 'Escuro (Padrão)', value: 'dark' },
                  { label: 'Claro', value: 'light' },
                  { label: 'Sistema', value: 'system' },
                ]}
              />
            </div>
          </div>

          <div className="bg-nexus-card border border-nexus-card rounded-xl p-6">
            <h3 className="text-lg font-bold text-nexus-text mb-4">Notificações</h3>
            <div className="space-y-3">
              <label className="flex items-center gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  checked={formData.notifications}
                  onChange={(e) => setFormData({ ...formData, notifications: e.target.checked })}
                  className="w-4 h-4"
                />
                <span className="text-sm text-nexus-text">Receber notificações de sistema</span>
              </label>
              <label className="flex items-center gap-3 cursor-pointer">
                <input type="checkbox" defaultChecked className="w-4 h-4" />
                <span className="text-sm text-nexus-text">Email com relatórios diários</span>
              </label>
              <label className="flex items-center gap-3 cursor-pointer">
                <input type="checkbox" defaultChecked className="w-4 h-4" />
                <span className="text-sm text-nexus-text">Alertas de erro crítico</span>
              </label>
            </div>
          </div>
        </div>
      </Section>

      {/* Segurança */}
      <Section>
        <h2 className="text-xl font-bold text-nexus-text mb-6">🔒 Segurança</h2>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="bg-nexus-card border border-nexus-card rounded-xl p-6">
            <h3 className="text-lg font-bold text-nexus-text mb-4">Senha</h3>
            <p className="text-sm text-nexus-text-secondary mb-4">
              Altere sua senha regularmente para manter sua conta segura.
            </p>
            <Button
              variant="danger"
              icon={FiLock}
              fullWidth
              onClick={() => setIsPasswordModalOpen(true)}
            >
              Alterar Senha
            </Button>
          </div>

          <div className="bg-nexus-card border border-nexus-card rounded-xl p-6">
            <h3 className="text-lg font-bold text-nexus-text mb-4">Sessões Ativas</h3>
            <div className="space-y-2 mb-4">
              <div className="text-sm">
                <p className="font-semibold text-nexus-text">Navegador: Chrome</p>
                <p className="text-xs text-nexus-text-secondary">IP: 192.168.1.1 • Agora</p>
              </div>
            </div>
            <Button
              variant="secondary"
              fullWidth
              size="sm"
            >
              Gerenciar Sessões
            </Button>
          </div>
        </div>
      </Section>

      {/* Modal de Alterar Senha */}
      <Modal
        isOpen={isPasswordModalOpen}
        title="Alterar Senha"
        size="md"
        onClose={() => setIsPasswordModalOpen(false)}
        footer={
          <>
            <Button
              variant="ghost"
              onClick={() => setIsPasswordModalOpen(false)}
            >
              Cancelar
            </Button>
            <Button
              variant="primary"
              onClick={handleChangePassword}
            >
              Alterar Senha
            </Button>
          </>
        }
      >
        <div className="space-y-4">
          <Input
            label="Senha Atual"
            type="password"
            value={passwords.current}
            onChange={(e) => setPasswords({ ...passwords, current: e.target.value })}
            placeholder="Digite sua senha atual"
            required
          />

          <Input
            label="Nova Senha"
            type="password"
            value={passwords.new}
            onChange={(e) => setPasswords({ ...passwords, new: e.target.value })}
            placeholder="Digite a nova senha"
            required
          />

          <Input
            label="Confirmar Senha"
            type="password"
            value={passwords.confirm}
            onChange={(e) => setPasswords({ ...passwords, confirm: e.target.value })}
            placeholder="Confirme a nova senha"
            required
          />

          <p className="text-xs text-nexus-text-secondary">
            A senha deve ter no mínimo 8 caracteres.
          </p>
        </div>
      </Modal>
    </Container>
  )
}

export default AdminProfilePage
