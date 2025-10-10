-- Supabase Authentication Setup for Azima.Store
-- This script configures authentication settings and creates necessary functions

-- =============================================
-- AUTHENTICATION CONFIGURATION
-- =============================================

-- Enable email authentication
-- Note: These settings are typically configured in Supabase Dashboard
-- but we'll document them here for reference

-- 1. Go to Authentication > Settings in Supabase Dashboard
-- 2. Enable "Enable email confirmations"
-- 3. Set "Site URL" to your production domain
-- 4. Configure "Redirect URLs" for your app domains

-- =============================================
-- AUTHENTICATION FUNCTIONS
-- =============================================

-- Function to handle user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert into users table when auth.users is created
    INSERT INTO public.users (id, email, first_name, last_name, email_verified)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
        COALESCE(NEW.email_confirmed_at IS NOT NULL, false)
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle user updates
CREATE OR REPLACE FUNCTION handle_user_update()
RETURNS TRIGGER AS $$
BEGIN
    -- Update users table when auth.users is updated
    UPDATE public.users
    SET
        email = NEW.email,
        first_name = COALESCE(NEW.raw_user_meta_data->>'first_name', first_name),
        last_name = COALESCE(NEW.raw_user_meta_data->>'last_name', last_name),
        email_verified = COALESCE(NEW.email_confirmed_at IS NOT NULL, email_verified),
        updated_at = NOW()
    WHERE id = NEW.id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle user deletion
CREATE OR REPLACE FUNCTION handle_user_delete()
RETURNS TRIGGER AS $$
BEGIN
    -- Soft delete user and related data
    UPDATE public.users
    SET deleted_at = NOW()
    WHERE id = OLD.id;
    
    -- Remove from all tenant relationships
    DELETE FROM public.tenant_users
    WHERE user_id = OLD.id;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- AUTHENTICATION TRIGGERS
-- =============================================

-- Trigger for new user registration
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Trigger for user updates
CREATE TRIGGER on_auth_user_updated
    AFTER UPDATE ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_user_update();

-- Trigger for user deletion
CREATE TRIGGER on_auth_user_deleted
    AFTER DELETE ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_user_delete();

-- =============================================
-- AUTHENTICATION HELPER FUNCTIONS
-- =============================================

-- Function to get user profile with tenant information
CREATE OR REPLACE FUNCTION get_user_profile(user_uuid UUID)
RETURNS JSON AS $$
DECLARE
    user_profile JSON;
    tenant_list JSON;
BEGIN
    -- Get user basic info
    SELECT json_build_object(
        'id', u.id,
        'email', u.email,
        'first_name', u.first_name,
        'last_name', u.last_name,
        'avatar_url', u.avatar_url,
        'email_verified', u.email_verified,
        'two_factor_enabled', u.two_factor_enabled,
        'last_login_at', u.last_login_at,
        'created_at', u.created_at
    ) INTO user_profile
    FROM users u
    WHERE u.id = user_uuid;
    
    -- Get user's tenants
    SELECT json_agg(
        json_build_object(
            'id', t.id,
            'name', t.name,
            'slug', t.slug,
            'subdomain', t.subdomain,
            'status', t.status,
            'role', tu.role,
            'permissions', tu.permissions
        )
    ) INTO tenant_list
    FROM tenant_users tu
    JOIN tenants t ON tu.tenant_id = t.id
    WHERE tu.user_id = user_uuid;
    
    -- Combine user profile with tenant list
    RETURN json_build_object(
        'profile', user_profile,
        'tenants', COALESCE(tenant_list, '[]'::json)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can access tenant
CREATE OR REPLACE FUNCTION can_access_tenant(user_uuid UUID, tenant_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1
        FROM tenant_users tu
        WHERE tu.user_id = user_uuid
        AND tu.tenant_id = tenant_uuid
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's role in tenant
CREATE OR REPLACE FUNCTION get_user_tenant_role(user_uuid UUID, tenant_uuid UUID)
RETURNS user_role AS $$
DECLARE
    user_role user_role;
BEGIN
    SELECT tu.role INTO user_role
    FROM tenant_users tu
    WHERE tu.user_id = user_uuid
    AND tu.tenant_id = tenant_uuid;
    
    RETURN user_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- AUTHENTICATION POLICIES
-- =============================================

-- Allow users to read their own profile
CREATE POLICY "Users can read own profile" ON users
    FOR SELECT USING (id = auth.uid());

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (id = auth.uid());

-- =============================================
-- SAMPLE DATA FOR TESTING
-- =============================================

-- Insert sample plans
INSERT INTO plans (id, name, tier, price_monthly, price_yearly, features, limits) VALUES
(
    uuid_generate_v4(),
    'Free',
    'free',
    0,
    0,
    '{"basic_storefront": true, "basic_analytics": true}',
    '{"stores": 1, "products": 20, "orders_per_month": 25, "storage_gb": 1}'
),
(
    uuid_generate_v4(),
    'Starter',
    'starter',
    1500, -- $15.00
    15000, -- $150.00
    '{"custom_domain": true, "advanced_analytics": true, "email_support": true}',
    '{"stores": 1, "products": 200, "orders_per_month": 200, "storage_gb": 10}'
),
(
    uuid_generate_v4(),
    'Pro',
    'pro',
    3900, -- $39.00
    39000, -- $390.00
    '{"multiple_stores": true, "custom_themes": true, "priority_support": true}',
    '{"stores": 2, "products": 2000, "orders_per_month": 1000, "storage_gb": 50}'
);

-- =============================================
-- AUTHENTICATION NOTES
-- =============================================

/*
To complete the authentication setup:

1. In Supabase Dashboard > Authentication > Settings:
   - Enable "Enable email confirmations"
   - Set "Site URL" to your production domain
   - Add redirect URLs for your app domains
   - Configure email templates if needed

2. In Supabase Dashboard > Authentication > Providers:
   - Configure any additional providers (Google, GitHub, etc.)
   - Set up OAuth redirect URLs

3. In Supabase Dashboard > Authentication > Policies:
   - Review and adjust RLS policies as needed
   - Test authentication flows

4. Environment Variables needed:
   - SUPABASE_URL
   - SUPABASE_ANON_KEY
   - SUPABASE_SERVICE_ROLE_KEY

5. Client-side setup:
   - Install @supabase/supabase-js
   - Initialize Supabase client
   - Set up authentication context
*/
