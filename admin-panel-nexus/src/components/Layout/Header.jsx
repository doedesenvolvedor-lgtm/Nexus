import React from 'react'
import { motion } from 'framer-motion'
import { useUIStore } from '../../store'
import { FiMenu, FiSearch, FiBell, FiSettings, FiUser } from 'react-icons/fi'
import { Tooltip } from '../ui'

export const Header = ({ title, subtitle }) => {
  const toggleSidebar = useUIStore((state) => state.toggleSidebar)

  return (
    <motion.header
      initial={{ y: -20, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      className="sticky top-0 bg-nexus-bg border-b border-nexus-border px-6 py-4 flex items-center justify-between gap-4 z-20"
    >
      <div className="flex items-center gap-4 flex-1">
        <button
          onClick={toggleSidebar}
          className="lg:hidden text-nexus-text hover:text-nexus-primary transition-smooth"
        >
          <FiMenu size={24} />
        </button>

        <div className="hidden md:flex flex-col">
          <h1 className="text-2xl font-bold text-nexus-text">{title}</h1>
          {subtitle && <p className="text-nexus-text-secondary text-sm">{subtitle}</p>}
        </div>
      </div>

      {/* Search Bar */}
      <div className="hidden md:flex items-center flex-1 max-w-xs gap-2">
        <div className="relative flex-1">
          <FiSearch className="absolute left-3 top-1/2 transform -translate-y-1/2 text-nexus-text-secondary" size={18} />
          <input
            type="text"
            placeholder="Buscar..."
            className="w-full bg-nexus-card border border-nexus-border rounded-lg px-4 py-2 pl-10 text-sm text-nexus-text placeholder:text-nexus-text-secondary focus:border-nexus-primary focus:ring-2 focus:ring-nexus-primary/20 transition-smooth"
          />
        </div>
      </div>

      {/* Right Actions */}
      <div className="flex items-center gap-4">
        <Tooltip text="Notificações">
          <button className="relative p-2 text-nexus-text-secondary hover:text-nexus-text transition-smooth">
            <FiBell size={22} />
            <span className="absolute top-1 right-1 w-2 h-2 bg-nexus-error rounded-full"></span>
          </button>
        </Tooltip>

        <Tooltip text="Configurações">
          <button className="p-2 text-nexus-text-secondary hover:text-nexus-text transition-smooth">
            <FiSettings size={22} />
          </button>
        </Tooltip>

        <div className="flex items-center gap-3 pl-4 border-l border-nexus-border">
          <div className="hidden sm:flex flex-col text-right">
            <span className="text-sm font-medium text-nexus-text">Admin</span>
            <span className="text-xs text-nexus-text-secondary">admin@nexus.com</span>
          </div>
          <button className="w-10 h-10 rounded-full bg-gradient-to-br from-nexus-primary to-nexus-secondary hover:shadow-lg transition-smooth">
            <span className="text-white font-bold">A</span>
          </button>
        </div>
      </div>
    </motion.header>
  )
}

export const PageHeader = ({ 
  title, 
  subtitle, 
  actions = [],
  breadcrumb = [],
  className = '' 
}) => {
  return (
    <div className={`flex flex-col gap-4 mb-8 ${className}`}>
      {breadcrumb.length > 0 && (
        <div className="flex items-center gap-2 text-sm text-nexus-text-secondary">
          {breadcrumb.map((item, idx) => (
            <React.Fragment key={idx}>
              {idx > 0 && <span>/</span>}
              <span className={item.active ? 'text-nexus-primary font-medium' : ''}>
                {item.label}
              </span>
            </React.Fragment>
          ))}
        </div>
      )}

      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-6">
        <div>
          <h1 className="text-3xl font-bold text-nexus-text mb-2">{title}</h1>
          {subtitle && <p className="text-nexus-text-secondary">{subtitle}</p>}
        </div>

        {actions.length > 0 && (
          <div className="flex flex-wrap gap-3">
            {actions}
          </div>
        )}
      </div>
    </div>
  )
}

export const Section = ({ title, children, className = '', action }) => {
  return (
    <div className={`bg-nexus-card border border-nexus-border rounded-lg ${className}`}>
      {title && (
        <div className="px-6 py-4 border-b border-nexus-border flex items-center justify-between">
          <h2 className="text-lg font-bold text-nexus-text">{title}</h2>
          {action && action}
        </div>
      )}
      <div className="p-6">
        {children}
      </div>
    </div>
  )
}

export const Container = ({ children, className = '' }) => {
  return <div className={`max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 ${className}`}>{children}</div>
}
