-- ============================================================================
-- Azima.Store SaaS Database Seed Data
-- ============================================================================
-- Purpose: Initial data for plans and default configurations
-- Run this AFTER saas-database-schema.sql
-- ============================================================================

-- ============================================================================
-- SEED PLANS
-- ============================================================================

-- Free Plan (Dev/Sandbox)
INSERT INTO plans (
  name,
  tier,
  description,
  monthly_price_cents,
  annual_price_cents,
  max_stores,
  max_products,
  max_orders_per_month,
  max_custom_domains,
  max_staff_accounts,
  max_asset_storage_gb,
  features,
  overage_order_price_cents,
  is_active,
  sort_order
) VALUES (
  'Free (Dev/Sandbox)',
  'free',
  'Perfect for evaluation and testing',
  0,
  0,
  1,
  20,
  25,
  0,
  1,
  1,
  '["Test domain only", "Basic support", "Community access"]'::jsonb,
  0,
  true,
  1
);

-- Starter Plan
INSERT INTO plans (
  name,
  tier,
  description,
  monthly_price_cents,
  annual_price_cents,
  max_stores,
  max_products,
  max_orders_per_month,
  max_custom_domains,
  max_staff_accounts,
  max_asset_storage_gb,
  features,
  overage_order_price_cents,
  is_active,
  sort_order
) VALUES (
  'Starter',
  'starter',
  'Great for new stores getting started',
  1500,
  15000,
  1,
  200,
  200,
  1,
  2,
  10,
  '["1 custom domain", "Email support", "SSL certificates", "Basic analytics"]'::jsonb,
  6,
  true,
  2
);

-- Pro Plan
INSERT INTO plans (
  name,
  tier,
  description,
  monthly_price_cents,
  annual_price_cents,
  max_stores,
  max_products,
  max_orders_per_month,
  max_custom_domains,
  max_staff_accounts,
  max_asset_storage_gb,
  features,
  overage_order_price_cents,
  is_active,
  sort_order
) VALUES (
  'Pro',
  'pro',
  'Perfect for growing businesses',
  3900,
  39000,
  2,
  2000,
  1000,
  3,
  5,
  50,
  '["3 custom domains", "Priority email support", "Advanced analytics", "Abandoned cart recovery", "Custom checkout", "Gift cards"]'::jsonb,
  5,
  true,
  3
);

-- Growth Plan
INSERT INTO plans (
  name,
  tier,
  description,
  monthly_price_cents,
  annual_price_cents,
  max_stores,
  max_products,
  max_orders_per_month,
  max_custom_domains,
  max_staff_accounts,
  max_asset_storage_gb,
  features,
  overage_order_price_cents,
  is_active,
  sort_order
) VALUES (
  'Growth',
  'growth',
  'For serious merchants scaling up',
  7900,
  79000,
  3,
  10000,
  3000,
  5,
  10,
  200,
  '["5 custom domains", "Phone & email support", "Advanced analytics", "API access", "Webhooks", "Multi-currency display", "Scheduled launches", "Staff permissions"]'::jsonb,
  4,
  true,
  4
);

-- Scale Plan
INSERT INTO plans (
  name,
  tier,
  description,
  monthly_price_cents,
  annual_price_cents,
  max_stores,
  max_products,
  max_orders_per_month,
  max_custom_domains,
  max_staff_accounts,
  max_asset_storage_gb,
  features,
  overage_order_price_cents,
  is_active,
  sort_order
) VALUES (
  'Scale',
  'scale',
  'High-volume stores with custom needs',
  14900,
  149000,
  5,
  50000,
  8000,
  10,
  20,
  500,
  '["10 custom domains", "Priority phone support", "Dedicated account manager", "Custom integrations", "SLA guarantees", "Advanced permissions", "Custom reports", "API rate limit boost"]'::jsonb,
  3,
  true,
  5
);

-- Enterprise Plan (Placeholder - contact for pricing)
INSERT INTO plans (
  name,
  tier,
  description,
  monthly_price_cents,
  annual_price_cents,
  max_stores,
  max_products,
  max_orders_per_month,
  max_custom_domains,
  max_staff_accounts,
  max_asset_storage_gb,
  features,
  overage_order_price_cents,
  is_active,
  sort_order
) VALUES (
  'Enterprise',
  'enterprise',
  'Custom solutions for brands and agencies',
  0, -- Custom pricing
  0, -- Custom pricing
  999,
  999999,
  999999,
  999,
  999,
  9999,
  '["Unlimited custom domains", "24/7 priority support", "SSO & SAML", "Audit logs", "Custom SLA", "White-label options", "Dedicated infrastructure", "Custom integrations", "Training & onboarding"]'::jsonb,
  0,
  false, -- Contact sales only
  6
);

-- ============================================================================
-- VERIFY SEED DATA
-- ============================================================================

-- Display all plans
SELECT 
  tier,
  name,
  monthly_price_cents / 100.0 as monthly_price_usd,
  annual_price_cents / 100.0 as annual_price_usd,
  max_products,
  max_orders_per_month,
  max_custom_domains,
  max_staff_accounts,
  max_asset_storage_gb,
  is_active
FROM plans
ORDER BY sort_order;

-- ============================================================================
-- END OF SEED DATA
-- ============================================================================

