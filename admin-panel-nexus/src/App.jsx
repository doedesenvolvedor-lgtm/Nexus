import React from 'react'
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { Sidebar } from './components/Layout/Sidebar'
import { Header } from './components/Layout/Header'
import { NotificationContainer } from './components/Notification'

// Pages - Core
import Dashboard from './pages/Dashboard'
import LoginPage from './pages/LoginPage'
import NotFoundPage from './pages/NotFoundPage'

// Pages - Content Management
import MoviesPage from './pages/Movies'
import SeriesPage from './pages/Series'
import EpisodesPage from './pages/Episodes'
import ChannelsPage from './pages/Channels'
import CategoriesPage from './pages/Categories'
import BannersPage from './pages/Banners'

// Pages - Users & Subscriptions
import UsersPage from './pages/Users'
import ProfilesPage from './pages/Profiles'
import SubscriptionsPage from './pages/Subscriptions'
import TrialsPage from './pages/Trials'
import PlansPage from './pages/Plans'

// Pages - Financial
import PaymentsPage from './pages/Payments'
import CouponsPage from './pages/Coupons'

// Pages - Tools & Integration
import M3UImporterPage from './pages/M3UImporter'
import TMDbIntegrationPage from './pages/TMDbIntegration'

// Pages - Monitoring & Admin
import NotificationsPage from './pages/Notifications'
import CommentsPage from './pages/Comments'
import LogsPage from './pages/Logs'
import AnalyticsPage from './pages/Analytics'
import SettingsPage from './pages/Settings'
import AdminProfilePage from './pages/AdminProfile'

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

                        {/* Content Management */}
                        <Route path="/movies" element={<MoviesPage />} />
                        <Route path="/movies/new" element={<MoviesPage />} />
                        <Route path="/movies/:id" element={<MoviesPage />} />

                        <Route path="/series" element={<SeriesPage />} />
                        <Route path="/series/new" element={<SeriesPage />} />
                        <Route path="/series/:id" element={<SeriesPage />} />

                        <Route path="/episodes" element={<EpisodesPage />} />
                        <Route path="/channels" element={<ChannelsPage />} />
                        <Route path="/categories" element={<CategoriesPage />} />
                        <Route path="/banners" element={<BannersPage />} />

                        {/* Users & Subscriptions */}
                        <Route path="/users" element={<UsersPage />} />
                        <Route path="/profiles" element={<ProfilesPage />} />
                        <Route path="/trials" element={<TrialsPage />} />
                        <Route path="/plans" element={<PlansPage />} />
                        <Route path="/subscriptions" element={<SubscriptionsPage />} />

                        {/* Financial */}
                        <Route path="/payments" element={<PaymentsPage />} />
                        <Route path="/coupons" element={<CouponsPage />} />

                        {/* Tools & Integration */}
                        <Route path="/importer" element={<M3UImporterPage />} />
                        <Route path="/tmdb" element={<TMDbIntegrationPage />} />

                        {/* Monitoring & Admin */}
                        <Route path="/notifications" element={<NotificationsPage />} />
                        <Route path="/comments" element={<CommentsPage />} />
                        <Route path="/analytics" element={<AnalyticsPage />} />
                        <Route path="/logs" element={<LogsPage />} />
                        <Route path="/settings" element={<SettingsPage />} />
                        <Route path="/profile" element={<AdminProfilePage />} />

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
