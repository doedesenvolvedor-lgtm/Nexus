-- Migration 007: Add Admin Audit Logs table
-- Data: 2026-07-26

-- ===== Admin Audit Logs =====
CREATE TABLE IF NOT EXISTS admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    admin_email VARCHAR(255),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id UUID,
    details JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    status VARCHAR(20) DEFAULT 'success',  -- success, failure, denied
    created_at TIMESTAMP DEFAULT NOW()
);

-- Índices para consultas rápidas de auditoria
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_admin_user ON admin_audit_logs (admin_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_admin_email ON admin_audit_logs (admin_email);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_action ON admin_audit_logs (action);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_resource ON admin_audit_logs (resource_type, resource_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_status ON admin_audit_logs (status);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_created ON admin_audit_logs (created_at DESC);

-- Índice composto para filtros combinados (padrão de consulta do painel)
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_combined
    ON admin_audit_logs (created_at DESC, action, resource_type, admin_email);

