"""initial schema

Revision ID: 001
Revises: 
Create Date: 2025-01-01

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '001'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Users table
    op.create_table(
        'users',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('email', sa.String(255), unique=True, nullable=False, index=True),
        sa.Column('username', sa.String(100), unique=True, nullable=True, index=True),
        sa.Column('hashed_password', sa.Text(), nullable=False),
        sa.Column('is_premium', sa.Boolean(), server_default=sa.text('false')),
        sa.Column('role', sa.String(20), server_default=sa.text("'user'"), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
    )

    # Profiles table
    op.create_table(
        'profiles',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('avatar_url', sa.Text(), nullable=True),
        sa.Column('is_kids', sa.Boolean(), server_default=sa.text('false')),
        sa.Column('pin_code', sa.String(4), nullable=True),
    )

    # Media Content table
    op.create_table(
        'media_content',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('title', sa.String(255), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('content_type', sa.String(30), nullable=True),
        sa.Column('genre', sa.String(100), nullable=True),
        sa.Column('release_year', sa.Integer(), nullable=True),
        sa.Column('duration', sa.Integer(), nullable=True),
        sa.Column('rating', sa.String(10), nullable=True),
        sa.Column('thumbnail_url', sa.Text(), nullable=True),
        sa.Column('banner_url', sa.Text(), nullable=True),
        sa.Column('trailer_url', sa.Text(), nullable=True),
        sa.Column('video_url', sa.Text(), nullable=True),
        sa.Column('ai_emotions_tags', sa.String(), nullable=True),
    )

    # Seasons table
    op.create_table(
        'seasons',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('media_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('media_content.id'), nullable=False),
        sa.Column('season_number', sa.Integer(), nullable=False),
        sa.Column('title', sa.String(200), nullable=False),
    )

    # Episodes table
    op.create_table(
        'episodes',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('season_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('seasons.id'), nullable=False),
        sa.Column('episode_number', sa.Integer(), nullable=False),
        sa.Column('title', sa.String(200), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('duration', sa.Integer(), nullable=True),
        sa.Column('thumbnail_url', sa.Text(), nullable=True),
        sa.Column('video_url', sa.Text(), nullable=True),
    )

    # Playback History table
    op.create_table(
        'playback_history',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('profile_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('profiles.id'), nullable=False),
        sa.Column('media_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('media_content.id'), nullable=False),
        sa.Column('last_position_seconds', sa.Integer(), server_default=sa.text('0')),
        sa.Column('is_finished', sa.Boolean(), server_default=sa.text('false')),
    )

    # Watchlist table
    op.create_table(
        'watchlist',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('profile_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('profiles.id'), nullable=False),
        sa.Column('media_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('media_content.id'), nullable=False),
    )

    # Ratings table
    op.create_table(
        'ratings',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('profile_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('profiles.id'), nullable=False),
        sa.Column('media_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('media_content.id'), nullable=False),
        sa.Column('stars', sa.Integer(), nullable=False),
        sa.Column('comment', sa.Text(), nullable=True),
    )

    # Payments table
    op.create_table(
        'payments',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('provider', sa.String(30), nullable=False),
        sa.Column('payment_id', sa.String(255), nullable=True),
        sa.Column('amount', sa.Float(), nullable=False),
        sa.Column('currency', sa.String(10), server_default=sa.text("'BRL'")),
        sa.Column('status', sa.String(20), server_default=sa.text("'pending'")),
        sa.Column('plan', sa.String(30), nullable=True),
        sa.Column('transaction_id', sa.String(255), nullable=True),
        sa.Column('metadata', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
    )

    # Subscriptions table
    op.create_table(
        'subscriptions',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('plan', sa.String(30), server_default=sa.text("'Free'")),
        sa.Column('plan_type', sa.String(20), server_default=sa.text("'Free'")),
        sa.Column('status', sa.String(20), server_default=sa.text("'active'")),
        sa.Column('trial_started_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('trial_ends_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('renewal_date', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
    )

    # Queue Jobs table
    op.create_table(
        'queue_jobs',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('queue_name', sa.String(100), nullable=False, index=True),
        sa.Column('job_type', sa.String(100), nullable=False, index=True),
        sa.Column('status', sa.String(20), nullable=False, server_default=sa.text("'queued'"), index=True),
        sa.Column('items_count', sa.Integer(), nullable=False, server_default=sa.text('0')),
        sa.Column('processed_count', sa.Integer(), nullable=False, server_default=sa.text('0')),
        sa.Column('payload', sa.JSON(), nullable=True),
        sa.Column('error_message', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
        sa.Column('started_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('finished_at', sa.DateTime(timezone=True), nullable=True),
    )

    # Device Tokens table
    op.create_table(
        'device_tokens',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id'), nullable=False, index=True),
        sa.Column('device_token', sa.String(500), nullable=False, unique=True, index=True),
        sa.Column('device_type', sa.String(20), nullable=False),
        sa.Column('device_name', sa.String(255), nullable=True),
        sa.Column('is_active', sa.Boolean(), server_default=sa.text('true')),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
        sa.Column('last_used_at', sa.DateTime(timezone=True), nullable=True),
    )

    # Create indexes from SQL migration files
    op.create_index('idx_users_role', 'users', ['role'])
    op.create_index('idx_queue_jobs_status', 'queue_jobs', ['status'])
    op.create_index('idx_queue_jobs_queue', 'queue_jobs', ['queue_name'])
    op.create_index('idx_queue_jobs_type', 'queue_jobs', ['job_type'])
    op.create_index('idx_device_tokens_user', 'device_tokens', ['user_id'])
    op.create_index('idx_device_tokens_token', 'device_tokens', ['device_token'])


def downgrade() -> None:
    op.drop_table('device_tokens')
    op.drop_table('queue_jobs')
    op.drop_table('subscriptions')
    op.drop_table('payments')
    op.drop_table('ratings')
    op.drop_table('watchlist')
    op.drop_table('playback_history')
    op.drop_table('episodes')
    op.drop_table('seasons')
    op.drop_table('media_content')
    op.drop_table('profiles')
    op.drop_table('users')
