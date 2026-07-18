import React from 'react'
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { Sidebar } from './components/Layout/Sidebar'
import { Header } from './components/Layout/Header'
import { NotificationContainer } from './components/Notification'

// Pages
import Dashboard from './pages/Dashboard'
import LoginPage from './pages/LoginPage'
import NotFoundPage from './pages/NotFoundPage'
import MoviesPage from './pages/Movies'
import UsersPage from './pages/Users'
import SubscriptionsPage from './pages/Subscriptions'
import TrialsPage from './pages/Trials'
import PaymentsPage from './pages/Payments'
import AnalyticsPage from './pages/Analytics'
import NotificationsPage from './pages/Notifications'
import SettingsPage from './pages/Settings'

// Placeholder Pages
const PlaceholderPage = ({ title }) => (
  <div className="flex items-center justify-center min-h-[400px]">
    <div className="text-center">
      <h1 className="text-4xl font-bold text-nexus-primary mb-4">{title}</h1>
      <p className="text-nexus-text-secondary">Esta página será implementada em breve.</p>
    </div>
  </div>
)

function App() {
  const isAuthenticated = !!localStorage.getItem('token')

  return (
    <Router>
      <NotificationContainer />
      
      <Routes>
        {/* Public Routes */}
        <Route path="/login" element={<LoginPage />} />

        {/* Protected Routes */}
        <Route
          path="/*"
          element={
            isAuthenticated ? (
              <div className="flex bg-nexus-bg text-nexus-text min-h-screen">
                <Sidebar />
                <div className="flex-1 flex flex-col">
                  <Header title="Dashboard" subtitle="Bem-vindo ao Painel Administrativo Nexustwos" />
                  <main className="flex-1 overflow-y-auto bg-nexus-bg">
                    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                      <Routes>
                        {/* Dashboard */}
                        <Route path="/dashboard" element={<Dashboard />} />

                        {/* Movies */}
                        <Route path="/movies" element={<MoviesPage />} />
                        <Route path="/movies/new" element={<MoviesPage />} />
                        <Route path="/movies/:id" element={<MoviesPage />} />

                        {/* Series */}
                        <Route path="/series" element={<PlaceholderPage title="📺 Séries" />} />
                        <Route path="/series/new" element={<PlaceholderPage title="Nova Série" />} />
                        <Route path="/series/:id" element={<PlaceholderPage title="Editar Série" />} />

                        {/* Episodes */}
                        <Route path="/episodes" element={<PlaceholderPage title="⏱️ Episódios" />} />

                        {/* Channels */}
                        <Route path="/channels" element={<PlaceholderPage title="📡 Canais ao Vivo" />} />

                        {/* Categories */}
                        <Route path="/categories" element={<PlaceholderPage title="🎯 Categorias" />} />

                        {/* Banners */}
                        <Route path="/banners" element={<PlaceholderPage title="🖼️ Banners" />} />

                        {/* Users */}
                        <Route path="/users" element={<UsersPage />} />
                        <Route path="/profiles" element={<PlaceholderPage title="👤 Perfis" />} />
                        <Route path="/trials" element={<TrialsPage />} />

                        {/* Subscriptions */}
                        <Route path="/plans" element={<PlaceholderPage title="💳 Planos" />} />
                        <Route path="/subscriptions" element={<SubscriptionsPage />} />
                        <Route path="/payments" element={<PaymentsPage />} />
                        <Route path="/coupons" element={<PlaceholderPage title="🎁 Cupons" />} />

                        {/* Tools */}
                        <Route path="/importer" element={<PlaceholderPage title="📥 Importador M3U" />} />
                        <Route path="/tmdb" element={<PlaceholderPage title="🎬 TMDb Integration" />} />

                        {/* Other */}
                        <Route path="/notifications" element={<NotificationsPage />} />
                        <Route path="/comments" element={<PlaceholderPage title="💬 Comentários" />} />
                        <Route path="/analytics" element={<AnalyticsPage />} />
                        <Route path="/logs" element={<PlaceholderPage title="📋 Logs" />} />
                        <Route path="/settings" element={<SettingsPage />} />
                        <Route path="/profile" element={<PlaceholderPage title="👤 Perfil Admin" />} />

                        {/* Default Redirect */}
                        <Route path="/" element={<Navigate to="/dashboard" replace />} />
                        <Route path="*" element={<NotFoundPage />} />
                      </Routes>
                    </div>
                  </main>
                </div>
              </div>
            ) : (
              <Navigate to="/login" replace />
            )
          }
        />
      </Routes>
    </Router>
  )
}

export default App
