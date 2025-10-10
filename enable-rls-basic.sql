-- Enable Row Level Security (RLS) for all SaaS tables
-- This is a basic setup - run this first to enable RLS

-- =============================================
-- ENABLE RLS ON ALL TABLES
-- =============================================

ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE plan_entitlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_counters ENABLE ROW LEVEL SECURITY;
ALTER TABLE domains ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- =============================================
-- BASIC POLICIES (Temporary - for testing)
-- =============================================

-- Allow authenticated users to read their own data
CREATE POLICY "Users can read own profile" ON users
    FOR SELECT USING (id = auth.uid());

-- Allow authenticated users to update their own profile
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (id = auth.uid());

-- Allow authenticated users to read plans (public data)
CREATE POLICY "Plans are publicly readable" ON plans
    FOR SELECT USING (is_active = true);

-- Allow authenticated users to read plan entitlements
CREATE POLICY "Plan entitlements are publicly readable" ON plan_entitlements
    FOR SELECT USING (true);

-- =============================================
-- SERVICE ROLE POLICIES
-- =============================================

-- Allow service role to do everything (for system operations)
CREATE POLICY "Service role can manage all data" ON tenants
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage all data" ON users
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage all data" ON tenant_users
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage all data" ON plans
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage all data" ON plan_entitlements
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage all data" ON subscriptions
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage all data" ON usage_counters
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage all data" ON domains
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage all data" ON webhooks
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage all data" ON api_keys
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage all data" ON events
    FOR ALL USING (auth.role() = 'service_role');

-- =============================================
-- GRANT PERMISSIONS
-- =============================================

-- Grant necessary permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant permissions to service role
GRANT ALL ON SCHEMA public TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
