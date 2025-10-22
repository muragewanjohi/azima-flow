# **SaaS Database Setup Guide**

This guide walks you through setting up the SaaS database schema in the `azima-store-saas` Supabase project.

---

## **📋 Overview**

The SaaS database manages:
- **Multi-tenant infrastructure** (tenants, domains)
- **Subscription & billing** (plans, subscriptions, usage tracking)
- **Security & access** (API keys, webhooks, audit logs)

---

## **🎯 Prerequisites**

1. **Supabase Project**: `azima-store-saas` project created
2. **Database Access**: Service role key or database connection string
3. **SQL Client**: Supabase SQL Editor (recommended) or `psql`

---

## **🚀 Setup Steps**

### **Step 1: Run Schema Migration**

1. Open Supabase Dashboard → SQL Editor
2. Create new query
3. Copy contents of `saas-database-schema.sql`
4. Execute the query
5. Verify all tables are created

**Expected tables:**
- `plans`
- `tenants`
- `subscriptions`
- `usage_counters`
- `domains`
- `webhooks`
- `api_keys`
- `events`

### **Step 2: Seed Initial Data**

1. Open new SQL Editor query
2. Copy contents of `saas-database-seed.sql`
3. Execute the query
4. Verify plans are created

**Expected output:**
```
tier       | name              | monthly_price_usd | annual_price_usd | ...
-----------|-------------------|-------------------|------------------|-----
free       | Free (Dev/Sandbox)| 0.00              | 0.00             | ...
starter    | Starter           | 15.00             | 150.00           | ...
pro        | Pro               | 39.00             | 390.00           | ...
growth     | Growth            | 79.00             | 790.00           | ...
scale      | Scale             | 149.00            | 1490.00          | ...
enterprise | Enterprise        | 0.00              | 0.00             | ...
```

### **Step 3: Verify RLS Policies**

Run this query to check RLS is enabled:

```sql
SELECT 
  tablename, 
  rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN (
    'plans', 'tenants', 'subscriptions', 'usage_counters', 
    'domains', 'webhooks', 'api_keys', 'events'
  );
```

**Expected result:** All tables should have `rowsecurity = true`

### **Step 4: Test Helper Functions**

```sql
-- Test get_user_tenant_id (should return NULL if not authenticated)
SELECT get_user_tenant_id();

-- Test get_current_usage (replace with actual tenant_id once you have one)
SELECT * FROM get_current_usage('00000000-0000-0000-0000-000000000000');
```

---

## **🧪 Testing the Schema**

### **Test 1: Create a Test Tenant**

```sql
-- First, create a test user in auth.users (or use existing user)
-- Then create a tenant
INSERT INTO tenants (
  business_name,
  subdomain,
  slug,
  owner_id,
  status
) VALUES (
  'Test Store',
  'test-store',
  'test-store',
  '00000000-0000-0000-0000-000000000000', -- Replace with real user ID
  'active'
) RETURNING *;
```

### **Test 2: Create a Subscription**

```sql
-- Get the free plan ID
WITH free_plan AS (
  SELECT id FROM plans WHERE tier = 'free' LIMIT 1
),
test_tenant AS (
  SELECT id FROM tenants WHERE subdomain = 'test-store' LIMIT 1
)
INSERT INTO subscriptions (
  tenant_id,
  plan_id,
  status,
  current_period_start,
  current_period_end,
  trial_start,
  trial_end
) 
SELECT 
  test_tenant.id,
  free_plan.id,
  'trialing',
  NOW(),
  NOW() + INTERVAL '30 days',
  NOW(),
  NOW() + INTERVAL '14 days'
FROM test_tenant, free_plan
RETURNING *;
```

### **Test 3: Create Usage Counter**

```sql
-- Create usage counter for current period
WITH test_tenant AS (
  SELECT id FROM tenants WHERE subdomain = 'test-store' LIMIT 1
)
INSERT INTO usage_counters (
  tenant_id,
  period_start,
  period_end,
  orders_count,
  products_count
)
SELECT 
  id,
  DATE_TRUNC('month', NOW()),
  DATE_TRUNC('month', NOW()) + INTERVAL '1 month',
  5,
  10
FROM test_tenant
RETURNING *;
```

