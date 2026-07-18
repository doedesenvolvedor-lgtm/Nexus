import React from 'react'
import { motion } from 'framer-motion'
import { FiChevronUp, FiChevronDown, FiEye, FiEdit, FiTrash2, FiMoreVertical } from 'react-icons/fi'
import { Pagination, EmptyState, Loading, Skeleton } from './ui'

export const Table = ({
  columns = [],
  data = [],
  loading = false,
  error = null,
  onRowClick,
  selectable = false,
  paginated = true,
  pageSize = 10,
  actions = [],
  className = '',
}) => {
  const [selectedRows, setSelectedRows] = React.useState(new Set())
  const [currentPage, setCurrentPage] = React.useState(1)
  const [sortColumn, setSortColumn] = React.useState(null)
  const [sortDirection, setSortDirection] = React.useState('asc')

  const handleSort = (columnKey) => {
    if (sortColumn === columnKey) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc')
    } else {
      setSortColumn(columnKey)
      setSortDirection('asc')
    }
  }

  const toggleRowSelection = (rowId) => {
    const newSelected = new Set(selectedRows)
    if (newSelected.has(rowId)) {
      newSelected.delete(rowId)
    } else {
      newSelected.add(rowId)
    }
    setSelectedRows(newSelected)
  }

  const toggleAllSelection = () => {
    if (selectedRows.size === paginatedData.length) {
      setSelectedRows(new Set())
    } else {
      setSelectedRows(new Set(paginatedData.map((row, idx) => idx)))
    }
  }

  let processedData = [...data]

  if (sortColumn) {
    processedData.sort((a, b) => {
      const aVal = a[sortColumn]
      const bVal = b[sortColumn]
      const comparison = aVal < bVal ? -1 : aVal > bVal ? 1 : 0
      return sortDirection === 'asc' ? comparison : -comparison
    })
  }

  const totalPages = Math.ceil(processedData.length / pageSize)
  const startIdx = (currentPage - 1) * pageSize
  const paginatedData = paginated ? processedData.slice(startIdx, startIdx + pageSize) : processedData

  if (error) {
    return (
      <EmptyState
        title="Erro ao carregar dados"
        message={error}
        className="bg-nexus-card border border-nexus-border rounded-lg"
      />
    )
  }

  if (loading) {
    return (
      <div className="bg-nexus-card border border-nexus-border rounded-lg p-6 space-y-4">
        {Array(5)
          .fill(0)
          .map((_, i) => (
            <Skeleton key={i} height="h-10" />
          ))}
      </div>
    )
  }

  if (paginatedData.length === 0) {
    return (
      <EmptyState
        title="Nenhum dado"
        message="Não há dados para exibir"
        className="bg-nexus-card border border-nexus-border rounded-lg"
      />
    )
  }

  return (
    <div className={`bg-nexus-card border border-nexus-border rounded-lg overflow-hidden ${className}`}>
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-nexus-bg border-b border-nexus-border">
            <tr>
              {selectable && (
                <th className="px-6 py-4 text-left">
                  <input
                    type="checkbox"
                    checked={selectedRows.size === paginatedData.length && paginatedData.length > 0}
                    onChange={toggleAllSelection}
                    className="w-4 h-4 rounded cursor-pointer"
                  />
                </th>
              )}
              {columns.map((column) => (
                <th
                  key={column.key}
                  className="px-6 py-4 text-left text-sm font-semibold text-nexus-text-secondary cursor-pointer hover:text-nexus-text transition-smooth group"
                  onClick={() => column.sortable && handleSort(column.key)}
                >
                  <div className="flex items-center gap-2">
                    {column.label}
                    {column.sortable && (
                      <span className="opacity-0 group-hover:opacity-100 transition-opacity">
                        {sortColumn === column.key ? (
                          sortDirection === 'asc' ? (
                            <FiChevronUp size={16} />
                          ) : (
                            <FiChevronDown size={16} />
                          )
                        ) : (
                          <FiChevronUp size={16} className="opacity-50" />
                        )}
                      </span>
                    )}
                  </div>
                </th>
              ))}
              {actions.length > 0 && <th className="px-6 py-4 text-left text-sm font-semibold text-nexus-text-secondary">Ações</th>}
            </tr>
          </thead>
          <tbody className="divide-y divide-nexus-border">
            {paginatedData.map((row, rowIdx) => (
              <motion.tr
                key={rowIdx}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                whileHover={{ backgroundColor: 'rgba(109, 40, 255, 0.05)' }}
                className="transition-colors"
              >
                {selectable && (
                  <td className="px-6 py-4">
                    <input
                      type="checkbox"
                      checked={selectedRows.has(rowIdx)}
                      onChange={() => toggleRowSelection(rowIdx)}
                      className="w-4 h-4 rounded cursor-pointer"
                    />
                  </td>
                )}
                {columns.map((column) => (
                  <td
                    key={column.key}
                    className="px-6 py-4 text-sm text-nexus-text cursor-pointer hover:text-nexus-primary transition-colors"
                    onClick={() => onRowClick?.(row)}
                  >
                    {column.render ? column.render(row[column.key], row) : row[column.key]}
                  </td>
                ))}
                {actions.length > 0 && (
                  <td className="px-6 py-4 text-sm">
                    <div className="flex items-center gap-2">
                      {actions.map((action, idx) => (
                        <motion.button
                          key={idx}
                          whileHover={{ scale: 1.1 }}
                          whileTap={{ scale: 0.95 }}
                          onClick={() => action.onClick?.(row)}
                          className={`p-2 rounded-lg transition-smooth ${
                            action.variant === 'danger'
                              ? 'text-nexus-error hover:bg-nexus-error/10'
                              : 'text-nexus-text-secondary hover:text-nexus-primary hover:bg-nexus-primary/10'
                          }`}
                          title={action.label}
                        >
                          {action.icon ? <action.icon size={18} /> : action.label}
                        </motion.button>
                      ))}
                    </div>
                  </td>
                )}
              </motion.tr>
            ))}
          </tbody>
        </table>
      </div>

      {paginated && totalPages > 1 && (
        <div className="px-6 py-4 border-t border-nexus-border">
          <Pagination
            currentPage={currentPage}
            totalPages={totalPages}
            onPageChange={setCurrentPage}
          />
        </div>
      )}
    </div>
  )
}

