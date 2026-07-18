import React from 'react'
import { useNavigate } from 'react-router-dom'
import { Button } from '../components/ui'

const NotFoundPage = () => {
  const navigate = useNavigate()

  return (
    <div className="min-h-screen bg-nexus-bg flex items-center justify-center">
      <div className="text-center">
        <h1 className="text-9xl font-bold gradient-text mb-4">404</h1>
        <h2 className="text-3xl font-bold text-nexus-text mb-2">Página não encontrada</h2>
        <p className="text-nexus-text-secondary mb-8">
          Desculpe, a página que você está procurando não existe.
        </p>
        <Button
          variant="primary"
          size="lg"
          onClick={() => navigate('/dashboard')}
        >
          Voltar ao Dashboard
        </Button>
      </div>
    </div>
  )
}

export default NotFoundPage