### **Test 4: Add a Custom Domain**

```sql
-- Add custom domain
WITH test_tenant AS (
  SELECT id FROM tenants WHERE subdomain = 'test-store' LIMIT 1
)
INSERT INTO domains (
  tenant_id,
  domain,
  is_primary,
  status,
  verification_token
)
SELECT 
  id,
  'example.com',
  true,
  'pending_verification',
  encode(gen_random_bytes(32), 'hex')
FROM test_tenant
RETURNING *;
```

### **Test 5: Create an API Key**

```sql
-- Create API key
WITH test_tenant AS (
  SELECT id FROM tenants WHERE subdomain = 'test-store' LIMIT 1
)
INSERT INTO api_keys (
  tenant_id,
  name,
  key_prefix,
  key_hash,
  scopes
)
SELECT 
  id,
  'Test API Key',
  'azima_test',
  encode(sha256('test-secret-key'::bytea), 'hex'),
  ARRAY['read', 'write']::TEXT[]
FROM test_tenant
RETURNING id, name, key_prefix, scopes, created_at;
```

### **Test 6: Log an Event**

```sql
-- Log an audit event
WITH test_tenant AS (
  SELECT id FROM tenants WHERE subdomain = 'test-store' LIMIT 1
)
INSERT INTO events (
  tenant_id,
  event_type,
  event_category,
  resource_type,
  resource_id,
  payload
)
SELECT 
  id,
  'tenant.created',
  'tenant_management',
  'tenant',
  id::TEXT,
  '{"action": "created", "source": "manual_test"}'::jsonb
FROM test_tenant
RETURNING *;
```

---

## **🔍 Verification Queries**

### **View All Tenants with Their Plans**

```sql
SELECT 
  t.id,
  t.business_name,
  t.subdomain,
  t.status,
  p.name as plan_name,
  p.tier as plan_tier,
  s.status as subscription_status,
  s.current_period_end,
  t.created_at
FROM tenants t
LEFT JOIN subscriptions s ON s.tenant_id = t.id
LEFT JOIN plans p ON p.id = s.plan_id
ORDER BY t.created_at DESC;
```

### **View Usage Summary**

```sql
SELECT 
  t.business_name,
  t.subdomain,
  u.period_start,
  u.period_end,
  u.orders_count,
  u.products_count,
  ROUND(u.asset_storage_bytes::NUMERIC / 1073741824, 2) as storage_gb,
  p.max_orders_per_month as limit_orders,
  p.max_products as limit_products
FROM usage_counters u
JOIN tenants t ON t.id = u.tenant_id
LEFT JOIN subscriptions s ON s.tenant_id = t.id
LEFT JOIN plans p ON p.id = s.plan_id
WHERE u.period_end >= NOW()
ORDER BY t.business_name;
```

### **View All Domains**

```sql
SELECT 
  t.business_name,
  d.domain,
  d.is_primary,
  d.status,
  d.verified_at,
  d.ssl_enabled
FROM domains d
JOIN tenants t ON t.id = d.tenant_id
ORDER BY t.business_name, d.is_primary DESC;
```

### **View Active Webhooks**

```sql
SELECT 
  t.business_name,
  w.url,
  w.events,
  w.is_active,
  w.last_success_at,
  w.last_failure_at
FROM webhooks w
JOIN tenants t ON t.id = w.tenant_id
WHERE w.is_active = true
ORDER BY t.business_name;
```

### **View Recent Events (Audit Log)**

```sql
SELECT 
  t.business_name,
  e.event_type,
  e.event_category,
  e.resource_type,
  e.resource_id,
  e.payload,
  e.created_at
FROM events e
LEFT JOIN tenants t ON t.id = e.tenant_id
ORDER BY e.created_at DESC
LIMIT 50;
```

---

## **🛠️ Common Operations**

### **Update Tenant Status**

```sql
UPDATE tenants 
SET status = 'active', provisioned_at = NOW()
WHERE subdomain = 'test-store';
```

### **Increment Usage Counter**

