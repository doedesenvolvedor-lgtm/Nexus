import React, { useState, useEffect } from 'react'
import { FiShield, FiPlus, FiTrash2, FiLock, FiUnlock } from 'react-icons/fi'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Card, Input, Select, Modal, Badge, Alert, EmptyState, Loading } from '../components/ui'
import { parentalControlAPI } from '../api/endpoints'

const RATING_OPTIONS = [
  { label: 'Livre', value: 'LIVRE' },
  { label: '10+', value: '10' },
  { label: '12+', value: '12' },
  { label: '14+', value: '14' },
  { label: '16+', value: '16' },
  { label: '18+', value: '18' },
]

const CONTENT_TYPES = [
  { label: 'Mídia (Filme/Série)', value: 'media' },
  { label: 'Canal de TV', value: 'channel' },
  { label: 'Categoria', value: 'category' },
]

const ParentalControlPage = () => {
  const [stats, setStats] = useState(null)
  const [ratings, setRatings] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [formData, setFormData] = useState({
    content_type: 'media',
    content_id: '',
    category: '',
    rating: '18',
    is_adult: false,
  })

  useEffect(() => {
    fetchAll()
  }, [])

  const fetchAll = async () => {
    try {
      setLoading(true)
      setError(null)
      const [statsRes, ratingsRes] = await Promise.all([
        parentalControlAPI.getStats(),
        parentalControlAPI.listContentRatings(),
      ])
      setStats(statsRes.data)
      setRatings(ratingsRes.data || [])
    } catch (err) {
      console.error('Erro ao carregar controle parental:', err)
      setError('Não foi possível carregar os dados do Controle Parental.')
    } finally {
      setLoading(false)
    }
  }

  const handleCreateRating = async () => {
    try {
      if (!formData.content_id && formData.content_type !== 'category') {
        setError('Informe o ID do conteúdo.')
        return
      }
      if (!formData.category && formData.content_type === 'category') {
        setError('Informe a categoria.')
        return
      }
      await parentalControlAPI.setContentRating(formData)
      setIsModalOpen(false)
      setFormData({
        content_type: 'media',
        content_id: '',
        category: '',
        rating: '18',
        is_adult: false,
      })
      const ratingsRes = await parentalControlAPI.listContentRatings()
      setRatings(ratingsRes.data || [])
    } catch (err) {
      console.error('Erro ao salvar classificação:', err)
      setError('Erro ao salvar classificação. Verifique o ID informado.')
    }
  }

  const handleDeleteRating = async (id) => {
    try {
      await parentalControlAPI.deleteRating?.(id)
      setRatings(ratings.filter((r) => r.id !== id))
    } catch (err) {
      console.error('Erro ao excluir classificação:', err)
    }
  }

  if (loading) {
    return (
      <Container>
        <div className="flex justify-center py-20">
          <Loading />
        </div>
      </Container>
    )
  }

  return (
    <Container>
      <PageHeader
        title="🛡️ Controle Parental"
        subtitle="Regras globais de classificação, conteúdo +18 e estatísticas de bloqueio"
        breadcrumb={[
          { label: 'Dashboard', path: '/dashboard' },
          { label: 'Controle Parental', active: true },
        ]}
        actions={[
          <Button
            key="create"
            variant="primary"
            size="md"
            icon={FiPlus}
            onClick={() => setIsModalOpen(true)}
          >
            Nova Classificação
          </Button>,
        ]}
      />

      {error && (
        <Alert
          variant="error"
          title="Erro"
          message={error}
          onClose={() => setError(null)}
          className="mb-6"
        />
      )}

      {/* Stats Cards */}
      {stats && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          <Card variant="gradient">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-lg bg-nexus-primary/20 flex items-center justify-center">
                <FiShield size={24} className="text-nexus-primary" />
              </div>
<div>
                <p className="text-2xl font-bold text-nexus-text">{stats.total_attempts ?? 0}</p>
                <p className="text-sm text-nexus-text-secondary">Tentativas de acesso</p>
              </div>
            </div>
          </Card>
          <Card variant="gradient">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-lg bg-nexus-error/20 flex items-center justify-center">
                <FiLock size={24} className="text-nexus-error" />
              </div>
<div>
                <p className="text-2xl font-bold text-nexus-text">
                  {(stats.adult_media ?? 0) + (stats.adult_channels ?? 0)}
                </p>
                <p className="text-sm text-nexus-text-secondary">Conteúdo +18</p>
              </div>
            </div>
          </Card>
          <Card variant="gradient">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-lg bg-nexus-warning/20 flex items-center justify-center">
                <FiLock size={24} className="text-nexus-warning" />
              </div>
<div>
                <p className="text-2xl font-bold text-nexus-text">
                  {(stats.blocked?.pin ?? 0) + (stats.blocked?.rating ?? 0) + (stats.blocked?.time ?? 0) + (stats.blocked?.channel ?? 0)}
                </p>
                <p className="text-sm text-nexus-text-secondary">Tentativas bloqueadas</p>
              </div>
            </div>
          </Card>
          <Card variant="gradient">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-lg bg-nexus-success/20 flex items-center justify-center">
                <FiUnlock size={24} className="text-nexus-success" />
              </div>
<div>
                <p className="text-2xl font-bold text-nexus-text">{stats.granted ?? 0}</p>
                <p className="text-sm text-nexus-text-secondary">Acessos liberados</p>
              </div>
            </div>
          </Card>
        </div>
      )}

      {/* Content Ratings Table */}
      <Section
        title="Classificações de Conteúdo"
        subtitle="Defina classificação indicativa e marque conteúdos como +18"
        action={
          <Button variant="ghost" size="sm" onClick={fetchAll}>
            Atualizar
          </Button>
        }
      >
        {ratings.length === 0 ? (
          <EmptyState
            icon={FiShield}
            title="Nenhuma classificação cadastrada"
            message="Cadastre classificações para filmes, séries, canais e categorias."
          />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-nexus-border text-left text-nexus-text-secondary">
                  <th className="pb-3 pr-4 font-medium">Tipo</th>
                  <th className="pb-3 pr-4 font-medium">Conteúdo</th>
                  <th className="pb-3 pr-4 font-medium">Classificação</th>
                  <th className="pb-3 pr-4 font-medium">+18</th>
                  <th className="pb-3 font-medium">Ações</th>
                </tr>
              </thead>
              <tbody>
                {ratings.map((rating) => (
                  <tr key={rating.id} className="border-b border-nexus-border/50 last:border-0">
                    <td className="py-3 pr-4">
                      <Badge variant="secondary">{rating.content_type}</Badge>
                    </td>
                    <td className="py-3 pr-4 text-nexus-text">
                      {rating.content_id || rating.category || '—'}
                    </td>
                    <td className="py-3 pr-4">
                      <Badge variant={rating.is_adult ? 'error' : 'primary'}>
                        {rating.rating === '18' || rating.is_adult ? '18+' : `${rating.rating}+`}
                      </Badge>
                    </td>
                    <td className="py-3 pr-4">
                      {rating.is_adult ? (
                        <Badge variant="error">Bloqueado</Badge>
                      ) : (
                        <Badge variant="success">Liberado</Badge>
                      )}
                    </td>
                    <td className="py-3">
                      <button
                        onClick={() => handleDeleteRating(rating.id)}
                        className="p-2 text-nexus-error hover:bg-nexus-error/10 rounded-lg transition-smooth"
                        title="Excluir"
                      >
                        <FiTrash2 size={18} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Section>

      {/* Modal */}
      <Modal
        isOpen={isModalOpen}
        title="Nova Classificação"
        size="lg"
        onClose={() => setIsModalOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setIsModalOpen(false)}>
              Cancelar
            </Button>
            <Button variant="primary" onClick={handleCreateRating}>
              Salvar
            </Button>
          </>
        }
      >
        <div className="space-y-6">
          <Select
            label="Tipo de Conteúdo"
            value={formData.content_type}
            onChange={(e) => setFormData({ ...formData, content_type: e.target.value })}
            options={CONTENT_TYPES}
            required
          />

          {formData.content_type !== 'category' ? (
            <Input
              label="ID do Conteúdo"
              value={formData.content_id}
              onChange={(e) => setFormData({ ...formData, content_id: e.target.value })}
              placeholder="UUID do filme/série/canal"
              required
            />
          ) : (
            <Input
              label="Categoria"
              value={formData.category}
              onChange={(e) => setFormData({ ...formData, category: e.target.value })}
              placeholder="Ex: Filmes, Esportes, Notícias, Adulto"
              required
            />
          )}

          <div className="grid grid-cols-2 gap-4">
            <Select
              label="Classificação Indicativa"
              value={formData.rating}
              onChange={(e) => setFormData({ ...formData, rating: e.target.value })}
              options={RATING_OPTIONS}
              required
            />
            <div className="flex items-end">
              <label className="flex items-center gap-3 p-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={formData.is_adult}
                  onChange={(e) => setFormData({ ...formData, is_adult: e.target.checked })}
                  className="w-4 h-4 accent-purple-600"
                />
                <span className="text-sm font-medium text-nexus-text">Marcar como +18</span>
              </label>
            </div>
          </div>

          {formData.is_adult && (
            <Alert
              variant="warning"
              title="Atenção"
              message="Conteúdo +18 ficará oculto por padrão e exigirá PIN do Controle Parental para acesso."
            />
          )}
        </div>
      </Modal>
    </Container>
  )
}

export default ParentalControlPage

