-- SaaS Database Schema for Azima.Store - Part 3
-- This script creates triggers and sample data

-- =============================================
-- TRIGGERS FOR UPDATED_AT
-- =============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers to relevant tables
CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON tenants FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tenant_users_updated_at BEFORE UPDATE ON tenant_users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_plans_updated_at BEFORE UPDATE ON plans FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_usage_counters_updated_at BEFORE UPDATE ON usage_counters FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_domains_updated_at BEFORE UPDATE ON domains FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_webhooks_updated_at BEFORE UPDATE ON webhooks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_api_keys_updated_at BEFORE UPDATE ON api_keys FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- SAMPLE DATA
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
),
(
    uuid_generate_v4(),
    'Growth',
    'growth',
    7900, -- $79.00
    79000, -- $790.00
    '{"advanced_features": true, "custom_integrations": true, "phone_support": true}',
    '{"stores": 3, "products": 10000, "orders_per_month": 3000, "storage_gb": 200}'
),
(
    uuid_generate_v4(),
    'Scale',
    'scale',
    14900, -- $149.00
    149000, -- $1490.00
    '{"enterprise_features": true, "dedicated_support": true, "custom_sla": true}',
    '{"stores": 5, "products": 50000, "orders_per_month": 8000, "storage_gb": 500}'
);

-- Insert sample plan entitlements
INSERT INTO plan_entitlements (plan_id, feature_key, limit_value, is_unlimited)
SELECT 
    p.id,
    feature_key,
    limit_value,
    is_unlimited
FROM plans p
CROSS JOIN (
    VALUES 
        ('stores', 1, false),
        ('products', 20, false),
        ('orders_per_month', 25, false),
        ('storage_gb', 1, false),
        ('custom_domain', 0, false),
        ('email_support', 1, false)
) AS features(feature_key, limit_value, is_unlimited)
WHERE p.tier = 'free'

UNION ALL

SELECT 
    p.id,
    feature_key,
    limit_value,
    is_unlimited
FROM plans p
CROSS JOIN (
    VALUES 
        ('stores', 1, false),
        ('products', 200, false),
        ('orders_per_month', 200, false),
        ('storage_gb', 10, false),
        ('custom_domain', 1, false),
        ('email_support', 1, false)
) AS features(feature_key, limit_value, is_unlimited)
WHERE p.tier = 'starter'

UNION ALL

SELECT 
    p.id,
    feature_key,
    limit_value,
    is_unlimited
FROM plans p
CROSS JOIN (
    VALUES 
        ('stores', 2, false),
        ('products', 2000, false),
        ('orders_per_month', 1000, false),
        ('storage_gb', 50, false),
        ('custom_domain', 3, false),
        ('email_support', 1, false)
) AS features(feature_key, limit_value, is_unlimited)
WHERE p.tier = 'pro';