```sql
-- Increment orders count for current period
WITH test_tenant AS (
  SELECT id FROM tenants WHERE subdomain = 'test-store' LIMIT 1
)
UPDATE usage_counters
SET 
  orders_count = orders_count + 1,
  updated_at = NOW()
WHERE tenant_id = (SELECT id FROM test_tenant)
  AND period_start <= NOW()
  AND period_end >= NOW();
```

### **Verify a Domain**

```sql
UPDATE domains
SET 
  status = 'verified',
  verified_at = NOW()
WHERE domain = 'example.com';
```

### **Suspend a Tenant**

```sql
UPDATE tenants
SET 
  status = 'suspended',
  updated_at = NOW()
WHERE subdomain = 'test-store';
```

---

## **🔐 RLS Policy Testing**

### **Test User Isolation**

```sql
-- Switch to an authenticated user context
SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000000';

-- This should only return tenants owned by this user
SELECT * FROM tenants;

-- Reset to service role
RESET request.jwt.claim.sub;
```

### **Test Service Role Access**

```sql
-- Service role should see everything
SELECT COUNT(*) FROM tenants;
SELECT COUNT(*) FROM subscriptions;
SELECT COUNT(*) FROM usage_counters;
```

---

## **📊 Database Statistics**

### **Table Sizes**

```sql
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### **Row Counts**

```sql
SELECT 
  'plans' as table_name, COUNT(*) as row_count FROM plans
UNION ALL
SELECT 'tenants', COUNT(*) FROM tenants
UNION ALL
SELECT 'subscriptions', COUNT(*) FROM subscriptions
UNION ALL
SELECT 'usage_counters', COUNT(*) FROM usage_counters
UNION ALL
SELECT 'domains', COUNT(*) FROM domains
UNION ALL
SELECT 'webhooks', COUNT(*) FROM webhooks
UNION ALL
SELECT 'api_keys', COUNT(*) FROM api_keys
UNION ALL
SELECT 'events', COUNT(*) FROM events;
```

---

## **🧹 Cleanup (Development Only)**

### **Delete Test Data**

```sql
-- Delete test tenant and all related data (CASCADE)
DELETE FROM tenants WHERE subdomain = 'test-store';
```

### **Reset All Data (DANGER)**

```sql
-- WARNING: This deletes ALL data!
-- Only use in development

TRUNCATE TABLE events CASCADE;
TRUNCATE TABLE api_keys CASCADE;
TRUNCATE TABLE webhooks CASCADE;
TRUNCATE TABLE domains CASCADE;
TRUNCATE TABLE usage_counters CASCADE;
TRUNCATE TABLE subscriptions CASCADE;
TRUNCATE TABLE tenants CASCADE;
-- Don't truncate plans as they are seed data
```

---

## **✅ Success Criteria**

You've successfully set up the SaaS database when:

- [x] All 8 tables created with correct schema
- [x] 6 pricing plans seeded
- [x] RLS enabled on all tables
- [x] RLS policies working correctly
- [x] Helper functions operational
- [x] Triggers updating `updated_at` correctly
- [x] Indexes created for performance
- [x] Test tenant can be created and queried

---

## **📝 Next Steps**

After completing this setup:

1. **Day 8**: Implement Medusa tenant isolation middleware
2. **Day 9**: Create SaaS signup API with dual user creation
3. **Day 10**: Test complete provisioning flow

---

## **🆘 Troubleshooting**

### **RLS Blocking Queries**

If you can't query tables:
```sql
-- Check if RLS is the issue
ALTER TABLE tenants DISABLE ROW LEVEL SECURITY;
-- Try your query
-- Then re-enable
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
```

### **Foreign Key Violations**

Make sure you're creating records in the correct order:
1. Plans (seed data)
2. Tenants (requires owner_id from auth.users)
3. Subscriptions (requires tenant_id and plan_id)
4. Everything else (requires tenant_id)

### **Trigger Not Firing**

Check trigger exists:
```sql
SELECT tgname, tgrelid::regclass, tgenabled 
FROM pg_trigger 
WHERE tgname LIKE '%updated_at%';
```

---

**Last Updated:** October 21, 2025  
**Schema Version:** 1.0

