-- Migration 005: Add missing database indexes for performance
-- Data: 2024-07-26

-- ===== Users =====
CREATE INDEX IF NOT EXISTS idx_users_email_lower ON users (LOWER(email));
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users (created_at DESC);

-- ===== Profiles =====
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles (user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_user_id_name ON profiles (user_id, name);

-- ===== Subscriptions =====
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions (user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id_created ON subscriptions (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_subscriptions_plan_type ON subscriptions (plan_type);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions (status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_trial_ends ON subscriptions (trial_ends_at) WHERE plan_type = 'Trial';

-- ===== Payments =====
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments (user_id);
CREATE INDEX IF NOT EXISTS idx_payments_user_id_created ON payments (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments (status);
CREATE INDEX IF NOT EXISTS idx_payments_provider ON payments (provider);
CREATE INDEX IF NOT EXISTS idx_payments_payment_id ON payments (payment_id);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments (created_at DESC);

-- ===== Media Content =====
CREATE INDEX IF NOT EXISTS idx_media_content_type ON media_content (content_type);
CREATE INDEX IF NOT EXISTS idx_media_content_genre ON media_content (genre);
CREATE INDEX IF NOT EXISTS idx_media_content_title_trgm ON media_content USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_media_content_release_year ON media_content (release_year DESC);

-- ===== Playback History =====
CREATE INDEX IF NOT EXISTS idx_playback_history_profile_id ON playback_history (profile_id);
CREATE INDEX IF NOT EXISTS idx_playback_history_media_id ON playback_history (media_id);
CREATE INDEX IF NOT EXISTS idx_playback_history_profile_media ON playback_history (profile_id, media_id);

-- ===== Watchlist =====
CREATE INDEX IF NOT EXISTS idx_watchlist_profile_id ON watchlist (profile_id);
CREATE INDEX IF NOT EXISTS idx_watchlist_profile_media ON watchlist (profile_id, media_id);

-- ===== Ratings =====
CREATE INDEX IF NOT EXISTS idx_ratings_profile_id ON ratings (profile_id);
CREATE INDEX IF NOT EXISTS idx_ratings_media_id ON ratings (media_id);
CREATE INDEX IF NOT EXISTS idx_ratings_stars ON ratings (stars DESC);

-- ===== Device Tokens =====
CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON device_tokens (user_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_active ON device_tokens (is_active) WHERE is_active = TRUE;

-- ===== Queue Jobs =====
CREATE INDEX IF NOT EXISTS idx_queue_jobs_status ON queue_jobs (status);
CREATE INDEX IF NOT EXISTS idx_queue_jobs_queue_status ON queue_jobs (queue_name, status);
CREATE INDEX IF NOT EXISTS idx_queue_jobs_created ON queue_jobs (created_at DESC);

-- ===== Seasons & Episodes =====
CREATE INDEX IF NOT EXISTS idx_seasons_media_id ON seasons (media_id);
CREATE INDEX IF NOT EXISTS idx_episodes_season_id ON episodes (season_id);

-- Enable pg_trgm extension for fuzzy text search (if not already enabled)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

