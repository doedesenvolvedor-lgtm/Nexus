import React from 'react'
import { BarChart, Bar, LineChart, Line, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts'
import { theme } from '../theme'

export const SimpleBarChart = ({ data, title, xKey, yKey, color = theme.colors.primary, className = '' }) => {
  return (
    <div className={className}>
      {title && <h3 className="text-lg font-semibold text-nexus-text mb-4">{title}</h3>}
      <ResponsiveContainer width="100%" height={300}>
        <BarChart data={data}>
          <CartesianGrid strokeDasharray="3 3" stroke={theme.colors.border} />
          <XAxis dataKey={xKey} stroke={theme.colors.textSecondary} />
          <YAxis stroke={theme.colors.textSecondary} />
          <Tooltip
            contentStyle={{
              backgroundColor: theme.colors.card,
              border: `1px solid ${theme.colors.border}`,
              borderRadius: '8px',
            }}
            labelStyle={{ color: theme.colors.text }}
          />
          <Legend />
          <Bar dataKey={yKey} fill={color} radius={[8, 8, 0, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}

export const SimpleLineChart = ({ data, title, xKey, yKey, color = theme.colors.primary, className = '' }) => {
  return (
    <div className={className}>
      {title && <h3 className="text-lg font-semibold text-nexus-text mb-4">{title}</h3>}
      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={data}>
          <CartesianGrid strokeDasharray="3 3" stroke={theme.colors.border} />
          <XAxis dataKey={xKey} stroke={theme.colors.textSecondary} />
          <YAxis stroke={theme.colors.textSecondary} />
          <Tooltip
            contentStyle={{
              backgroundColor: theme.colors.card,
              border: `1px solid ${theme.colors.border}`,
              borderRadius: '8px',
            }}
            labelStyle={{ color: theme.colors.text }}
          />
          <Legend />
          <Line type="monotone" dataKey={yKey} stroke={color} dot={{ fill: color }} isAnimationActive />
        </LineChart>
      </ResponsiveContainer>
    </div>
  )
}

export const SimplePieChart = ({ data, title, nameKey, valueKey, colors = [theme.colors.primary, theme.colors.secondary, theme.colors.success], className = '' }) => {
  return (
    <div className={className}>
      {title && <h3 className="text-lg font-semibold text-nexus-text mb-4">{title}</h3>}
      <ResponsiveContainer width="100%" height={300}>
        <PieChart>
          <Pie
            data={data}
            cx="50%"
            cy="50%"
            labelLine={false}
            label={({ name, value }) => `${name}: ${value}`}
            outerRadius={100}
            fill="#8884d8"
            dataKey={valueKey}
          >
            {data.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={colors[index % colors.length]} />
            ))}
          </Pie>
          <Tooltip
            contentStyle={{
              backgroundColor: theme.colors.card,
              border: `1px solid ${theme.colors.border}`,
              borderRadius: '8px',
            }}
            labelStyle={{ color: theme.colors.text }}
          />
        </PieChart>
      </ResponsiveContainer>
    </div>
  )
}

export const StatCard = ({ 
  icon: Icon, 
  title, 
  value, 
  change, 
  trend = 'up',
  color = 'primary',
  className = '' 
}) => {
  const colorClasses = {
    primary: 'from-nexus-primary to-purple-700',
    secondary: 'from-nexus-secondary to-blue-600',
    success: 'from-nexus-success to-green-600',
    warning: 'from-nexus-warning to-yellow-600',
    error: 'from-nexus-error to-red-600',
  }

  return (
    <div className={`bg-nexus-card border border-nexus-border rounded-lg p-6 ${className}`}>
      <div className="flex items-start justify-between">
        <div>
          <p className="text-nexus-text-secondary text-sm font-medium mb-2">{title}</p>
          <h3 className="text-3xl font-bold text-nexus-text">{value}</h3>
          {change && (
            <p className={`text-sm mt-2 ${trend === 'up' ? 'text-nexus-success' : 'text-nexus-error'}`}>
              {trend === 'up' ? '↑' : '↓'} {change}
            </p>
          )}
        </div>
        {Icon && (
          <div className={`w-12 h-12 rounded-lg bg-gradient-to-br ${colorClasses[color]} flex items-center justify-center`}>
            <Icon className="text-white" size={24} />
          </div>
        )}
      </div>
    </div>
  )
}

export const ProgressBar = ({ label, value, max = 100, color = 'primary', className = '' }) => {
  const colorClasses = {
    primary: 'bg-nexus-primary',
    secondary: 'bg-nexus-secondary',
    success: 'bg-nexus-success',
    warning: 'bg-nexus-warning',
    error: 'bg-nexus-error',
  }

  const percentage = (value / max) * 100

  return (
    <div className={className}>
      <div className="flex justify-between items-center mb-2">
        <p className="text-sm font-medium text-nexus-text">{label}</p>
        <p className="text-sm text-nexus-text-secondary">{value} / {max}</p>
      </div>
      <div className="w-full bg-nexus-card rounded-full h-2 overflow-hidden">
        <div
          className={`h-full ${colorClasses[color]} transition-all duration-500`}
          style={{ width: `${percentage}%` }}
        />
      </div>
    </div>
  )
}

export const MetricRow = ({ label, value, icon: Icon, color = 'text-nexus-text-secondary', className = '' }) => {
  return (
    <div className={`flex items-center justify-between py-3 border-b border-nexus-border/50 last:border-b-0 ${className}`}>
      <div className="flex items-center gap-3">
        {Icon && <Icon className={color} size={20} />}
        <span className="text-nexus-text-secondary">{label}</span>
      </div>
      <span className="font-semibold text-nexus-text">{value}</span>
    </div>
  )
}
