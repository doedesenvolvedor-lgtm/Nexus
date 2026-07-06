import uuid

from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, String, Text
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
    provider = Column(String(30), nullable=False)
    amount = Column(Float, nullable=False)
    currency = Column(String(10), default="BRL")
    status = Column(String(20), default="pending")
    transaction_id = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="payments")


class Subscription(Base):
    __tablename__ = "subscriptions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    plan = Column(String(30), default="Free")
    status = Column(String(20), default="active")
    renewal_date = Column(DateTime, nullable=True)

    user = relationship("User", back_populates="subscriptions")
