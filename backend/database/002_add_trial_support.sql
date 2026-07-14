-- Migration: Add trial fields to subscriptions table
-- This migration adds support for trial periods

ALTER TABLE subscriptions
ADD COLUMN IF NOT EXISTS plan_type VARCHAR(20) DEFAULT 'Free',
ADD COLUMN IF NOT EXISTS trial_started_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Update renewal_date to use TIMESTAMP WITH TIME ZONE if needed
-- Note: This might be already correct in your schema
