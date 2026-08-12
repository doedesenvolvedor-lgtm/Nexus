import uuid

from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, String, Text, JSON, Time
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=False, index=True)
    username = Column(String(100), unique=True, nullable=True, index=True)
    hashed_password = Column(Text, nullable=False)
    is_premium = Column(Boolean, default=False)
    role = Column(String(20), default="user", nullable=False)  # user, moderator, admin
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    profiles = relationship("Profile", back_populates="user", cascade="all, delete-orphan")
    payments = relationship("Payment", back_populates="user", cascade="all, delete-orphan")
    subscriptions = relationship("Subscription", back_populates="user", cascade="all, delete-orphan")


class Profile(Base):
    __tablename__ = "profiles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    name = Column(String(100), nullable=False)
    avatar_url = Column(Text, nullable=True)
    is_kids = Column(Boolean, default=False)
    pin_code = Column(String(4), nullable=True)

    user = relationship("User", back_populates="profiles")
    playback_history = relationship("PlaybackHistory", back_populates="profile", cascade="all, delete-orphan")


class MediaContent(Base):
    __tablename__ = "media_content"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    content_type = Column(String(30), nullable=True)
    genre = Column(String(100), nullable=True)
    release_year = Column(Integer, nullable=True)
    duration = Column(Integer, nullable=True)
    rating = Column(String(10), nullable=True)
    thumbnail_url = Column(Text, nullable=True)
    banner_url = Column(Text, nullable=True)
    trailer_url = Column(Text, nullable=True)
    video_url = Column(Text, nullable=True)
    ai_emotions_tags = Column(String, nullable=True)

    playback_history = relationship("PlaybackHistory", back_populates="media", cascade="all, delete-orphan")
    seasons = relationship("Season", back_populates="media", cascade="all, delete-orphan")
    watchlist_entries = relationship("WatchList", back_populates="media", cascade="all, delete-orphan")
    ratings = relationship("Rating", back_populates="media", cascade="all, delete-orphan")


class Season(Base):
    __tablename__ = "seasons"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    media_id = Column(UUID(as_uuid=True), ForeignKey("media_content.id"), nullable=False)
    season_number = Column(Integer, nullable=False)
    title = Column(String(200), nullable=False)

    media = relationship("MediaContent", back_populates="seasons")
    episodes = relationship("Episode", back_populates="season", cascade="all, delete-orphan")


class Episode(Base):
    __tablename__ = "episodes"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    season_id = Column(UUID(as_uuid=True), ForeignKey("seasons.id"), nullable=False)
    episode_number = Column(Integer, nullable=False)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    duration = Column(Integer, nullable=True)
    thumbnail_url = Column(Text, nullable=True)
    video_url = Column(Text, nullable=True)

    season = relationship("Season", back_populates="episodes")


class PlaybackHistory(Base):
    __tablename__ = "playback_history"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), ForeignKey("profiles.id"), nullable=False)
    media_id = Column(UUID(as_uuid=True), ForeignKey("media_content.id"), nullable=False)
    last_position_seconds = Column(Integer, default=0)
    is_finished = Column(Boolean, default=False)

    profile = relationship("Profile", back_populates="playback_history")
    media = relationship("MediaContent", back_populates="playback_history")


class WatchList(Base):
    __tablename__ = "watchlist"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), ForeignKey("profiles.id"), nullable=False)
    media_id = Column(UUID(as_uuid=True), ForeignKey("media_content.id"), nullable=False)

    profile = relationship("Profile")
    media = relationship("MediaContent", back_populates="watchlist_entries")


class Rating(Base):
    __tablename__ = "ratings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), ForeignKey("profiles.id"), nullable=False)
    media_id = Column(UUID(as_uuid=True), ForeignKey("media_content.id"), nullable=False)
    stars = Column(Integer, nullable=False)
    comment = Column(Text, nullable=True)

    profile = relationship("Profile")
    media = relationship("MediaContent", back_populates="ratings")


class Payment(Base):
    __tablename__ = "payments"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    provider = Column(String(30), nullable=False)  # mercadopago, stripe
    payment_id = Column(String(255), nullable=True)  # ID do pagamento na plataforma
    amount = Column(Float, nullable=False)
    currency = Column(String(10), default="BRL")
    status = Column(String(20), default="pending")  # pending, approved, rejected, refunded
    plan = Column(String(30), nullable=True)  # Basic, Standard, Premium
    transaction_id = Column(String(255), nullable=True)
    metadata_json = Column("metadata", JSON, nullable=True)  # Dados adicionais (payer_email, etc)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="payments")


class Subscription(Base):
    __tablename__ = "subscriptions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    plan = Column(String(30), default="Free")
    plan_type = Column(String(20), default="Free")  # Trial, Free, Premium
    status = Column(String(20), default="active")
    trial_started_at = Column(DateTime(timezone=True), nullable=True)
    trial_ends_at = Column(DateTime(timezone=True), nullable=True)
    renewal_date = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="subscriptions")


class QueueJob(Base):
    __tablename__ = "queue_jobs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    queue_name = Column(String(100), nullable=False, index=True)
    job_type = Column(String(100), nullable=False, index=True)
    status = Column(String(20), nullable=False, default="queued", index=True)
    items_count = Column(Integer, nullable=False, default=0)
    processed_count = Column(Integer, nullable=False, default=0)
    payload = Column(JSON, nullable=True)
    error_message = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    started_at = Column(DateTime(timezone=True), nullable=True)
    finished_at = Column(DateTime(timezone=True), nullable=True)


