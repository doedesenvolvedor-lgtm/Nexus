import React from 'react'
import { motion } from 'framer-motion'
import { useUIStore } from '../store'

export const Notification = ({ id, title, message, variant = 'info', duration = 4000, onClose }) => {
  React.useEffect(() => {
    if (duration) {
      const timer = setTimeout(onClose, duration)
      return () => clearTimeout(timer)
    }
  }, [duration, onClose])

  const variantClasses = {
    success: 'bg-green-500/20 border-green-500/50 text-green-300',
    error: 'bg-red-500/20 border-red-500/50 text-red-300',
    warning: 'bg-yellow-500/20 border-yellow-500/50 text-yellow-300',
    info: 'bg-blue-500/20 border-blue-500/50 text-blue-300',
  }

  const icons = {
    success: '✓',
    error: '✕',
    warning: '⚠️',
    info: 'ℹ️',
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20, x: 20 }}
      animate={{ opacity: 1, y: 0, x: 0 }}
      exit={{ opacity: 0, y: 20, x: 20 }}
      className={`border rounded-lg p-4 ${variantClasses[variant]} flex items-start gap-3 min-w-[300px]`}
    >
      <span className="text-xl mt-1">{icons[variant]}</span>
      <div className="flex-1">
        {title && <h4 className="font-semibold">{title}</h4>}
        <p className="text-sm opacity-90">{message}</p>
      </div>
      <button
        onClick={onClose}
        className="text-current hover:opacity-75 transition-smooth"
      >
        ✕
      </button>
    </motion.div>
  )
}

export const NotificationContainer = () => {
  const notifications = useUIStore((state) => state.notifications)
  const removeNotification = useUIStore((state) => state.removeNotification)

  return (
    <div className="fixed top-6 right-6 flex flex-col gap-3 pointer-events-none z-50">
      {notifications.map((notification) => (
        <div key={notification.id} className="pointer-events-auto">
          <Notification
            {...notification}
            onClose={() => removeNotification(notification.id)}
          />
        </div>
      ))}
    </div>
  )
}
