import React from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { useUIStore } from '../../store'
import {
  FiHome,
  FiFilm,
  FiTv,
  FiUsers,
  FiDollarSign,
  FiSettings,
  FiMenu,
  FiX,
  FiLogOut,
  FiUser,
  FiTrendingUp,
  FiMessageCircle,
  FiShare2,
  FiImage,
  FiFileText,
  FiBell,
  FiGift,
  FiLink2,
  FiGrid,
  FiClock,
} from 'react-icons/fi'

const menuItems = [
  {
    label: 'Dashboard',
    path: '/dashboard',
    icon: FiHome,
    badge: null,
  },
  {
    label: 'Conteúdo',
    icon: FiGrid,
    submenu: [
      { label: 'Filmes', path: '/movies', icon: FiFilm },
      { label: 'Séries', path: '/series', icon: FiTv },
      { label: 'Episódios', path: '/episodes', icon: FiClock },
      { label: 'Canais Ao Vivo', path: '/channels', icon: FiShare2 },
      { label: 'Categorias', path: '/categories', icon: FiGrid },
      { label: 'Banners', path: '/banners', icon: FiImage },
    ],
  },
  {
    label: 'Usuários',
    icon: FiUsers,
    submenu: [
      { label: 'Usuários', path: '/users', icon: FiUsers },
      { label: 'Perfis', path: '/profiles', icon: FiUser },
      { label: 'Trials', path: '/trials', icon: FiClock },
    ],
  },
  {
    label: 'Assinaturas',
    icon: FiDollarSign,
    submenu: [
      { label: 'Planos', path: '/plans', icon: FiDollarSign },
      { label: 'Assinaturas', path: '/subscriptions', icon: FiDollarSign },
      { label: 'Pagamentos', path: '/payments', icon: FiDollarSign },
      { label: 'Cupons', path: '/coupons', icon: FiGift },
    ],
  },
  {
    label: 'Ferramentas',
    icon: FiLink2,
    submenu: [
      { label: 'Importador M3U', path: '/importer', icon: FiLink2 },
      { label: 'TMDb Integration', path: '/tmdb', icon: FiTv },
    ],
  },
  {
    label: 'Notificações',
    path: '/notifications',
    icon: FiBell,
    badge: null,
  },
  {
    label: 'Comentários',
    path: '/comments',
    icon: FiMessageCircle,
  },
  {
    label: 'Analytics',
    path: '/analytics',
    icon: FiTrendingUp,
  },
  {
    label: 'Logs',
    path: '/logs',
    icon: FiFileText,
  },
  {
    label: 'Configurações',
    path: '/settings',
    icon: FiSettings,
  },
]

const SidebarItem = ({ item, isOpen }) => {
  const location = useLocation()
  const [expandSubmenu, setExpandSubmenu] = React.useState(false)

  const isActive = item.path ? location.pathname === item.path : false
  const isSubmenuActive = item.submenu?.some((sub) => location.pathname === sub.path)

  if (item.submenu) {
    return (
      <div>
        <button
          onClick={() => setExpandSubmenu(!expandSubmenu)}
          className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-smooth ${
            isSubmenuActive
              ? 'bg-nexus-primary/20 text-nexus-primary'
              : 'text-nexus-text-secondary hover:text-nexus-text'
          }`}
        >
          <item.icon size={20} />
          {isOpen && (
            <>
              <span className="flex-1 text-left">{item.label}</span>
              <motion.svg
                animate={{ rotate: expandSubmenu ? 180 : 0 }}
                className="w-4 h-4"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 14l-7 7m0 0l-7-7m7 7V3" />
              </motion.svg>
            </>
          )}
        </button>
        <motion.div
          initial={false}
          animate={{ height: expandSubmenu ? 'auto' : 0 }}
          className="overflow-hidden"
        >
          <div className="pl-6 space-y-1 py-2">
            {item.submenu.map((subitem) => (
              <Link
                key={subitem.path}
                to={subitem.path}
                className={`flex items-center gap-3 px-4 py-2 rounded-lg transition-smooth ${
                  location.pathname === subitem.path
                    ? 'bg-nexus-primary/20 text-nexus-primary'
                    : 'text-nexus-text-secondary hover:text-nexus-text'
                }`}
              >
                <subitem.icon size={18} />
                {isOpen && <span className="text-sm">{subitem.label}</span>}
              </Link>
            ))}
          </div>
        </motion.div>
      </div>
    )
  }

  return (
    <Link
      to={item.path}
      className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-smooth relative ${
        isActive
          ? 'bg-nexus-primary/20 text-nexus-primary'
          : 'text-nexus-text-secondary hover:text-nexus-text'
      }`}
    >
      <item.icon size={20} />
      {isOpen && <span className="flex-1">{item.label}</span>}
      {item.badge && (
        <span className="ml-auto bg-nexus-error text-white text-xs px-2 py-1 rounded-full">
          {item.badge}
        </span>
      )}
    </Link>
  )
}

export const Sidebar = () => {
  const navigate = useNavigate()
  const sidebarOpen = useUIStore((state) => state.sidebarOpen)
  const toggleSidebar = useUIStore((state) => state.toggleSidebar)
  const handleLogout = () => {
    localStorage.removeItem('token')
    localStorage.removeItem('auth-storage')
    navigate('/login', { replace: true })
  }

  return (
    <>
      {/* Mobile Backdrop */}
      {sidebarOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={toggleSidebar}
          className="fixed inset-0 bg-black/50 backdrop-blur-sm lg:hidden z-30"
        />
      )}

      {/* Sidebar */}
      <motion.aside
        animate={{ x: sidebarOpen ? 0 : -300 }}
        transition={{ type: 'spring', damping: 20 }}
        className="fixed lg:static left-0 top-0 h-screen w-72 bg-nexus-bg border-r border-nexus-border overflow-y-auto z-40 lg:z-10"
      >
        <div className="p-6 flex items-center justify-between sticky top-0 bg-nexus-bg/95 backdrop-blur">
          <h1 className="text-xl font-bold gradient-text">Nexustwos</h1>
          <button
            onClick={toggleSidebar}
            className="lg:hidden text-nexus-text-secondary hover:text-nexus-text"
          >
            <FiX size={24} />
          </button>
        </div>

        <nav className="px-4 py-6 space-y-2">
          {menuItems.map((item, idx) => (
            <SidebarItem key={idx} item={item} isOpen={true} />
          ))}
        </nav>

        {/* Footer */}
        <div className="absolute bottom-0 left-0 right-0 p-4 border-t border-nexus-border bg-nexus-bg/95 backdrop-blur space-y-2">
          <Link
            to="/profile"
            className="flex items-center gap-3 px-4 py-3 rounded-lg text-nexus-text-secondary hover:text-nexus-text transition-smooth"
          >
            <FiUser size={20} />
            <span>Perfil</span>
          </Link>
          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-3 px-4 py-3 rounded-lg text-nexus-error hover:bg-nexus-error/10 transition-smooth"
          >
            <FiLogOut size={20} />
            <span>Sair</span>
          </button>
        </div>
      </motion.aside>
    </>
  )
}
