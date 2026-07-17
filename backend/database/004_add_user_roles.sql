-- Migration: Add admin roles support
-- Date: 2026-07-17
-- Description: Adiciona suporte a roles (user, moderator, admin) na tabela users

BEGIN;

-- Adiciona coluna role à tabela users com default 'user'
ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user' NOT NULL;

-- Cria índice para queries rápidas por role
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- Define alguns usuários admin (substitua pelo seu email real)
-- UPDATE users SET role = 'admin' WHERE email IN ('seu-email-admin@example.com');

-- Valida integridade
ALTER TABLE users ADD CONSTRAINT check_valid_role 
CHECK (role IN ('user', 'moderator', 'admin')) NOT VALID;

-- Valida constraint (aceita violações já existentes)
ALTER TABLE users VALIDATE CONSTRAINT check_valid_role;

COMMIT;
