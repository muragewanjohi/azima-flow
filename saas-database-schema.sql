-- ============================================================================
-- Azima.Store SaaS Database Schema
-- ============================================================================
-- Purpose: Multi-tenant SaaS platform management
-- Project: azima-store-saas (Supabase)
-- Security: RLS enabled for tenant isolation
-- ============================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- CLEANUP (Optional - uncomment if you need to reset)
-- ============================================================================

-- Uncomment the following lines if you need to drop existing schema
-- WARNING: This will DELETE ALL DATA!

/*
DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS api_keys CASCADE;
DROP TABLE IF EXISTS webhooks CASCADE;
DROP TABLE IF EXISTS domains CASCADE;
DROP TABLE IF EXISTS usage_counters CASCADE;
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS tenants CASCADE;
DROP TABLE IF EXISTS plans CASCADE;

DROP FUNCTION IF EXISTS get_current_usage(UUID);
DROP FUNCTION IF EXISTS user_owns_tenant(UUID);
DROP FUNCTION IF EXISTS get_user_tenant_id();
DROP FUNCTION IF EXISTS update_updated_at_column();

DROP TYPE IF EXISTS webhook_event_type;
DROP TYPE IF EXISTS domain_status;
DROP TYPE IF EXISTS subscription_status;
DROP TYPE IF EXISTS plan_tier;
DROP TYPE IF EXISTS tenant_status;
*/

-- ============================================================================
-- ENUMS
-- ============================================================================

