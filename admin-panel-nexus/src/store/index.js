import { create } from 'zustand'
import { devtools, persist } from 'zustand/middleware'

export const useAuthStore = create(
  devtools(
    persist(
      (set) => ({
        token: null,
        user: null,
        isAuthenticated: false,
        
        setAuth: (token, user) => set({
          token,
          user,
          isAuthenticated: !!token
        }),
        
        logout: () => set({
          token: null,
          user: null,
          isAuthenticated: false
        }),
      }),
      {
        name: 'auth-storage',
      }
    )
  )
)

export const useUIStore = create(
  devtools(
    persist(
      (set) => ({
        sidebarOpen: true,
        theme: 'dark',
        notifications: [],
        
        toggleSidebar: () => set((state) => ({
          sidebarOpen: !state.sidebarOpen
        })),
        
        addNotification: (notification) => set((state) => ({
          notifications: [...state.notifications, notification]
        })),
        
        removeNotification: (id) => set((state) => ({
          notifications: state.notifications.filter(n => n.id !== id)
        })),
      }),
      {
        name: 'ui-storage',
      }
    )
  )
)

export const useDashboardStore = create(
  devtools((set) => ({
    stats: null,
    loading: false,
    error: null,
    
    setStats: (stats) => set({ stats }),
    setLoading: (loading) => set({ loading }),
    setError: (error) => set({ error }),
  }))
)

export const useContentStore = create(
  devtools((set) => ({
    movies: [],
    series: [],
    episodes: [],
    loading: false,
    error: null,
    
    setMovies: (movies) => set({ movies }),
    setSeries: (series) => set({ series }),
    setEpisodes: (episodes) => set({ episodes }),
    setLoading: (loading) => set({ loading }),
    setError: (error) => set({ error }),
  }))
)

export const useUserStore = create(
  devtools((set) => ({
    users: [],
    selectedUser: null,
    loading: false,
    error: null,
    
    setUsers: (users) => set({ users }),
    setSelectedUser: (user) => set({ selectedUser: user }),
    setLoading: (loading) => set({ loading }),
    setError: (error) => set({ error }),
  }))
)
