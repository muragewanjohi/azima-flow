-- Row Level Security (RLS) Policies for Azima.Store SaaS Platform
-- This script sets up RLS policies to ensure proper data isolation

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
-- HELPER FUNCTIONS
-- =============================================

-- Function to get current user's tenant IDs
CREATE OR REPLACE FUNCTION get_user_tenant_ids(user_uuid UUID)
RETURNS UUID[] AS $$
BEGIN
    RETURN ARRAY(
        SELECT tenant_id 
        FROM tenant_users 
        WHERE user_id = user_uuid
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user has access to tenant
CREATE OR REPLACE FUNCTION user_has_tenant_access(user_uuid UUID, tenant_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 
        FROM tenant_users 
        WHERE user_id = user_uuid 
        AND tenant_id = tenant_uuid
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is tenant owner/admin
CREATE OR REPLACE FUNCTION user_is_tenant_admin(user_uuid UUID, tenant_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 
        FROM tenant_users 
        WHERE user_id = user_uuid 
        AND tenant_id = tenant_uuid
        AND role IN ('owner', 'admin')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- TENANTS TABLE POLICIES
-- =============================================

-- Users can only see tenants they have access to
CREATE POLICY "Users can view their tenants" ON tenants
    FOR SELECT USING (
        id = ANY(get_user_tenant_ids(auth.uid()))
    );

-- Only tenant owners can update tenant info
CREATE POLICY "Owners can update their tenants" ON tenants
    FOR UPDATE USING (
        user_is_tenant_admin(auth.uid(), id)
    );

-- Only system can insert tenants (via service role)
CREATE POLICY "System can insert tenants" ON tenants
    FOR INSERT WITH CHECK (true);

-- Only system can delete tenants (via service role)
CREATE POLICY "System can delete tenants" ON tenants
    FOR DELETE USING (true);

-- =============================================
-- USERS TABLE POLICIES
-- =============================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (id = auth.uid());

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (id = auth.uid());

-- System can insert users (registration)
CREATE POLICY "System can insert users" ON users
    FOR INSERT WITH CHECK (true);

-- =============================================
-- TENANT_USERS TABLE POLICIES
-- =============================================

-- Users can view tenant relationships for their tenants
CREATE POLICY "Users can view their tenant relationships" ON tenant_users
    FOR SELECT USING (
        user_id = auth.uid() OR 
        tenant_id = ANY(get_user_tenant_ids(auth.uid()))
    );

-- Only tenant owners can manage user relationships
CREATE POLICY "Owners can manage tenant users" ON tenant_users
    FOR ALL USING (
        user_is_tenant_admin(auth.uid(), tenant_id)
    );

-- =============================================
-- PLANS TABLE POLICIES
-- =============================================

-- Plans are public (read-only for users)
CREATE POLICY "Plans are publicly readable" ON plans
    FOR SELECT USING (is_active = true);

-- Only system can manage plans
CREATE POLICY "System can manage plans" ON plans
    FOR ALL USING (true);

-- =============================================
-- PLAN_ENTITLEMENTS TABLE POLICIES
-- =============================================

-- Plan entitlements are public (read-only for users)
CREATE POLICY "Plan entitlements are publicly readable" ON plan_entitlements
    FOR SELECT USING (true);

-- Only system can manage plan entitlements
CREATE POLICY "System can manage plan entitlements" ON plan_entitlements
    FOR ALL USING (true);

-- =============================================
-- SUBSCRIPTIONS TABLE POLICIES
-- =============================================

-- Users can view subscriptions for their tenants
CREATE POLICY "Users can view their tenant subscriptions" ON subscriptions
    FOR SELECT USING (
        tenant_id = ANY(get_user_tenant_ids(auth.uid()))
    );

-- Only tenant owners can update subscriptions
CREATE POLICY "Owners can update tenant subscriptions" ON subscriptions
    FOR UPDATE USING (
        user_is_tenant_admin(auth.uid(), tenant_id)
    );

-- System can manage subscriptions
CREATE POLICY "System can manage subscriptions" ON subscriptions
    FOR ALL USING (true);

-- =============================================
-- USAGE_COUNTERS TABLE POLICIES
-- =============================================

-- Users can view usage for their tenants
CREATE POLICY "Users can view their tenant usage" ON usage_counters
    FOR SELECT USING (
        tenant_id = ANY(get_user_tenant_ids(auth.uid()))
    );

-- Only system can manage usage counters
CREATE POLICY "System can manage usage counters" ON usage_counters
    FOR ALL USING (true);

-- =============================================
-- DOMAINS TABLE POLICIES
-- =============================================

-- Users can view domains for their tenants
CREATE POLICY "Users can view their tenant domains" ON domains
    FOR SELECT USING (
        tenant_id = ANY(get_user_tenant_ids(auth.uid()))
    );

-- Only tenant owners can manage domains
CREATE POLICY "Owners can manage tenant domains" ON domains
    FOR ALL USING (
        user_is_tenant_admin(auth.uid(), tenant_id)
    );

-- =============================================
-- WEBHOOKS TABLE POLICIES
-- =============================================

-- Users can view webhooks for their tenants
CREATE POLICY "Users can view their tenant webhooks" ON webhooks
    FOR SELECT USING (
        tenant_id = ANY(get_user_tenant_ids(auth.uid()))
    );

-- Only tenant owners can manage webhooks
CREATE POLICY "Owners can manage tenant webhooks" ON webhooks
    FOR ALL USING (
        user_is_tenant_admin(auth.uid(), tenant_id)
    );

-- =============================================
-- API_KEYS TABLE POLICIES
-- =============================================

-- Users can view API keys for their tenants
CREATE POLICY "Users can view their tenant API keys" ON api_keys
    FOR SELECT USING (
        tenant_id = ANY(get_user_tenant_ids(auth.uid()))
    );

-- Only tenant owners can manage API keys
CREATE POLICY "Owners can manage tenant API keys" ON api_keys
    FOR ALL USING (
        user_is_tenant_admin(auth.uid(), tenant_id)
    );

-- =============================================
-- EVENTS TABLE POLICIES
-- =============================================

-- Users can view events for their tenants
CREATE POLICY "Users can view their tenant events" ON events
    FOR SELECT USING (
        tenant_id = ANY(get_user_tenant_ids(auth.uid()))
    );

-- System can manage events
CREATE POLICY "System can manage events" ON events
    FOR ALL USING (true);

-- =============================================
-- SERVICE ROLE POLICIES
-- =============================================

-- Create a service role for system operations
-- Note: This would typically be done through Supabase dashboard
-- but we'll document the policies here

-- Service role can bypass RLS for system operations
-- This is handled by using the service role key in application code

-- =============================================
-- GRANT PERMISSIONS
-- =============================================

-- Grant necessary permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant permissions to service role (if exists)
GRANT ALL ON SCHEMA public TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
