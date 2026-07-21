import React, { Suspense, lazy } from 'react'
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { Sidebar } from './components/Layout/Sidebar'
import { Header } from './components/Layout/Header'
import { NotificationContainer } from './components/Notification'

const Dashboard = lazy(() => import('./pages/Dashboard'))
const LoginPage = lazy(() => import('./pages/LoginPage'))
const NotFoundPage = lazy(() => import('./pages/NotFoundPage'))
const MoviesPage = lazy(() => import('./pages/Movies'))
const SeriesPage = lazy(() => import('./pages/Series'))
const EpisodesPage = lazy(() => import('./pages/Episodes'))
const ChannelsPage = lazy(() => import('./pages/Channels'))
const CategoriesPage = lazy(() => import('./pages/Categories'))
const BannersPage = lazy(() => import('./pages/Banners'))
const UsersPage = lazy(() => import('./pages/Users'))
const ProfilesPage = lazy(() => import('./pages/Profiles'))
const SubscriptionsPage = lazy(() => import('./pages/Subscriptions'))
const TrialsPage = lazy(() => import('./pages/Trials'))
const PlansPage = lazy(() => import('./pages/Plans'))
const PaymentsPage = lazy(() => import('./pages/Payments'))
const CouponsPage = lazy(() => import('./pages/Coupons'))
const M3UImporterPage = lazy(() => import('./pages/M3UImporter'))
const TMDbIntegrationPage = lazy(() => import('./pages/TMDbIntegration'))
const NotificationsPage = lazy(() => import('./pages/Notifications'))
const CommentsPage = lazy(() => import('./pages/Comments'))
const LogsPage = lazy(() => import('./pages/Logs'))
const AnalyticsPage = lazy(() => import('./pages/Analytics'))
const SettingsPage = lazy(() => import('./pages/Settings'))
const AdminProfilePage = lazy(() => import('./pages/AdminProfile'))

const PageLoader = () => (
  <div className="flex min-h-[40vh] items-center justify-center text-nexus-text-secondary">
    Carregando...
  </div>
)

function App() {
  const isAuthenticated = !!localStorage.getItem('token')

  return (
    <Router>
      <NotificationContainer />

      <Routes>
        <Route
          path="/login"
          element={
            <Suspense fallback={<PageLoader />}>
              <LoginPage />
            </Suspense>
          }
        />

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
                      <Suspense fallback={<PageLoader />}>
                        <Routes>
                          <Route path="/dashboard" element={<Dashboard />} />
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
                          <Route path="/users" element={<UsersPage />} />
                          <Route path="/profiles" element={<ProfilesPage />} />
                          <Route path="/trials" element={<TrialsPage />} />
                          <Route path="/plans" element={<PlansPage />} />
                          <Route path="/subscriptions" element={<SubscriptionsPage />} />
                          <Route path="/payments" element={<PaymentsPage />} />
                          <Route path="/coupons" element={<CouponsPage />} />
                          <Route path="/importer" element={<M3UImporterPage />} />
                          <Route path="/tmdb" element={<TMDbIntegrationPage />} />
                          <Route path="/notifications" element={<NotificationsPage />} />
                          <Route path="/comments" element={<CommentsPage />} />
                          <Route path="/analytics" element={<AnalyticsPage />} />
                          <Route path="/logs" element={<LogsPage />} />
                          <Route path="/settings" element={<SettingsPage />} />
                          <Route path="/profile" element={<AdminProfilePage />} />
                          <Route path="/" element={<Navigate to="/dashboard" replace />} />
                          <Route path="*" element={<NotFoundPage />} />
                        </Routes>
                      </Suspense>
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
