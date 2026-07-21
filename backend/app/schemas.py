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
    token_type: str = "bearer"


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
    stars: int
    comment: Optional[str] = None


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
