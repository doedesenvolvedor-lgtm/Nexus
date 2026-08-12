import axios from 'axios'

// ============================================================
// SEGURANÇA: ARMAZENAMENTO DE TOKEN
// ------------------------------------------------------------
// ATENÇÃO: O token JWT é armazenado em localStorage, o que o
// expõe a ataques XSS. É uma mitigação aceitável para SPA sem
// SSR, mas a opção RECOMENDADA para produção é:
//
//   1. Backend: emitir token em cookie httpOnly + Secure + SameSite
//      (não acessível via JavaScript - imune a XSS)
//   2. Frontend: remover este interceptor e deixar o navegador
//      enviar o cookie automaticamente
//   3. Implementar rotação de CSRF token (double-submit cookie)
//
// Migração completa: ver AUDITORIA_NOVEMBRO_2026.md (Fase 3)
// ============================================================

const API_BASE_URL =
  import.meta.env.VITE_API_URL ||
  import.meta.env.REACT_APP_API_URL ||
  'http://localhost:8000'

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Interceptor para adicionar token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => Promise.reject(error)
)

// Interceptor para tratamento de erros
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token')
      localStorage.removeItem('auth-storage')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export default api
