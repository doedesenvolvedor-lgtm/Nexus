import React, { useState, useEffect } from 'react'
import { FiTrash2, FiCheck, FiX } from 'react-icons/fi'
import { PageHeader, Container, Section } from '../components/Layout/Header'
import { Button, Modal, Badge } from '../components/ui'
import { Table } from '../components/Table'
import toast from 'react-hot-toast'

const CommentsPage = () => {
  const [comments, setComments] = useState([])
  const [loading, setLoading] = useState(false)
  const [selectedComment, setSelectedComment] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)

  useEffect(() => {
    fetchComments()
  }, [])

  const fetchComments = async () => {
    try {
      setLoading(true)
      setComments([
        {
          id: 1,
          author: 'João Silva',
          email: 'joao@email.com',
          content: 'Adorei este filme, muito bom mesmo!',
          contentTitle: 'Breaking Bad',
          status: 'pendente',
          date: '2024-01-15 10:30',
          rating: 5,
        },
        {
          id: 2,
          author: 'Maria Santos',
          email: 'maria@email.com',
          content: 'A série é excelente, recomendo muito.',
          contentTitle: 'The Crown',
          status: 'aprovado',
          date: '2024-01-14 15:45',
          rating: 5,
        },
        {
          id: 3,
          author: 'Pedro Costa',
          email: 'pedro@email.com',
          content: 'Não gostei, muito lento.',
          contentTitle: 'Breaking Bad',
          status: 'pendente',
          date: '2024-01-13 08:20',
          rating: 2,
        },
      ])
    } catch (error) {
      console.error('Erro ao carregar comentários:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleApprove = async (comment) => {
    try {
      setComments(comments.map(c =>
        c.id === comment.id ? { ...c, status: 'aprovado' } : c
      ))
      toast.success('Comentário aprovado!')
    } catch (error) {
      toast.error('Erro ao aprovar comentário')
    }
  }

  const handleReject = async (comment) => {
    try {
      setComments(comments.map(c =>
        c.id === comment.id ? { ...c, status: 'rejeitado' } : c
      ))
      toast.success('Comentário rejeitado!')
    } catch (error) {
      toast.error('Erro ao rejeitar comentário')
    }
  }

  const handleDelete = async (comment) => {
    if (window.confirm('Deseja deletar este comentário?')) {
      try {
        setComments(comments.filter(c => c.id !== comment.id))
        toast.success('Comentário deletado!')
      } catch (error) {
        toast.error('Erro ao deletar comentário')
      }
    }
  }

  const columns = [
    {
      key: 'author',
      label: 'Autor',
      sortable: true,
      render: (value) => <span className="font-medium">{value}</span>,
    },
    {
      key: 'contentTitle',
      label: 'Conteúdo',
      render: (value) => <span className="text-sm">{value}</span>,
    },
    {
      key: 'rating',
      label: 'Avaliação',
      render: (value) => <span className="text-lg">{'⭐'.repeat(value)}</span>,
    },
    {
      key: 'status',
      label: 'Status',
      render: (value) => (
        <Badge
          variant={
            value === 'aprovado' ? 'success' : value === 'rejeitado' ? 'error' : 'warning'
          }
        >
          {value === 'aprovado' ? '✓ Aprovado' : value === 'rejeitado' ? '✗ Rejeitado' : '⏳ Pendente'}
        </Badge>
      ),
    },
    {
      key: 'date',
      label: 'Data',
    },
  ]

  const actions = [
    {
      label: 'Visualizar',
      onClick: (comment) => {
        setSelectedComment(comment)
        setIsModalOpen(true)
      },
    },
    {
      label: 'Aprovar',
      icon: FiCheck,
      variant: 'success',
      onClick: (comment) => handleApprove(comment),
      hidden: (comment) => comment.status !== 'pendente',
    },
    {
      label: 'Rejeitar',
      icon: FiX,
      variant: 'warning',
      onClick: (comment) => handleReject(comment),
      hidden: (comment) => comment.status !== 'pendente',
    },
    {
      label: 'Deletar',
      icon: FiTrash2,
      variant: 'danger',
      onClick: (comment) => handleDelete(comment),
    },
  ]

  return (
    <Container>
      <PageHeader
        title="💬 Comentários"
        subtitle="Modere os comentários dos usuários"
      />

      <Section>
        <Table
          columns={columns}
          data={comments}
          loading={loading}
          actions={actions}
          paginated={true}
          pageSize={10}
        />
      </Section>

      {/* Modal de Detalhes */}
      <Modal
        isOpen={isModalOpen}
        title={`Comentário de ${selectedComment?.author}`}
        size="lg"
        onClose={() => setIsModalOpen(false)}
        footer={
          <>
            {selectedComment?.status === 'pendente' && (
              <>
                <Button
                  variant="success"
                  icon={FiCheck}
                  onClick={() => {
                    handleApprove(selectedComment)
                    setIsModalOpen(false)
                  }}
                >
                  Aprovar
                </Button>
                <Button
                  variant="error"
                  icon={FiX}
                  onClick={() => {
                    handleReject(selectedComment)
                    setIsModalOpen(false)
                  }}
                >
                  Rejeitar
                </Button>
              </>
            )}
            <Button
              variant="ghost"
              onClick={() => setIsModalOpen(false)}
            >
              Fechar
            </Button>
          </>
        }
      >
        <div className="space-y-6">
          <div className="bg-nexus-card rounded-lg p-4">
            <div className="flex justify-between items-start mb-4">
              <div>
                <p className="font-semibold text-nexus-text">{selectedComment?.author}</p>
                <p className="text-sm text-nexus-text-secondary">{selectedComment?.email}</p>
              </div>
              <Badge
                variant={
                  selectedComment?.status === 'aprovado'
                    ? 'success'
                    : selectedComment?.status === 'rejeitado'
                    ? 'error'
                    : 'warning'
                }
              >
                {selectedComment?.status === 'aprovado'
                  ? '✓ Aprovado'
                  : selectedComment?.status === 'rejeitado'
                  ? '✗ Rejeitado'
                  : '⏳ Pendente'}
              </Badge>
            </div>

            <p className="text-sm text-nexus-text-secondary mb-3">
              Conteúdo: <span className="font-semibold text-nexus-text">{selectedComment?.contentTitle}</span>
            </p>

            <p className="text-sm text-nexus-text-secondary mb-3">
              Data: {selectedComment?.date}
            </p>

            <div className="flex items-center gap-1 mb-4">
              {[...Array(5)].map((_, i) => (
                <span key={i} className="text-lg">
                  {i < selectedComment?.rating ? '⭐' : '☆'}
                </span>
              ))}
            </div>
          </div>

          <div>
            <p className="text-sm font-semibold text-nexus-text mb-3">Comentário:</p>
            <div className="bg-nexus-card border border-nexus-card rounded-lg p-4">
              <p className="text-nexus-text whitespace-pre-wrap">{selectedComment?.content}</p>
            </div>
          </div>
        </div>
      </Modal>
    </Container>
  )
}

export default CommentsPage
