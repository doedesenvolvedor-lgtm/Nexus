
from datetime import datetime
from typing import Optional
from uuid import UUID
from re import match

from pydantic import BaseModel, EmailStr, Field, field_validator


# Validator para força de senha
def validate_password_strength(password: str) -> str:
    """
    Valida senha forte:
    - Mínimo 12 caracteres
    - Pelo menos 1 letra maiúscula
    - Pelo menos 1 letra minúscula
    - Pelo menos 1 dígito
    - Pelo menos 1 caractere especial
    """
    if len(password) < 12:
        raise ValueError("Senha deve ter no mínimo 12 caracteres")
    
    if not match(r'^(?=.*[A-Z])', password):
        raise ValueError("Senha deve conter pelo menos 1 letra maiúscula")
    
    if not match(r'^(?=.*[a-z])', password):
        raise ValueError("Senha deve conter pelo menos 1 letra minúscula")
    
    if not match(r'^(?=.*\d)', password):
        raise ValueError("Senha deve conter pelo menos 1 dígito")
    
    if not match(r'^(?=.*[@$!%*?&])', password):
        raise ValueError("Senha deve conter pelo menos 1 caractere especial (@$!%*?&)")
    
    return password


class UserCreate(BaseModel):
    email: EmailStr
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    password: str = Field(min_length=12, description="Senha forte: maiúscula, minúscula, dígito, especial")
    
    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        return validate_password_strength(v)
    
    @field_validator("username")
    @classmethod
    def validate_username(cls, v: Optional[str]) -> Optional[str]:
        if v and not match(r'^[a-zA-Z0-9_-]+$', v):
            raise ValueError("Username pode conter apenas letras, números, hífen e underline")
        return v


class UserResponse(BaseModel):
    id: UUID
    email: EmailStr
    username: Optional[str] = None
    is_premium: bool = False

    class Config:
        from_attributes = True


class AdminUserResponse(BaseModel):
    id: UUID
    email: EmailStr
    username: Optional[str] = None
    is_premium: bool = False
    role: str
    created_at: datetime
    plan: str = "free"
    status: str = "inactive"


class PaginatedAdminUsersResponse(BaseModel):
    data: list[AdminUserResponse]
    total: int
    page: int
    limit: int


class UserDetailResponse(BaseModel):
    id: UUID
    email: EmailStr
    username: Optional[str] = None
    is_premium: bool = False
    subscription: Optional["SubscriptionResponse"] = None

    class Config:
        from_attributes = True


class Login(BaseModel):
    email: EmailStr
    password: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    token: str = Field(..., min_length=10)
    new_password: str = Field(min_length=12, description="Senha forte: maiúscula, minúscula, dígito, especial")
    
    @field_validator("new_password")
    @classmethod
    def validate_new_password(cls, v: str) -> str:
        return validate_password_strength(v)


class UserLogin(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=8)


class ProfileCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    avatar_url: Optional[str] = Field(None, max_length=500)
    is_kids: bool = False
    pin_code: Optional[str] = Field(None, pattern=r'^\d{4}$')  # 4 dígitos


class ProfileResponse(BaseModel):
    id: UUID
    name: str
    avatar_url: Optional[str] = None
    is_kids: bool = False
    pin_code: Optional[str] = None

    class Config:
        from_attributes = True


class MediaCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    description: str = Field(..., min_length=10, max_length=2000)
    content_type: str = Field(..., pattern=r'^(movie|series|documentary|special)$')
    genre: str = Field(..., min_length=2, max_length=50)
    release_year: int = Field(..., ge=1900, le=2100)
    duration: int = Field(..., gt=0, le=14400)  # até 4 horas em segundos
    rating: str = Field(..., pattern=r'^(G|PG|PG-13|R|NC-17|L| 10|12|14|16|18)$')
    thumbnail_url: str = Field(..., max_length=500)
    banner_url: str = Field(..., max_length=500)
    trailer_url: Optional[str] = Field(None, max_length=500)
    video_url: str = Field(..., max_length=500)
    ai_emotions_tags: list[str] = Field(default_factory=list, max_items=10)

    @field_validator("thumbnail_url", "banner_url", "trailer_url", "video_url")
    @classmethod
    def validate_url_fields(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return value
        trimmed = value.strip()
        if not trimmed:
            return trimmed
        if trimmed.startswith("/"):
            return trimmed
        if not match(r"^https?://", trimmed):
            raise ValueError("URL deve ser absoluta (http/https) ou caminho relativo iniciado por /")
        return trimmed

    @field_validator("ai_emotions_tags")
    @classmethod
    def normalize_ai_tags(cls, value: list[str]) -> list[str]:
        normalized = []
        for item in value:
            tag = item.strip().lower()
            if tag and tag not in normalized:
                normalized.append(tag)
        return normalized


class MediaResponse(BaseModel):
    id: UUID
    title: str
    description: Optional[str] = None
    content_type: Optional[str] = None
    genre: Optional[str] = None
    release_year: Optional[int] = None
    duration: Optional[int] = None
    rating: Optional[str] = None
    thumbnail_url: Optional[str] = None
    banner_url: Optional[str] = None
    trailer_url: Optional[str] = None
    video_url: Optional[str] = None
    ai_emotions_tags: Optional[list[str]] = None

    @field_validator("ai_emotions_tags", mode="before")
    @classmethod
    def parse_ai_emotions_tags(cls, value):
        if value is None:
            return None
        if isinstance(value, list):
            return value
        if isinstance(value, str):
            return [item.strip() for item in value.split(",") if item.strip()]
        return value

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    refresh_token: str = ""
    token_type: str = "bearer"

    @field_validator("refresh_token", mode="before")
    @classmethod
    def ensure_refresh_token(cls, v):
        """Garante que refresh_token nunca seja None."""
        return v or ""


class RefreshTokenRequest(BaseModel):
    refresh_token: str = Field(..., min_length=10, description="Refresh token JWT")


class SeasonCreate(BaseModel):
    media_id: UUID
    season_number: int
    title: str


class SeasonResponse(BaseModel):
    id: UUID
    media_id: UUID
    season_number: int
    title: str

    class Config:
        from_attributes = True


class EpisodeCreate(BaseModel):
    season_id: UUID
    episode_number: int
    title: str
    description: Optional[str] = None
    duration: Optional[int] = None
    thumbnail_url: Optional[str] = None
    video_url: Optional[str] = None


class EpisodeResponse(BaseModel):
    id: UUID
    season_id: UUID
    episode_number: int
    title: str
    description: Optional[str] = None
    duration: Optional[int] = None
    thumbnail_url: Optional[str] = None
    video_url: Optional[str] = None

    class Config:
        from_attributes = True


class RatingCreate(BaseModel):
    profile_id: UUID
    media_id: UUID
    stars: int = Field(..., ge=1, le=5, description="Avaliação de 1 a 5 estrelas")
    comment: Optional[str] = Field(None, max_length=500)


class RatingResponse(BaseModel):
    id: UUID
    profile_id: UUID
    media_id: UUID
    stars: int
    comment: Optional[str] = None

    class Config:
        from_attributes = True


class WatchListCreate(BaseModel):
    profile_id: UUID
    media_id: UUID


class WatchListResponse(BaseModel):
    id: UUID
    profile_id: UUID
    media_id: UUID

    class Config:
        from_attributes = True


class PlaybackHistoryCreate(BaseModel):
    profile_id: UUID
    media_id: UUID
    last_position_seconds: Optional[int] = 0
    is_finished: bool = False


class PlaybackHistoryResponse(BaseModel):
    id: UUID
    profile_id: UUID
    media_id: UUID
    last_position_seconds: int = 0
    is_finished: bool = False

    class Config:
        from_attributes = True


class SubscriptionCreate(BaseModel):
    user_id: UUID
    plan: str = "Free"
    plan_type: str = "Free"
    status: str = "active"
    trial_started_at: Optional[datetime] = None
    trial_ends_at: Optional[datetime] = None
    renewal_date: Optional[datetime] = None


class SubscriptionResponse(BaseModel):
    id: UUID
    user_id: UUID
    plan: str
    plan_type: str
    status: str
    trial_started_at: Optional[datetime] = None
    trial_ends_at: Optional[datetime] = None
    renewal_date: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class TrialStatusResponse(BaseModel):
    is_trial: bool
    days_remaining: int
    trial_ends_at: Optional[datetime] = None
    plan_type: str

    class Config:
        from_attributes = True


class PaymentCreate(BaseModel):
    user_id: UUID
    provider: str
    amount: float
    currency: str = "BRL"
    status: str = "pending"
    transaction_id: Optional[str] = None


class PaymentResponse(BaseModel):
    id: UUID
    user_id: UUID
    provider: str
    amount: float
    currency: str
    status: str
    transaction_id: Optional[str] = None

    class Config:
        from_attributes = True


class AdminEmailAnnouncementRequest(BaseModel):
    title: str
    message: str


# ===== Live TV / Channels =====

class LiveChannelCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    url: str = Field(..., min_length=5, max_length=2000)
    logo_url: Optional[str] = Field(None, max_length=500)
    category: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = Field(None, max_length=1000)
    is_active: bool = True
    is_verified: bool = False


class LiveChannelUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    url: Optional[str] = Field(None, min_length=5, max_length=2000)
    logo_url: Optional[str] = Field(None, max_length=500)
    category: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = Field(None, max_length=1000)
    is_active: Optional[bool] = None


class LiveChannelResponse(BaseModel):
    id: UUID
    name: str
    url: str
    logo_url: Optional[str] = None
    category: Optional[str] = None
    description: Optional[str] = None
    is_active: bool = True
    is_verified: bool = False
    source: str = "manual"
    last_checked_at: Optional[datetime] = None
    added_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class M3U8PlaylistCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    source_url: Optional[str] = Field(None, max_length=2000)
    source_type: str = Field(default="url", pattern=r"^(url|file|manual)$")


class M3U8PlaylistResponse(BaseModel):
    id: UUID
    name: str
    source_url: Optional[str] = None
    source_type: str = "url"
    status: str = "active"
    total_channels: int = 0
    valid_channels: int = 0
    invalid_channels: int = 0
    last_import_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ===== Admin Audit Logs =====

class AdminAuditLogResponse(BaseModel):
    id: UUID
    admin_user_id: Optional[UUID] = None
    admin_email: Optional[str] = None
    action: str
    resource_type: str
    resource_id: Optional[UUID] = None
    details: Optional[dict] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    status: str = "success"
    created_at: datetime

    class Config:
        from_attributes = True


# ===== System Monitoring =====

class SystemStorageResponse(BaseModel):
    total_bytes: int
    used_bytes: int
    free_bytes: int
    used_percent: float
    storage_paths: dict


class SystemStatusResponse(BaseModel):
    cpu_percent: float
    memory_total_bytes: int
    memory_used_bytes: int
    memory_percent: float
    disk_total_bytes: int
    disk_used_bytes: int
    disk_percent: float
    uptime_seconds: float
    python_version: str


class ReleaseInfoResponse(BaseModel):
    name: str
    size_mb: float
    download_url: str
    date: str
    type: str = "APK Release"


# ===== Content Maintenance =====

class MaintenanceCheckResponse(BaseModel):
    total_media: int
    checked: int
    invalid_links: int
    fixed: int
    errors: list[dict]


class TMDbImportResponse(BaseModel):
    success: bool
    message: str
    media_id: Optional[str] = None


# ===== Controle Parental =====

class ParentalSettingsUpdate(BaseModel):
    max_rating: Optional[str] = Field(None, pattern=r'^(LIVRE|10|12|14|16|18)$')  # Classificação máxima
    daily_time_limit_minutes: Optional[int] = Field(None, ge=0, le=1440)  # 0 = sem limite
    allowed_start_time: Optional[str] = Field(None, pattern=r'^([01]\d|2[0-3]):[0-5]\d$')  # HH:MM
    allowed_end_time: Optional[str] = Field(None, pattern=r'^([01]\d|2[0-3]):[0-5]\d$')  # HH:MM
    hide_adult_content: Optional[bool] = None
    locked_by_pin: Optional[bool] = None
    biometric_enabled: Optional[bool] = None
    require_auth_after_minutes: Optional[int] = Field(None, ge=1, le=1440)
    block_adult_channels: Optional[bool] = None


class ParentalSettingsResponse(BaseModel):
    profile_id: UUID
    max_rating: str = "18"
    daily_time_limit_minutes: int = 0
    allowed_start_time: str = "00:00"
    allowed_end_time: str = "23:59"
    hide_adult_content: bool = True
    locked_by_pin: bool = True
    biometric_enabled: bool = False
    require_auth_after_minutes: int = 30
    block_adult_channels: bool = True
    has_pin: bool = False

    class Config:
        from_attributes = True


class PinSetRequest(BaseModel):
    pin: str = Field(..., min_length=4, max_length=8, pattern=r'^\d{4,8}$')  # 4 a 8 dígitos


class PinVerifyRequest(BaseModel):
    pin: str = Field(..., min_length=4, max_length=8, pattern=r'^\d{4,8}$')  # 4 a 8 dígitos


class BlockedChannelCreate(BaseModel):
    channel_id: UUID
    reason: Optional[str] = Field(None, max_length=100)


class BlockedChannelResponse(BaseModel):
    id: UUID
    profile_id: UUID
    channel_id: UUID
    blocked_by_admin: bool = False
    reason: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class AccessAttemptResponse(BaseModel):
    id: UUID
    profile_id: UUID
    content_type: str
    target_id: Optional[UUID] = None
    target_title: Optional[str] = None
    action: str
    detail: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class AccessCheckRequest(BaseModel):
    profile_id: UUID
    content_type: str = Field(..., pattern=r'^(movie|series|channel|category)$')
    target_id: Optional[UUID] = None
    rating: Optional[str] = None
    title: Optional[str] = Field(None, max_length=255)


class AccessCheckResponse(BaseModel):
    allowed: bool
    requires_pin: bool = False
    reason: Optional[str] = None
    message: Optional[str] = None


class ContentRatingSet(BaseModel):
    content_type: str = Field(..., pattern=r'^(media|channel|category)$')
    content_id: Optional[UUID] = None
    category: Optional[str] = Field(None, max_length=100)
    rating: str = Field(..., pattern=r'^(LIVRE|10|12|14|16|18)$')
    is_adult: bool = False


class ContentRatingResponse(BaseModel):
    id: UUID
    content_type: str
    content_id: Optional[UUID] = None
    category: Optional[str] = None
    rating: str
    is_adult: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