export const FilterBar = ({
  filters = [],
  onFilterChange,
  onReset,
  loading = false,
  className = '',
}) => {
  const [filterValues, setFilterValues] = React.useState({})

  const handleFilterChange = (key, value) => {
    setFilterValues((prev) => ({
      ...prev,
      [key]: value,
    }))
    onFilterChange?.(key, value)
  }

  const handleReset = () => {
    setFilterValues({})
    onReset?.()
  }

  return (
    <div className={`bg-nexus-card border border-nexus-border rounded-lg p-6 ${className}`}>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filters.map((filter) => (
          <div key={filter.key}>
            {filter.type === 'text' && (
              <input
                type="text"
                placeholder={filter.placeholder}
                value={filterValues[filter.key] || ''}
                onChange={(e) => handleFilterChange(filter.key, e.target.value)}
                className="w-full bg-nexus-bg border border-nexus-border rounded-lg px-4 py-2 text-sm text-nexus-text placeholder:text-nexus-text-secondary focus:border-nexus-primary focus:ring-2 focus:ring-nexus-primary/20 transition-smooth"
              />
            )}
            {filter.type === 'select' && (
              <select
                value={filterValues[filter.key] || ''}
                onChange={(e) => handleFilterChange(filter.key, e.target.value)}
                className="w-full bg-nexus-bg border border-nexus-border rounded-lg px-4 py-2 text-sm text-nexus-text focus:border-nexus-primary focus:ring-2 focus:ring-nexus-primary/20 transition-smooth"
              >
                <option value="">{filter.placeholder}</option>
                {filter.options?.map((option) => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>
            )}
            {filter.type === 'date' && (
              <input
                type="date"
                value={filterValues[filter.key] || ''}
                onChange={(e) => handleFilterChange(filter.key, e.target.value)}
                className="w-full bg-nexus-bg border border-nexus-border rounded-lg px-4 py-2 text-sm text-nexus-text focus:border-nexus-primary focus:ring-2 focus:ring-nexus-primary/20 transition-smooth"
              />
            )}
          </div>
        ))}
      </div>
      <div className="flex gap-3 mt-4">
        <button
          onClick={handleReset}
          disabled={loading}
          className="px-4 py-2 bg-nexus-bg border border-nexus-border rounded-lg text-sm text-nexus-text hover:bg-nexus-card transition-smooth disabled:opacity-50"
        >
          Resetar
        </button>
      </div>
    </div>
  )
}
