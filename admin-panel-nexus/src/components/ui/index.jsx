import React from 'react'
import { motion } from 'framer-motion'

export const Button = ({
  children,
  variant = 'primary',
  size = 'md',
  disabled = false,
  loading = false,
  icon: Icon,
  className = '',
  ...props
}) => {
  const baseClasses = 'font-medium rounded-lg transition-smooth focus:outline-none'
  
  const variantClasses = {
    primary: 'bg-nexus-primary hover:bg-purple-700 text-white shadow-lg hover:shadow-purple-500/50',
    secondary: 'bg-nexus-secondary hover:bg-blue-600 text-white shadow-lg hover:shadow-blue-500/50',
    ghost: 'bg-transparent hover:bg-nexus-card text-nexus-text',
    danger: 'bg-nexus-error hover:bg-red-700 text-white',
    success: 'bg-nexus-success hover:bg-green-600 text-white',
  }
  
  const sizeClasses = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg',
  }
  
  return (
    <motion.button
      whileHover={{ scale: disabled ? 1 : 1.02 }}
      whileTap={{ scale: disabled ? 1 : 0.98 }}
      disabled={disabled || loading}
      className={`${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]} ${className} disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2 justify-center`}
      {...props}
    >
      {loading ? (
        <svg className="animate-spin h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
      ) : Icon ? (
        <Icon size={20} />
      ) : null}
      {children}
    </motion.button>
  )
}

export const Card = ({ children, className = '', variant = 'default', ...props }) => {
  const variantClasses = {
    default: 'bg-nexus-card border border-nexus-border',
    glass: 'glass',
    gradient: 'bg-gradient-to-br from-nexus-card to-nexus-bg border border-nexus-border',
  }
  
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className={`rounded-lg p-6 shadow-lg ${variantClasses[variant]} ${className}`}
      {...props}
    >
      {children}
    </motion.div>
  )
}

export const Input = ({
  label,
  error,
  icon: Icon,
  value,
  onChange,
  type = 'text',
  placeholder,
  required = false,
  disabled = false,
  className = '',
  ...props
}) => {
  return (
    <div className={`flex flex-col gap-2 ${className}`}>
      {label && (
        <label className="text-sm font-medium text-nexus-text">
          {label}
          {required && <span className="text-nexus-error ml-1">*</span>}
        </label>
      )}
      <div className="relative">
        {Icon && (
          <Icon className="absolute left-3 top-1/2 transform -translate-y-1/2 text-nexus-text-secondary" size={20} />
        )}
        <input
          type={type}
          value={value}
          onChange={onChange}
          placeholder={placeholder}
          disabled={disabled}
          className={`w-full bg-nexus-card border border-nexus-border rounded-lg px-4 py-2 text-nexus-text placeholder:text-nexus-text-secondary focus:border-nexus-primary focus:ring-2 focus:ring-nexus-primary/20 transition-smooth ${Icon ? 'pl-10' : ''} disabled:opacity-50 disabled:cursor-not-allowed`}
          {...props}
        />
      </div>
      {error && <span className="text-sm text-nexus-error">{error}</span>}
    </div>
  )
}

export const Select = ({
  label,
  error,
  value,
  onChange,
  options = [],
  required = false,
  disabled = false,
  className = '',
  ...props
}) => {
  return (
    <div className={`flex flex-col gap-2 ${className}`}>
      {label && (
        <label className="text-sm font-medium text-nexus-text">
          {label}
          {required && <span className="text-nexus-error ml-1">*</span>}
        </label>
      )}
      <select
        value={value}
        onChange={onChange}
        disabled={disabled}
        className="w-full bg-nexus-card border border-nexus-border rounded-lg px-4 py-2 text-nexus-text focus:border-nexus-primary focus:ring-2 focus:ring-nexus-primary/20 transition-smooth disabled:opacity-50 disabled:cursor-not-allowed"
        {...props}
      >
        <option value="">Selecione uma opção</option>
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
      {error && <span className="text-sm text-nexus-error">{error}</span>}
    </div>
  )
}