DO $$ BEGIN
  CREATE TYPE tenant_status AS ENUM (
    'provisioning',
    'active',
    'suspended',
    'error',
    'deleted'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE plan_tier AS ENUM (
    'free',
    'starter',
    'pro',
    'growth',
    'scale',
    'enterprise'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE subscription_status AS ENUM (
    'trialing',
    'active',
    'past_due',
    'canceled',
    'unpaid'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE domain_status AS ENUM (
    'pending_verification',
    'verified',
    'active',
    'failed',
    'inactive'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE webhook_event_type AS ENUM (
    'orders.created',
    'orders.paid',
    'orders.fulfilled',
    'orders.canceled',
    'products.created',
    'products.updated',
    'products.deleted',
    'themes.published',
    'subscription.updated',
    'subscription.canceled'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- ============================================================================
-- TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Plans Table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(50) NOT NULL,
  tier plan_tier NOT NULL UNIQUE,
  description TEXT,
  
  -- Pricing
  monthly_price_cents INTEGER NOT NULL DEFAULT 0,
  annual_price_cents INTEGER NOT NULL DEFAULT 0,
  
  -- Limits
  max_stores INTEGER NOT NULL DEFAULT 1,
  max_products INTEGER NOT NULL DEFAULT 100,
  max_orders_per_month INTEGER NOT NULL DEFAULT 100,
  max_custom_domains INTEGER NOT NULL DEFAULT 0,
  max_staff_accounts INTEGER NOT NULL DEFAULT 1,
  max_asset_storage_gb INTEGER NOT NULL DEFAULT 1,
  
  -- Features
  features JSONB DEFAULT '[]'::jsonb,
  
  -- Overages
  overage_order_price_cents INTEGER DEFAULT 0,
  
  -- Metadata
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- Tenants Table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tenants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Identity
  business_name VARCHAR(255) NOT NULL,
  subdomain VARCHAR(63) NOT NULL UNIQUE,
  slug VARCHAR(63) NOT NULL UNIQUE,
  
  -- Owner (links to Supabase auth.users)
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Medusa Integration
  medusa_region_id VARCHAR(255),
  medusa_sales_channel_id VARCHAR(255),
  medusa_stock_location_id VARCHAR(255),
  medusa_admin_user_id VARCHAR(255),
  
  -- Status
  status tenant_status NOT NULL DEFAULT 'provisioning',
  
  -- Configuration
  settings JSONB DEFAULT '{}'::jsonb,
  metadata JSONB DEFAULT '{}'::jsonb,
  
  -- Timestamps
  provisioned_at TIMESTAMPTZ,
  last_active_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  
  -- Constraints
  CONSTRAINT valid_subdomain CHECK (subdomain ~* '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'),
  CONSTRAINT valid_slug CHECK (slug ~* '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$')
);

-- ----------------------------------------------------------------------------
-- Subscriptions Table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Relationships
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  plan_id UUID NOT NULL REFERENCES plans(id),
  
  -- Stripe Integration
  stripe_subscription_id VARCHAR(255) UNIQUE,
  stripe_customer_id VARCHAR(255),
  
  -- Status
  status subscription_status NOT NULL DEFAULT 'trialing',
  
  -- Billing Period
  current_period_start TIMESTAMPTZ NOT NULL,
  current_period_end TIMESTAMPTZ NOT NULL,
  
  -- Trial
  trial_start TIMESTAMPTZ,
  trial_end TIMESTAMPTZ,
  
  -- Cancellation
  cancel_at_period_end BOOLEAN DEFAULT false,
  canceled_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(tenant_id, plan_id)
);

-- ----------------------------------------------------------------------------
-- Usage Counters Table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS usage_counters (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Relationships
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
  
  -- Period
  period_start TIMESTAMPTZ NOT NULL,
  period_end TIMESTAMPTZ NOT NULL,
  
  -- Counters
  orders_count INTEGER DEFAULT 0,
  products_count INTEGER DEFAULT 0,
  asset_storage_bytes BIGINT DEFAULT 0,
  bandwidth_bytes BIGINT DEFAULT 0,
  api_calls_count INTEGER DEFAULT 0,
  
  -- Metadata
  metadata JSONB DEFAULT '{}'::jsonb,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(tenant_id, period_start),
  CONSTRAINT valid_period CHECK (period_end > period_start)
);

-- ----------------------------------------------------------------------------
-- Domains Table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS domains (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Relationships
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Domain Info
  domain VARCHAR(255) NOT NULL UNIQUE,
  is_primary BOOLEAN DEFAULT false,
  
  -- Status
  status domain_status NOT NULL DEFAULT 'pending_verification',
  
  -- Verification
  verification_token VARCHAR(255),
  verified_at TIMESTAMPTZ,
  
  -- SSL/TLS
  ssl_enabled BOOLEAN DEFAULT false,
  ssl_issued_at TIMESTAMPTZ,
  
  -- Configuration
  redirect_to_primary BOOLEAN DEFAULT false,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_domain CHECK (domain ~* '^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*$')
);

-- ----------------------------------------------------------------------------
-- Webhooks Table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS webhooks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Relationships
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Webhook Config
  url TEXT NOT NULL,
  events webhook_event_type[] NOT NULL,
  
  -- Security
  secret VARCHAR(255) NOT NULL DEFAULT encode(gen_random_bytes(32), 'hex'),
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  -- Retry Configuration
  max_retries INTEGER DEFAULT 3,
  retry_count INTEGER DEFAULT 0,
  last_success_at TIMESTAMPTZ,
  last_failure_at TIMESTAMPTZ,
  last_error TEXT,
  
  -- Metadata
  description TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- API Keys Table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS api_keys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Relationships
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  
  -- Key Info
  name VARCHAR(255) NOT NULL,
  key_prefix VARCHAR(20) NOT NULL,
  key_hash VARCHAR(255) NOT NULL UNIQUE,
  
  -- Permissions
  scopes TEXT[] DEFAULT ARRAY['read']::TEXT[],
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  -- Usage
  last_used_at TIMESTAMPTZ,
  usage_count INTEGER DEFAULT 0,
  
  -- Expiration
  expires_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  revoked_at TIMESTAMPTZ
);

-- ----------------------------------------------------------------------------
-- Events Table (Audit Log)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Relationships
  tenant_id UUID REFERENCES tenants(id) ON DELETE SET NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  
  -- Event Info
  event_type VARCHAR(100) NOT NULL,
  event_category VARCHAR(50) NOT NULL,
  
  -- Details
  resource_type VARCHAR(50),
  resource_id VARCHAR(255),
  
  -- Data
  payload JSONB DEFAULT '{}'::jsonb,
  
  -- Context
  ip_address INET,
  user_agent TEXT,
  
  -- Timestamp
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Tenants
CREATE INDEX IF NOT EXISTS idx_tenants_owner_id ON tenants(owner_id);
CREATE INDEX IF NOT EXISTS idx_tenants_status ON tenants(status);
CREATE INDEX IF NOT EXISTS idx_tenants_subdomain ON tenants(subdomain);
CREATE INDEX IF NOT EXISTS idx_tenants_medusa_region_id ON tenants(medusa_region_id);

-- Subscriptions
CREATE INDEX IF NOT EXISTS idx_subscriptions_tenant_id ON subscriptions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_plan_id ON subscriptions(plan_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe_customer_id ON subscriptions(stripe_customer_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_period_end ON subscriptions(current_period_end);

-- Usage Counters
CREATE INDEX IF NOT EXISTS idx_usage_counters_tenant_id ON usage_counters(tenant_id);
CREATE INDEX IF NOT EXISTS idx_usage_counters_period ON usage_counters(period_start, period_end);

-- Domains
CREATE INDEX IF NOT EXISTS idx_domains_tenant_id ON domains(tenant_id);
CREATE INDEX IF NOT EXISTS idx_domains_domain ON domains(domain);
CREATE INDEX IF NOT EXISTS idx_domains_status ON domains(status);

-- Webhooks
CREATE INDEX IF NOT EXISTS idx_webhooks_tenant_id ON webhooks(tenant_id);
CREATE INDEX IF NOT EXISTS idx_webhooks_is_active ON webhooks(is_active);

-- API Keys
CREATE INDEX IF NOT EXISTS idx_api_keys_tenant_id ON api_keys(tenant_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_key_hash ON api_keys(key_hash);
CREATE INDEX IF NOT EXISTS idx_api_keys_is_active ON api_keys(is_active);

-- Events
CREATE INDEX IF NOT EXISTS idx_events_tenant_id ON events(tenant_id);
CREATE INDEX IF NOT EXISTS idx_events_user_id ON events(user_id);
CREATE INDEX IF NOT EXISTS idx_events_event_type ON events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_created_at ON events(created_at DESC);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Updated_at triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_plans_updated_at ON plans;
CREATE TRIGGER update_plans_updated_at BEFORE UPDATE ON plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_tenants_updated_at ON tenants;
CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON tenants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON subscriptions;
CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_usage_counters_updated_at ON usage_counters;
CREATE TRIGGER update_usage_counters_updated_at BEFORE UPDATE ON usage_counters
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_domains_updated_at ON domains;
CREATE TRIGGER update_domains_updated_at BEFORE UPDATE ON domains
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_webhooks_updated_at ON webhooks;
CREATE TRIGGER update_webhooks_updated_at BEFORE UPDATE ON webhooks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_api_keys_updated_at ON api_keys;
CREATE TRIGGER update_api_keys_updated_at BEFORE UPDATE ON api_keys
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_counters ENABLE ROW LEVEL SECURITY;
ALTER TABLE domains ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- Plans Policies (Public Read)
-- ----------------------------------------------------------------------------
CREATE POLICY "Plans are viewable by everyone"
  ON plans FOR SELECT
  USING (is_active = true);

CREATE POLICY "Plans are manageable by service role"
  ON plans FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ----------------------------------------------------------------------------
-- Tenants Policies
-- ----------------------------------------------------------------------------
-- Owners can view their own tenants
CREATE POLICY "Users can view their own tenants"
  ON tenants FOR SELECT
  USING (auth.uid() = owner_id);

-- Owners can update their own tenants
CREATE POLICY "Users can update their own tenants"
  ON tenants FOR UPDATE
  USING (auth.uid() = owner_id);

-- Service role can do everything
CREATE POLICY "Service role can manage all tenants"
  ON tenants FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ----------------------------------------------------------------------------
-- Subscriptions Policies
-- ----------------------------------------------------------------------------
-- Users can view subscriptions for their tenants
CREATE POLICY "Users can view their tenant subscriptions"
  ON subscriptions FOR SELECT
  USING (
    tenant_id IN (
      SELECT id FROM tenants WHERE owner_id = auth.uid()
    )
  );

-- Service role can manage all subscriptions
CREATE POLICY "Service role can manage all subscriptions"
  ON subscriptions FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ----------------------------------------------------------------------------
-- Usage Counters Policies
-- ----------------------------------------------------------------------------
-- Users can view usage for their tenants
CREATE POLICY "Users can view their tenant usage"
  ON usage_counters FOR SELECT
  USING (
    tenant_id IN (
      SELECT id FROM tenants WHERE owner_id = auth.uid()
    )
  );

-- Service role can manage all usage counters
CREATE POLICY "Service role can manage all usage counters"
  ON usage_counters FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ----------------------------------------------------------------------------
-- Domains Policies
-- ----------------------------------------------------------------------------
-- Users can view domains for their tenants
CREATE POLICY "Users can view their tenant domains"
  ON domains FOR SELECT
  USING (
    tenant_id IN (
      SELECT id FROM tenants WHERE owner_id = auth.uid()
    )
  );

-- Users can create domains for their tenants
CREATE POLICY "Users can create domains for their tenants"
  ON domains FOR INSERT
  WITH CHECK (
    tenant_id IN (
      SELECT id FROM tenants WHERE owner_id = auth.uid()
    )
  );

-- Users can update their tenant domains
CREATE POLICY "Users can update their tenant domains"
  ON domains FOR UPDATE
  USING (
    tenant_id IN (
      SELECT id FROM tenants WHERE owner_id = auth.uid()
    )
  );

-- Users can delete their tenant domains
CREATE POLICY "Users can delete their tenant domains"
  ON domains FOR DELETE
  USING (
    tenant_id IN (
      SELECT id FROM tenants WHERE owner_id = auth.uid()
    )
  );

-- Service role can manage all domains
CREATE POLICY "Service role can manage all domains"
  ON domains FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ----------------------------------------------------------------------------
-- Webhooks Policies
-- ----------------------------------------------------------------------------
-- Users can manage webhooks for their tenants
CREATE POLICY "Users can view their tenant webhooks"
  ON webhooks FOR SELECT
  USING (
    tenant_id IN (
      SELECT id FROM tenants WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can create webhooks for their tenants"
  ON webhooks FOR INSERT
  WITH CHECK (
    tenant_id IN (
      SELECT id FROM tenants WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their tenant webhooks"
  ON webhooks FOR UPDATE
  USING (
    tenant_id IN (
      SELECT id FROM tenants WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete their tenant webhooks"
  ON webhooks FOR DELETE
  USING (
    tenant_id IN (
      SELECT id FROM tenants WHERE owner_id = auth.uid()
    )
  );

-- Service role can manage all webhooks
CREATE POLICY "Service role can manage all webhooks"
  ON webhooks FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ----------------------------------------------------------------------------
-- API Keys Policies
-- ----------------------------------------------------------------------------
-- Users can manage API keys for their tenants
CREATE POLICY "Users can view their tenant API keys"
  ON api_keys FOR SELECT
  USING (
    tenant_id IN (
      SELECT id FROM tenants WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can create API keys for their tenants"
  ON api_keys FOR INSERT
  WITH CHECK (
    tenant_id IN (
      SELECT id FROM tenants WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their tenant API keys"
  ON api_keys FOR UPDATE
  USING (
    tenant_id IN (
      SELECT id FROM tenants WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete their tenant API keys"
  ON api_keys FOR DELETE
  USING (
    tenant_id IN (
      SELECT id FROM tenants WHERE owner_id = auth.uid()
    )
  );

-- Service role can manage all API keys
CREATE POLICY "Service role can manage all API keys"
  ON api_keys FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ----------------------------------------------------------------------------
-- Events Policies (Audit Log)
-- ----------------------------------------------------------------------------
-- Users can view events for their tenants
CREATE POLICY "Users can view their tenant events"
  ON events FOR SELECT
  USING (
    tenant_id IN (
      SELECT id FROM tenants WHERE owner_id = auth.uid()
    )
    OR user_id = auth.uid()
  );

-- Service role can manage all events
CREATE POLICY "Service role can manage all events"
  ON events FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to get current tenant for a user
CREATE OR REPLACE FUNCTION get_user_tenant_id()
RETURNS UUID AS $$
  SELECT id FROM tenants WHERE owner_id = auth.uid() LIMIT 1;
$$ LANGUAGE SQL SECURITY DEFINER;

-- Function to check if user owns tenant
CREATE OR REPLACE FUNCTION user_owns_tenant(tenant_uuid UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM tenants 
    WHERE id = tenant_uuid AND owner_id = auth.uid()
  );
$$ LANGUAGE SQL SECURITY DEFINER;

-- Function to get tenant usage for current period
CREATE OR REPLACE FUNCTION get_current_usage(tenant_uuid UUID)
RETURNS TABLE (
  orders INTEGER,
  products INTEGER,
  storage_gb NUMERIC,
  bandwidth_gb NUMERIC,
  api_calls INTEGER
) AS $$
  SELECT 
    COALESCE(orders_count, 0)::INTEGER,
    COALESCE(products_count, 0)::INTEGER,
    ROUND(COALESCE(asset_storage_bytes, 0)::NUMERIC / 1073741824, 2) as storage_gb,
    ROUND(COALESCE(bandwidth_bytes, 0)::NUMERIC / 1073741824, 2) as bandwidth_gb,
    COALESCE(api_calls_count, 0)::INTEGER
  FROM usage_counters
  WHERE tenant_id = tenant_uuid
    AND period_start <= NOW()
    AND period_end >= NOW()
  LIMIT 1;
$$ LANGUAGE SQL SECURITY DEFINER;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE plans IS 'Subscription plans with pricing and limits';
COMMENT ON TABLE tenants IS 'Multi-tenant stores with Medusa integration';
COMMENT ON TABLE subscriptions IS 'Active subscriptions linked to Stripe';
COMMENT ON TABLE usage_counters IS 'Usage tracking per billing period';
COMMENT ON TABLE domains IS 'Custom domains with verification status';
COMMENT ON TABLE webhooks IS 'Webhook configurations for event notifications';
COMMENT ON TABLE api_keys IS 'API keys for programmatic access';
COMMENT ON TABLE events IS 'Audit log for all system events';

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================

