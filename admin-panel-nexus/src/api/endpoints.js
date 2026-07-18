import api from './client'

// ===== DASHBOARD =====
export const dashboardAPI = {
  getStats: () => api.get('/admin/dashboard/stats'),
  getRevenueChart: (period = 'month') => api.get(`/admin/dashboard/revenue?period=${period}`),
  getNewUsersChart: (period = 'month') => api.get(`/admin/dashboard/new-users?period=${period}`),
  getSubscriptionsChart: (period = 'month') => api.get(`/admin/dashboard/subscriptions?period=${period}`),
  getViewsChart: (period = 'month') => api.get(`/admin/dashboard/views?period=${period}`),
  getDevicesChart: () => api.get('/admin/dashboard/devices'),
  getCountriesChart: () => api.get('/admin/dashboard/countries'),
  getCrashReports: (page = 1, limit = 10) => api.get(`/admin/dashboard/crashes?page=${page}&limit=${limit}`),
}

// ===== FILMES =====
export const moviesAPI = {
  list: (page = 1, limit = 20, filters = {}) => 
    api.get('/admin/movies', { params: { page, limit, ...filters } }),
  get: (id) => api.get(`/admin/movies/${id}`),
  create: (data) => api.post('/admin/movies', data),
  update: (id, data) => api.put(`/admin/movies/${id}`, data),
  delete: (id) => api.delete(`/admin/movies/${id}`),
  upload: (id, file) => {
    const formData = new FormData()
    formData.append('file', file)
    return api.post(`/admin/movies/${id}/upload`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
  },
  searchTMDb: (query) => api.get(`/admin/movies/tmdb/search?q=${query}`),
  importFromTMDb: (tmdbId) => api.post(`/admin/movies/tmdb/import`, { tmdb_id: tmdbId }),
}

// ===== SÉRIES =====
export const seriesAPI = {
  list: (page = 1, limit = 20, filters = {}) => 
    api.get('/admin/series', { params: { page, limit, ...filters } }),
  get: (id) => api.get(`/admin/series/${id}`),
  create: (data) => api.post('/admin/series', data),
  update: (id, data) => api.put(`/admin/series/${id}`, data),
  delete: (id) => api.delete(`/admin/series/${id}`),
  upload: (id, file) => {
    const formData = new FormData()
    formData.append('file', file)
    return api.post(`/admin/series/${id}/upload`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
  },
}

// ===== TEMPORADAS =====
export const seasonsAPI = {
  list: (seriesId, page = 1, limit = 20) => 
    api.get(`/admin/series/${seriesId}/seasons`, { params: { page, limit } }),
  get: (seriesId, seasonId) => api.get(`/admin/series/${seriesId}/seasons/${seasonId}`),
  create: (seriesId, data) => api.post(`/admin/series/${seriesId}/seasons`, data),
  update: (seriesId, seasonId, data) => api.put(`/admin/series/${seriesId}/seasons/${seasonId}`, data),
  delete: (seriesId, seasonId) => api.delete(`/admin/series/${seriesId}/seasons/${seasonId}`),
}

// ===== EPISÓDIOS =====
export const episodesAPI = {
  list: (seriesId, seasonId, page = 1, limit = 20) => 
    api.get(`/admin/series/${seriesId}/seasons/${seasonId}/episodes`, { params: { page, limit } }),
  get: (seriesId, seasonId, episodeId) => 
    api.get(`/admin/series/${seriesId}/seasons/${seasonId}/episodes/${episodeId}`),
  create: (seriesId, seasonId, data) => 
    api.post(`/admin/series/${seriesId}/seasons/${seasonId}/episodes`, data),
  update: (seriesId, seasonId, episodeId, data) => 
    api.put(`/admin/series/${seriesId}/seasons/${seasonId}/episodes/${episodeId}`, data),
  delete: (seriesId, seasonId, episodeId) => 
    api.delete(`/admin/series/${seriesId}/seasons/${seasonId}/episodes/${episodeId}`),
}

// ===== USUÁRIOS =====
export const usersAPI = {
  list: (page = 1, limit = 20, filters = {}) => 
    api.get('/admin/users', { params: { page, limit, ...filters } }),
  get: (id) => api.get(`/admin/users/${id}`),
  update: (id, data) => api.put(`/admin/users/${id}`, data),
  delete: (id) => api.delete(`/admin/users/${id}`),
  block: (id) => api.post(`/admin/users/${id}/block`),
  unblock: (id) => api.post(`/admin/users/${id}/unblock`),
  changePlan: (id, plan) => api.post(`/admin/users/${id}/plan`, { plan }),
  getHistory: (id) => api.get(`/admin/users/${id}/history`),
  getFavorites: (id) => api.get(`/admin/users/${id}/favorites`),
  getDevices: (id) => api.get(`/admin/users/${id}/devices`),
}

// ===== PERFIS =====
export const profilesAPI = {
  list: (userId, page = 1, limit = 20) => 
    api.get(`/admin/users/${userId}/profiles`, { params: { page, limit } }),
  get: (userId, profileId) => api.get(`/admin/users/${userId}/profiles/${profileId}`),
  update: (userId, profileId, data) => api.put(`/admin/users/${userId}/profiles/${profileId}`, data),
  delete: (userId, profileId) => api.delete(`/admin/users/${userId}/profiles/${profileId}`),
  changePIN: (userId, profileId, pin) => api.post(`/admin/users/${userId}/profiles/${profileId}/pin`, { pin }),
}

// ===== ASSINATURAS =====
export const subscriptionsAPI = {
  list: (page = 1, limit = 20, filters = {}) => 
    api.get('/admin/subscriptions', { params: { page, limit, ...filters } }),
  get: (id) => api.get(`/admin/subscriptions/${id}`),
  update: (id, data) => api.put(`/admin/subscriptions/${id}`, data),
  cancel: (id) => api.post(`/admin/subscriptions/${id}/cancel`),
  getPlans: () => api.get('/admin/plans'),
  updatePlan: (id, planId) => api.post(`/admin/subscriptions/${id}/plan`, { plan_id: planId }),
}

// ===== PLANOS =====
export const plansAPI = {
  list: () => api.get('/admin/plans'),
  get: (id) => api.get(`/admin/plans/${id}`),
  create: (data) => api.post('/admin/plans', data),
  update: (id, data) => api.put(`/admin/plans/${id}`, data),
  delete: (id) => api.delete(`/admin/plans/${id}`),
}

// ===== TRIALS =====
export const trialsAPI = {
  list: (page = 1, limit = 20, filters = {}) => 
    api.get('/admin/trials', { params: { page, limit, ...filters } }),
  get: (userId) => api.get(`/admin/trials/${userId}`),
  extend: (userId, days = 3) => api.post(`/admin/trials/${userId}/extend`, { days }),
  cancel: (userId) => api.post(`/admin/trials/${userId}/cancel`),
  convertToPremium: (userId) => api.post(`/admin/trials/${userId}/convert`),
  getStats: () => api.get('/admin/trials/analytics/summary'),
}

// ===== PAGAMENTOS =====
export const paymentsAPI = {
  list: (page = 1, limit = 20, filters = {}) => 
    api.get('/admin/payments', { params: { page, limit, ...filters } }),
  get: (id) => api.get(`/admin/payments/${id}`),
  refund: (id) => api.post(`/admin/payments/${id}/refund`),
  getStats: () => api.get('/admin/payments/stats'),
  exportExcel: (filters = {}) => api.get('/admin/payments/export/excel', { params: filters }),
  exportPDF: (filters = {}) => api.get('/admin/payments/export/pdf', { params: filters }),
}

// ===== CUPONS =====
export const couponsAPI = {
  list: (page = 1, limit = 20, filters = {}) => 
    api.get('/admin/coupons', { params: { page, limit, ...filters } }),
  get: (id) => api.get(`/admin/coupons/${id}`),
  create: (data) => api.post('/admin/coupons', data),
  update: (id, data) => api.put(`/admin/coupons/${id}`, data),
  delete: (id) => api.delete(`/admin/coupons/${id}`),
}

// ===== NOTIFICAÇÕES =====
export const notificationsAPI = {
  list: (page = 1, limit = 20) => 
    api.get('/admin/notifications', { params: { page, limit } }),
  send: (data) => api.post('/admin/notifications/send', data),
  schedule: (data) => api.post('/admin/notifications/schedule', data),
  getHistory: (page = 1, limit = 20) => api.get('/admin/notifications/history', { params: { page, limit } }),
}

// ===== COMENTÁRIOS =====
export const commentsAPI = {
  list: (page = 1, limit = 20, filters = {}) => 
    api.get('/admin/comments', { params: { page, limit, ...filters } }),
  approve: (id) => api.post(`/admin/comments/${id}/approve`),
  reject: (id) => api.post(`/admin/comments/${id}/reject`),
  delete: (id) => api.delete(`/admin/comments/${id}`),
  blockUser: (userId) => api.post(`/admin/comments/block-user`, { user_id: userId }),
}

// ===== BANNERS =====
export const bannersAPI = {
  list: (page = 1, limit = 20) => api.get('/admin/banners', { params: { page, limit } }),
  get: (id) => api.get(`/admin/banners/${id}`),
  create: (data) => api.post('/admin/banners', data),
  update: (id, data) => api.put(`/admin/banners/${id}`, data),
  delete: (id) => api.delete(`/admin/banners/${id}`),
  reorder: (order) => api.post('/admin/banners/reorder', { order }),
  schedule: (id, schedule) => api.post(`/admin/banners/${id}/schedule`, schedule),
}

// ===== IMPORTADOR M3U =====
export const importerAPI = {
  importURL: (url) => api.post('/admin/import/m3u/url', { url }),
  importFile: (file) => {
    const formData = new FormData()
    formData.append('file', file)
    return api.post('/admin/import/m3u/file', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
  },
  removeDuplicates: () => api.post('/admin/import/remove-duplicates'),
  getStatus: () => api.get('/admin/import/status'),
  updateAutomatically: (enabled) => api.post('/admin/import/auto-update', { enabled }),
}

// ===== CATEGORIAS =====
export const categoriesAPI = {
  list: () => api.get('/admin/categories'),
  get: (id) => api.get(`/admin/categories/${id}`),
  create: (data) => api.post('/admin/categories', data),
  update: (id, data) => api.put(`/admin/categories/${id}`, data),
  delete: (id) => api.delete(`/admin/categories/${id}`),
}

// ===== CANAIS AO VIVO =====
export const channelsAPI = {
  list: (page = 1, limit = 20) => api.get('/admin/channels', { params: { page, limit } }),
  get: (id) => api.get(`/admin/channels/${id}`),
  create: (data) => api.post('/admin/channels', data),
  update: (id, data) => api.put(`/admin/channels/${id}`, data),
  delete: (id) => api.delete(`/admin/channels/${id}`),
}

// ===== LOGS =====
export const logsAPI = {
  list: (page = 1, limit = 20, filters = {}) => 
    api.get('/admin/logs', { params: { page, limit, ...filters } }),
  export: (filters = {}) => api.get('/admin/logs/export', { params: filters }),
}

// ===== CONFIGURAÇÕES =====
export const settingsAPI = {
  get: () => api.get('/admin/settings'),
  update: (data) => api.put('/admin/settings', data),
  testEmail: (email) => api.post('/admin/settings/test-email', { email }),
  testSMTP: (config) => api.post('/admin/settings/test-smtp', config),
  backupDatabase: () => api.post('/admin/settings/backup'),
  restoreDatabase: (backupId) => api.post(`/admin/settings/restore`, { backup_id: backupId }),
}

// ===== ANALYTICS =====
export const analyticsAPI = {
  getUsers: (period = 'month') => api.get(`/admin/analytics/users?period=${period}`),
  getSessions: (period = 'month') => api.get(`/admin/analytics/sessions?period=${period}`),
  getWatchTime: (period = 'month') => api.get(`/admin/analytics/watch-time?period=${period}`),
  getTopContent: (type = 'movies', limit = 10) => api.get(`/admin/analytics/top-content?type=${type}&limit=${limit}`),
  getDevices: () => api.get('/admin/analytics/devices'),
  getCountries: () => api.get('/admin/analytics/countries'),
  getCities: () => api.get('/admin/analytics/cities'),
  getAppVersions: () => api.get('/admin/analytics/app-versions'),
}

// ===== AUTENTICAÇÃO =====
export const authAPI = {
  login: (email, password) => api.post('/auth/login', { email, password }),
  logout: () => api.post('/auth/logout'),
  getProfile: () => api.get('/auth/profile'),
  updateProfile: (data) => api.put('/auth/profile', data),
  changePassword: (currentPassword, newPassword) => 
    api.post('/auth/change-password', { current_password: currentPassword, new_password: newPassword }),
  enable2FA: () => api.post('/auth/2fa/enable'),
  verify2FA: (code) => api.post('/auth/2fa/verify', { code }),
  disable2FA: () => api.post('/auth/2fa/disable'),
}

export default api
