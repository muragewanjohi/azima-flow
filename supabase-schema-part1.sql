-- SaaS Database Schema for Azima.Store - Part 1
-- This script creates the basic structure and core tables

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create custom types
CREATE TYPE tenant_status AS ENUM ('provisioning', 'active', 'suspended', 'error', 'deleted');
CREATE TYPE plan_tier AS ENUM ('free', 'starter', 'pro', 'growth', 'scale', 'enterprise');
CREATE TYPE subscription_status AS ENUM ('trial', 'active', 'past_due', 'canceled', 'unpaid');
CREATE TYPE user_role AS ENUM ('owner', 'admin', 'staff', 'viewer');

-- =============================================
-- CORE TABLES
-- =============================================

-- Plans table - Subscription plans (must be created first due to foreign key references)
CREATE TABLE plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    tier plan_tier NOT NULL,
    price_monthly INTEGER NOT NULL, -- Price in cents
    price_yearly INTEGER NOT NULL, -- Price in cents
    features JSONB DEFAULT '{}',
    limits JSONB NOT NULL DEFAULT '{}', -- Store limits, product limits, etc.
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Subscriptions table - Active subscriptions
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID, -- Will be updated after tenants table is created
    plan_id UUID NOT NULL REFERENCES plans(id),
    status subscription_status DEFAULT 'trial',
    stripe_customer_id VARCHAR(255),
    stripe_subscription_id VARCHAR(255),
    current_period_start TIMESTAMP WITH TIME ZONE,
    current_period_end TIMESTAMP WITH TIME ZONE,
    trial_start TIMESTAMP WITH TIME ZONE,
    trial_end TIMESTAMP WITH TIME ZONE,
    canceled_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tenants table - Core tenant information
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    subdomain VARCHAR(100) UNIQUE NOT NULL,
    status tenant_status DEFAULT 'provisioning',
    plan_id UUID REFERENCES plans(id),
    subscription_id UUID REFERENCES subscriptions(id),
    medusa_region_id VARCHAR(50), -- Maps to Medusa region
    medusa_admin_user_id VARCHAR(50), -- Maps to Medusa admin user
    custom_domain VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Users table - SaaS platform users (not Medusa users)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    avatar_url TEXT,
    email_verified BOOLEAN DEFAULT FALSE,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tenant users - Junction table for tenant-user relationships
CREATE TABLE tenant_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role user_role DEFAULT 'staff',
    permissions JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tenant_id, user_id)
);

-- Plan entitlements - What each plan includes
CREATE TABLE plan_entitlements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id UUID NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
    feature_key VARCHAR(100) NOT NULL,
    limit_value INTEGER,
    is_unlimited BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(plan_id, feature_key)
);
