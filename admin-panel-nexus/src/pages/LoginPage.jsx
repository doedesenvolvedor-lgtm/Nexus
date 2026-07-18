import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { Button, Input } from '../components/ui'
import { authAPI } from '../api/endpoints'

const LoginPage = () => {
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const [formData, setFormData] = useState({
    email: '',
    password: '',
  })

  const handleChange = (e) => {
    const { name, value } = e.target
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError(null)
    setLoading(true)

    try {
      const response = await authAPI.login(formData.email, formData.password)
      localStorage.setItem('token', response.data.access_token)
      navigate('/dashboard')
    } catch (err) {
      setError(err.response?.data?.message || 'Erro ao fazer login')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-nexus-bg via-purple-900/20 to-nexus-bg flex items-center justify-center p-4">
      {/* Background Elements */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-10 left-10 w-72 h-72 bg-nexus-primary/10 rounded-full blur-3xl"></div>
        <div className="absolute bottom-10 right-10 w-72 h-72 bg-nexus-secondary/10 rounded-full blur-3xl"></div>
      </div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="relative z-10 w-full max-w-md"
      >
        {/* Logo */}
        <div className="text-center mb-8">
          <motion.h1
            className="text-5xl font-bold gradient-text mb-2"
            animate={{ scale: [1, 1.05, 1] }}
            transition={{ duration: 2, repeat: Infinity }}
          >
            Nexustwos
          </motion.h1>
          <p className="text-nexus-text-secondary">Admin Panel</p>
        </div>

        {/* Login Card */}
        <motion.div
          className="bg-nexus-card/80 backdrop-blur border border-nexus-border rounded-2xl p-8 shadow-2xl"
          whileHover={{ scale: 1.02 }}
          transition={{ duration: 0.3 }}
        >
          <h2 className="text-2xl font-bold text-nexus-text mb-6">Bem-vindo</h2>

          {error && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="mb-6 p-4 bg-nexus-error/20 border border-nexus-error/50 rounded-lg text-nexus-error text-sm"
            >
              {error}
            </motion.div>
          )}

          <form onSubmit={handleSubmit} className="space-y-6">
            <Input
              label="Email"
              name="email"
              type="email"
              value={formData.email}
              onChange={handleChange}
              placeholder="seu@email.com"
              required
            />

            <Input
              label="Senha"
              name="password"
              type="password"
              value={formData.password}
              onChange={handleChange}
              placeholder="••••••••"
              required
            />

            <Button
              variant="primary"
              size="lg"
              type="submit"
              loading={loading}
              className="w-full"
            >
              Entrar
            </Button>
          </form>

          {/* Demo Credentials */}
          <div className="mt-6 p-4 bg-nexus-bg rounded-lg border border-nexus-border/50">
            <p className="text-xs text-nexus-text-secondary mb-2">
              📝 Credenciais de Demo:
            </p>
            <p className="text-xs text-nexus-text font-mono mb-1">
              Email: admin@nexus.com
            </p>
            <p className="text-xs text-nexus-text font-mono">
              Senha: admin123456
            </p>
          </div>
        </motion.div>

        {/* Footer */}
        <p className="text-center text-nexus-text-secondary text-xs mt-8">
          © 2026 Nexustwos. Todos os direitos reservados.
        </p>
      </motion.div>
    </div>
  )
}

export default LoginPage
