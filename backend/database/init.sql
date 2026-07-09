CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE,
    hashed_password TEXT NOT NULL,
    is_premium BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    is_kids BOOLEAN DEFAULT FALSE,
    pin_code VARCHAR(4)
);

CREATE TABLE IF NOT EXISTS media_content (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    content_type VARCHAR(50) NOT NULL,
    release_year INTEGER,
    rating VARCHAR(10),
    thumbnail_url TEXT,
    video_url TEXT
);

CREATE TABLE IF NOT EXISTS playback_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    media_id UUID REFERENCES media_content(id) ON DELETE CASCADE,
    last_position_seconds INTEGER DEFAULT 0,
    is_finished BOOLEAN DEFAULT FALSE
);