class DeviceToken(Base):
    __tablename__ = "device_tokens"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    device_token = Column(String(500), nullable=False, unique=True, index=True)
    device_type = Column(String(20), nullable=False)  # ios, android
    device_name = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    last_used_at = Column(DateTime(timezone=True), nullable=True)

    user = relationship("User")


class LiveChannel(Base):
    __tablename__ = "live_channels"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    url = Column(Text, nullable=False)
    logo_url = Column(Text, nullable=True)
    category = Column(String(100), nullable=True)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    source = Column(String(50), default="manual")  # manual, m3u8_import
    m3u8_playlist_id = Column(UUID(as_uuid=True), ForeignKey("m3u8_playlists.id"), nullable=True)
    last_checked_at = Column(DateTime(timezone=True), nullable=True)
    added_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    playlist = relationship("M3U8Playlist", back_populates="channels")


class M3U8Playlist(Base):
    __tablename__ = "m3u8_playlists"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    source_url = Column(Text, nullable=True)
    source_type = Column(String(20), default="url")  # url, file, manual
    status = Column(String(20), default="active")  # active, inactive, error
    total_channels = Column(Integer, default=0)
    valid_channels = Column(Integer, default=0)
    invalid_channels = Column(Integer, default=0)
    last_import_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    channels = relationship("LiveChannel", back_populates="playlist", cascade="all, delete-orphan")


class AdminAuditLog(Base):
    __tablename__ = "admin_audit_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    admin_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True, index=True)
    admin_email = Column(String(255), nullable=True)
    action = Column(String(100), nullable=False, index=True)
    resource_type = Column(String(50), nullable=False)
    resource_id = Column(UUID(as_uuid=True), nullable=True)
    details = Column(JSON, nullable=True)
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(Text, nullable=True)
    status = Column(String(20), default="success")  # success, failure, denied
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    admin = relationship("User")


class ParentalControlSettings(Base):
    """
    Configurações de Controle Parental por perfil.
    """
    __tablename__ = "parental_control_settings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), ForeignKey("profiles.id"), nullable=False, unique=True, index=True)
    # Classificação máxima permitida: LIVRE, 10, 12, 14, 16, 18
    max_rating = Column(String(10), default="18", nullable=False)
    # Tempo máximo de uso diário em minutos (0 = sem limite)
    daily_time_limit_minutes = Column(Integer, default=0, nullable=False)
    # Horários permitidos (formato "HH:MM")
    allowed_start_time = Column(String(5), default="00:00", nullable=False)
    allowed_end_time = Column(String(5), default="23:59", nullable=False)
    # Ocultar completamente o conteúdo +18 da interface
    hide_adult_content = Column(Boolean, default=True, nullable=False)
    # Exigir autenticação (PIN/biometria) para alterar configurações
    locked_by_pin = Column(Boolean, default=True, nullable=False)
    # Biometria habilitada
    biometric_enabled = Column(Boolean, default=False, nullable=False)
    # Re-autenticação após X minutos de inatividade
    require_auth_after_minutes = Column(Integer, default=30, nullable=False)
    # Bloquear canais classificados como adultos automaticamente
    block_adult_channels = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    profile = relationship("Profile")


class ParentalPin(Base):
    """
    PIN do Controle Parental por perfil (armazenado com hash bcrypt).
    """
    __tablename__ = "parental_pins"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), ForeignKey("profiles.id"), nullable=False, unique=True, index=True)
    # Hash bcrypt do PIN (nunca armazenar plaintext)
    pin_hash = Column(Text, nullable=False)
    failed_attempts = Column(Integer, default=0, nullable=False)
    locked_until = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    profile = relationship("Profile")


class BlockedChannel(Base):
    """
    Canal de TV bloqueado para um perfil específico.
    """
    __tablename__ = "blocked_channels"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), ForeignKey("profiles.id"), nullable=False, index=True)
    channel_id = Column(UUID(as_uuid=True), ForeignKey("live_channels.id"), nullable=False)
    # True se bloqueado por regra global (admin / categoria adulta)
    blocked_by_admin = Column(Boolean, default=False, nullable=False)
    reason = Column(String(100), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    profile = relationship("Profile")
    channel = relationship("LiveChannel")


class AccessAttempt(Base):
    """
    Histórico de tentativas de acesso a conteúdo bloqueado/liberado.
    """
    __tablename__ = "access_attempts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), ForeignKey("profiles.id"), nullable=False, index=True)
    content_type = Column(String(30), nullable=False)  # movie, series, channel, category
    target_id = Column(UUID(as_uuid=True), nullable=True)
    target_title = Column(String(255), nullable=True)
    action = Column(String(20), nullable=False)  # granted, blocked_pin, blocked_rating, blocked_time, blocked_channel
    detail = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    profile = relationship("Profile")


class ContentRating(Base):
    """
    Classificação indicativa de conteúdo (admin global).
    """
    __tablename__ = "content_ratings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    content_type = Column(String(20), nullable=False)  # media, channel, category
    content_id = Column(UUID(as_uuid=True), nullable=True)
    category = Column(String(100), nullable=True)
    rating = Column(String(10), nullable=False)  # LIVRE, 10, 12, 14, 16, 18
    is_adult = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    admin = relationship("User", primaryjoin="ContentRating.id == User.id", viewonly=True)
