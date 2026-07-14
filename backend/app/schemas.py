from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr


class UserCreate(BaseModel):
    email: EmailStr
    username: Optional[str] = None
    password: str


class UserResponse(BaseModel):
    id: UUID
    email: EmailStr
    username: Optional[str] = None
    is_premium: bool = False

    class Config:
        from_attributes = True


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
    token: str
    new_password: str


class UserLogin(BaseModel):
    username: str
    password: str


class ProfileCreate(BaseModel):
    name: str
    avatar_url: Optional[str] = None
    is_kids: bool = False
    pin_code: Optional[str] = None


class ProfileResponse(BaseModel):
    id: UUID
    name: str
    avatar_url: Optional[str] = None
    is_kids: bool = False
    pin_code: Optional[str] = None

    class Config:
        from_attributes = True


class MediaCreate(BaseModel):
    title: str
    description: str
    content_type: str
    genre: str
    release_year: int
    duration: int
    rating: str
    thumbnail_url: str
    banner_url: str
    trailer_url: str
    video_url: str
    ai_emotions_tags: list[str] = []


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
