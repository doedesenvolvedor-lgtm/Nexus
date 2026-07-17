/**
 * Configuração da aplicação Admin
 * Carregada dinamicamente baseada no ambiente
 */

const AppConfig = {
  // API Configuration
  api: {
    baseUrl: process.env.REACT_APP_API_URL || 'https://api.nexustwos.com',
    timeout: 30000,
    retryAttempts: 3,
  },

  // Auth Configuration
  auth: {
    tokenKey: 'admin_token',
    emailKey: 'admin_email',
    refreshTokenKey: 'admin_refresh_token',
    tokenExpireTime: 24 * 60 * 60 * 1000, // 24 horas
  },

  // Feature Flags
  features: {
    enableAnalytics: process.env.REACT_APP_ENABLE_ANALYTICS === 'true',
    enableDebugMode: process.env.REACT_APP_DEBUG_MODE === 'true',
    enableCrashReporting: process.env.REACT_APP_CRASH_REPORTING === 'true',
  },

  // Security
  security: {
    enableCSRFProtection: true,
    enableContentSecurityPolicy: true,
    httpOnlyTokens: true,
  },

  // Environment
  environment: process.env.NODE_ENV || 'production',
  version: process.env.REACT_APP_VERSION || '1.0.0',
};

export default AppConfig;