export const Textarea = ({
  label,
  error,
  value,
  onChange,
  placeholder,
  required = false,
  disabled = false,
  rows = 4,
  className = '',
  ...props
}) => {
  return (
    <div className={`flex flex-col gap-2 ${className}`}>
      {label && (
        <label className="text-sm font-medium text-nexus-text">
          {label}
          {required && <span className="text-nexus-error ml-1">*</span>}
        </label>
      )}
      <textarea
        value={value}
        onChange={onChange}
        placeholder={placeholder}
        disabled={disabled}
        rows={rows}
        className="w-full bg-nexus-card border border-nexus-border rounded-lg px-4 py-2 text-nexus-text placeholder:text-nexus-text-secondary focus:border-nexus-primary focus:ring-2 focus:ring-nexus-primary/20 transition-smooth disabled:opacity-50 disabled:cursor-not-allowed resize-none"
        {...props}
      />
      {error && <span className="text-sm text-nexus-error">{error}</span>}
    </div>
  )
}

export const Modal = ({
  isOpen,
  title,
  children,
  footer,
  onClose,
  size = 'md',
  className = '',
}) => {
  if (!isOpen) return null

  const sizeClasses = {
    sm: 'max-w-sm',
    md: 'max-w-md',
    lg: 'max-w-lg',
    xl: 'max-w-xl',
    '2xl': 'max-w-2xl',
  }

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50"
      onClick={onClose}
    >
      <motion.div
        initial={{ scale: 0.95, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.95, opacity: 0 }}
        className={`bg-nexus-card border border-nexus-border rounded-lg shadow-xl max-h-[90vh] overflow-y-auto ${sizeClasses[size]} w-full mx-4 ${className}`}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between p-6 border-b border-nexus-border sticky top-0 bg-nexus-card">
          <h2 className="text-xl font-bold text-nexus-text">{title}</h2>
          <button
            onClick={onClose}
            className="text-nexus-text-secondary hover:text-nexus-text transition-smooth"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
        <div className="p-6">
          {children}
        </div>
        {footer && (
          <div className="p-6 border-t border-nexus-border flex gap-3 justify-end sticky bottom-0 bg-nexus-card">
            {footer}
          </div>
        )}
      </motion.div>
    </motion.div>
  )
}

export const Badge = ({ children, variant = 'primary', className = '' }) => {
  const variantClasses = {
    primary: 'bg-nexus-primary/20 text-nexus-primary',
    secondary: 'bg-nexus-secondary/20 text-nexus-secondary',
    success: 'bg-nexus-success/20 text-nexus-success',
    warning: 'bg-nexus-warning/20 text-nexus-warning',
    error: 'bg-nexus-error/20 text-nexus-error',
  }
  
  return (
    <span className={`px-3 py-1 rounded-full text-xs font-medium ${variantClasses[variant]} ${className}`}>
      {children}
    </span>
  )
}

export const Alert = ({ title, message, variant = 'info', onClose, className = '' }) => {
  const variantClasses = {
    info: 'bg-blue-500/20 border-blue-500/50 text-blue-300',
    success: 'bg-green-500/20 border-green-500/50 text-green-300',
    warning: 'bg-yellow-500/20 border-yellow-500/50 text-yellow-300',
    error: 'bg-red-500/20 border-red-500/50 text-red-300',
  }

  const iconClasses = {
    info: '👁️',
    success: '✓',
    warning: '⚠️',
    error: '✕',
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -10 }}
      className={`border rounded-lg p-4 ${variantClasses[variant]} ${className}`}
    >
      <div className="flex items-start gap-3">
        <span className="text-xl">{iconClasses[variant]}</span>
        <div className="flex-1">
          {title && <h3 className="font-semibold">{title}</h3>}
          <p className="text-sm opacity-90">{message}</p>
        </div>
        {onClose && (
          <button
            onClick={onClose}
            className="text-current hover:opacity-75 transition-smooth"
          >
            ✕
          </button>
        )}
      </div>
    </motion.div>
  )
}

