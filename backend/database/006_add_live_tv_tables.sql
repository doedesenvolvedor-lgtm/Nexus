-- Migration 006: Add Live TV and M3U8 Playlist tables
-- Data: 2026-07-26

-- ===== M3U8 Playlists =====
CREATE TABLE IF NOT EXISTS m3u8_playlists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    source_url TEXT,
    source_type VARCHAR(20) DEFAULT 'url',  -- url, file, manual
    status VARCHAR(20) DEFAULT 'active',    -- active, inactive, error
    total_channels INTEGER DEFAULT 0,
    valid_channels INTEGER DEFAULT 0,
    invalid_channels INTEGER DEFAULT 0,
    last_import_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_m3u8_playlists_status ON m3u8_playlists (status);
CREATE INDEX IF NOT EXISTS idx_m3u8_playlists_created ON m3u8_playlists (created_at DESC);

-- ===== Live Channels =====
CREATE TABLE IF NOT EXISTS live_channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    url TEXT NOT NULL,
    logo_url TEXT,
    category VARCHAR(100),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    source VARCHAR(50) DEFAULT 'manual',    -- manual, m3u8_import
    m3u8_playlist_id UUID REFERENCES m3u8_playlists(id) ON DELETE SET NULL,
    last_checked_at TIMESTAMP,
    added_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_live_channels_active ON live_channels (is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_live_channels_category ON live_channels (category);
CREATE INDEX IF NOT EXISTS idx_live_channels_source ON live_channels (source);
CREATE INDEX IF NOT EXISTS idx_live_channels_playlist ON live_channels (m3u8_playlist_id);