export const Loading = ({ className = '' }) => (
  <motion.div
    animate={{ rotate: 360 }}
    transition={{ duration: 1, repeat: Infinity, ease: 'linear' }}
    className={`w-8 h-8 border-4 border-nexus-border border-t-nexus-primary rounded-full ${className}`}
  />
)

export const EmptyState = ({ 
  icon: Icon, 
  title = 'Nenhum dado', 
  message = 'Não há dados para exibir',
  action,
  className = '' 
}) => (
  <div className={`flex flex-col items-center justify-center py-12 ${className}`}>
    {Icon && <Icon size={48} className="text-nexus-text-secondary mb-4 opacity-50" />}
    <h3 className="text-lg font-semibold text-nexus-text mb-2">{title}</h3>
    <p className="text-nexus-text-secondary mb-6">{message}</p>
    {action && action}
  </div>
)

export const Pagination = ({ 
  currentPage = 1, 
  totalPages = 1, 
  onPageChange = () => {},
  className = '' 
}) => (
  <div className={`flex items-center gap-2 justify-center ${className}`}>
    <Button
      variant="ghost"
      size="sm"
      onClick={() => onPageChange(currentPage - 1)}
      disabled={currentPage === 1}
    >
      ← Anterior
    </Button>
    <div className="flex items-center gap-1">
      {Array.from({ length: Math.min(5, totalPages) }).map((_, i) => {
        const pageNum = i + 1
        return (
          <button
            key={pageNum}
            onClick={() => onPageChange(pageNum)}
            className={`px-3 py-1 rounded-lg transition-smooth ${
              pageNum === currentPage
                ? 'bg-nexus-primary text-white'
                : 'bg-nexus-card text-nexus-text hover:bg-nexus-card/80'
            }`}
          >
            {pageNum}
          </button>
        )
      })}
    </div>
    <Button
      variant="ghost"
      size="sm"
      onClick={() => onPageChange(currentPage + 1)}
      disabled={currentPage === totalPages}
    >
      Próxima →
    </Button>
  </div>
)

export const Tabs = ({ tabs = [], defaultTab = 0, onChange, className = '' }) => {
  const [activeTab, setActiveTab] = React.useState(defaultTab)

  const handleTabChange = (index) => {
    setActiveTab(index)
    onChange?.(index)
  }

  return (
    <div className={className}>
      <div className="flex gap-2 border-b border-nexus-border overflow-x-auto">
        {tabs.map((tab, index) => (
          <button
            key={index}
            onClick={() => handleTabChange(index)}
            className={`px-4 py-2 font-medium whitespace-nowrap transition-smooth relative ${
              activeTab === index
                ? 'text-nexus-primary'
                : 'text-nexus-text-secondary hover:text-nexus-text'
            }`}
          >
            {tab.label}
            {activeTab === index && (
              <motion.div
                layoutId="activeTab"
                className="absolute bottom-0 left-0 right-0 h-1 bg-nexus-primary"
              />
            )}
          </button>
        ))}
      </div>
      <div className="mt-6">
        {tabs[activeTab]?.content}
      </div>
    </div>
  )
}

export const Skeleton = ({ count = 1, height = 'h-4', className = '' }) => (
  <div className={`space-y-2 ${className}`}>
    {Array(count)
      .fill(0)
      .map((_, i) => (
        <div
          key={i}
          className={`${height} bg-nexus-card rounded animate-shimmer`}
        />
      ))}
  </div>
)

export const Tooltip = ({ text, children, position = 'top' }) => {
  const positionClasses = {
    top: 'bottom-full mb-2',
    bottom: 'top-full mt-2',
    left: 'right-full mr-2',
    right: 'left-full ml-2',
  }

  return (
    <div className="relative group">
      {children}
      <div
        className={`absolute ${positionClasses[position]} hidden group-hover:block bg-nexus-card border border-nexus-border text-nexus-text text-xs px-2 py-1 rounded whitespace-nowrap z-10`}
      >
        {text}
      </div>
    </div>
  )
}
