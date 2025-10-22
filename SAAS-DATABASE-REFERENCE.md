# **SaaS Database Schema Reference**

Quick reference for the `azima-store-saas` database schema.

---

## **📊 Tables Overview**

| Table | Purpose | Key Relationships |
|-------|---------|-------------------|
| `plans` | Subscription pricing tiers | Referenced by `subscriptions` |
| `tenants` | Multi-tenant stores | Owned by `auth.users`, has many `subscriptions`, `domains`, etc. |
| `subscriptions` | Active subscriptions | Links `tenants` to `plans`, connects to Stripe |
| `usage_counters` | Usage tracking per period | Belongs to `tenant`, tracks orders/assets/bandwidth |
| `domains` | Custom domains | Belongs to `tenant`, tracks verification status |
| `webhooks` | Event notification endpoints | Belongs to `tenant`, stores URL and secret |
| `api_keys` | Programmatic access | Belongs to `tenant`, hashed keys with scopes |
| `events` | Audit log | Optional `tenant` and `user` references |

---

## **🔑 Key Enums**

### `tenant_status`
- `provisioning` - Being set up
- `active` - Fully operational
- `suspended` - Temporarily disabled
- `error` - Provisioning failed
- `deleted` - Soft deleted

### `plan_tier`
- `free` - Dev/Sandbox
- `starter` - $15/mo
- `pro` - $39/mo
- `growth` - $79/mo
- `scale` - $149/mo
- `enterprise` - Custom pricing

### `subscription_status`
- `trialing` - Free trial period
- `active` - Paid and active
- `past_due` - Payment failed
- `canceled` - Canceled by user
- `unpaid` - Payment required

### `domain_status`
- `pending_verification` - Awaiting DNS verification
- `verified` - DNS verified
- `active` - Live and serving traffic
- `failed` - Verification failed
- `inactive` - Temporarily disabled

---

## **🔗 Relationships**

### Tenant → Everything
```
tenants (1) → (many) subscriptions
tenants (1) → (many) usage_counters
tenants (1) → (many) domains
tenants (1) → (many) webhooks
tenants (1) → (many) api_keys
tenants (1) → (many) events
```

### Plans → Subscriptions
```
plans (1) → (many) subscriptions
```

### Auth Users → Tenants
```
auth.users (1) → (many) tenants (via owner_id)
```

---

## **📋 Core Fields**

### **tenants**
```sql
id                      UUID (PK)
business_name           VARCHAR(255)
subdomain               VARCHAR(63) UNIQUE
slug                    VARCHAR(63) UNIQUE
owner_id                UUID → auth.users(id)
medusa_region_id        VARCHAR(255)
medusa_sales_channel_id VARCHAR(255)
medusa_stock_location_id VARCHAR(255)
medusa_admin_user_id    VARCHAR(255)
status                  tenant_status
settings                JSONB
metadata                JSONB
provisioned_at          TIMESTAMPTZ
created_at              TIMESTAMPTZ
```

### **plans**
```sql
id                      UUID (PK)
name                    VARCHAR(50)
tier                    plan_tier UNIQUE
monthly_price_cents     INTEGER
annual_price_cents      INTEGER
max_stores              INTEGER
max_products            INTEGER
max_orders_per_month    INTEGER
max_custom_domains      INTEGER
max_staff_accounts      INTEGER
max_asset_storage_gb    INTEGER
features                JSONB
overage_order_price_cents INTEGER
is_active               BOOLEAN
```

### **subscriptions**
```sql
id                      UUID (PK)
tenant_id               UUID → tenants(id)
plan_id                 UUID → plans(id)
stripe_subscription_id  VARCHAR(255) UNIQUE
stripe_customer_id      VARCHAR(255)
status                  subscription_status
current_period_start    TIMESTAMPTZ
current_period_end      TIMESTAMPTZ
trial_start             TIMESTAMPTZ
trial_end               TIMESTAMPTZ
cancel_at_period_end    BOOLEAN
```

### **usage_counters**
```sql
id                      UUID (PK)
tenant_id               UUID → tenants(id)
subscription_id         UUID → subscriptions(id)
period_start            TIMESTAMPTZ
period_end              TIMESTAMPTZ
orders_count            INTEGER
products_count          INTEGER
asset_storage_bytes     BIGINT
bandwidth_bytes         BIGINT
api_calls_count         INTEGER
metadata                JSONB
```

### **domains**
```sql
id                      UUID (PK)
tenant_id               UUID → tenants(id)
domain                  VARCHAR(255) UNIQUE
is_primary              BOOLEAN
status                  domain_status
verification_token      VARCHAR(255)
verified_at             TIMESTAMPTZ
ssl_enabled             BOOLEAN
redirect_to_primary     BOOLEAN
```

---

## **🔐 RLS Policies Summary**

### **plans**
- ✅ Public read access (where `is_active = true`)
- ✅ Service role full access

### **tenants**
- ✅ Users can SELECT/UPDATE their own tenants (via `owner_id`)
- ✅ Service role full access

### **subscriptions**
- ✅ Users can SELECT subscriptions for their tenants
- ✅ Service role full access

### **usage_counters**
- ✅ Users can SELECT usage for their tenants
- ✅ Service role full access

### **domains**
- ✅ Users can SELECT/INSERT/UPDATE/DELETE domains for their tenants
- ✅ Service role full access

### **webhooks**
- ✅ Users can SELECT/INSERT/UPDATE/DELETE webhooks for their tenants
- ✅ Service role full access

### **api_keys**
- ✅ Users can SELECT/INSERT/UPDATE/DELETE API keys for their tenants
- ✅ Service role full access

### **events**
- ✅ Users can SELECT events for their tenants or their own actions
- ✅ Service role full access

---

## **⚡ Helper Functions**

### `get_user_tenant_id()`
Returns the tenant ID for the current authenticated user.

```sql
SELECT get_user_tenant_id();
```

### `user_owns_tenant(tenant_uuid)`
Checks if the current user owns the specified tenant.

```sql
SELECT user_owns_tenant('123e4567-e89b-12d3-a456-426614174000');
```

### `get_current_usage(tenant_uuid)`
Returns current usage stats for a tenant.

```sql
SELECT * FROM get_current_usage('123e4567-e89b-12d3-a456-426614174000');
-- Returns: orders, products, storage_gb, bandwidth_gb, api_calls
```

---

## **📊 Common Queries**

### Get tenant with subscription details
```sql
SELECT 
  t.*,
  p.name as plan_name,
  p.tier,
  s.status as subscription_status,
  s.current_period_end
FROM tenants t
LEFT JOIN subscriptions s ON s.tenant_id = t.id
LEFT JOIN plans p ON p.id = s.plan_id
WHERE t.subdomain = 'my-store';
```

### Check if tenant is over limit
```sql
SELECT 
  t.business_name,
  u.orders_count,
  p.max_orders_per_month,
  CASE 
    WHEN u.orders_count >= p.max_orders_per_month 
    THEN 'Over limit' 
    ELSE 'OK' 
  END as status
FROM usage_counters u
JOIN tenants t ON t.id = u.tenant_id
JOIN subscriptions s ON s.tenant_id = t.id
JOIN plans p ON p.id = s.plan_id
WHERE u.period_end >= NOW();
```

### Get active subscriptions expiring soon
```sql
SELECT 
  t.business_name,
  s.current_period_end,
  s.current_period_end - NOW() as time_until_renewal
FROM subscriptions s
JOIN tenants t ON t.id = s.tenant_id
WHERE s.status = 'active'
  AND s.current_period_end <= NOW() + INTERVAL '7 days'
ORDER BY s.current_period_end;
```

---

## **🎯 Plan Limits Quick Reference**

| Plan | Monthly $ | Products | Orders/mo | Domains | Staff | Storage |
|------|-----------|----------|-----------|---------|-------|---------|
| Free | $0 | 20 | 25 | 0 | 1 | 1 GB |
| Starter | $15 | 200 | 200 | 1 | 2 | 10 GB |
| Pro | $39 | 2,000 | 1,000 | 3 | 5 | 50 GB |
| Growth | $79 | 10,000 | 3,000 | 5 | 10 | 200 GB |
| Scale | $149 | 50,000 | 8,000 | 10 | 20 | 500 GB |
| Enterprise | Custom | 999,999 | 999,999 | 999 | 999 | 9,999 GB |

**Overage Pricing (per order above limit):**
- Starter: $0.06
- Pro: $0.05
- Growth: $0.04
- Scale: $0.03

---

## **🔄 Typical Data Flow**

### Signup Flow
```
1. User signs up → auth.users created
2. Tenant created → tenants.owner_id = auth.users.id
3. Subscription created → links tenant to free plan
4. Usage counter created → tracks current period
5. Subdomain activated → tenant.subdomain + azima.store
```

### Custom Domain Flow
```
1. Domain added → domains.status = 'pending_verification'
2. DNS verified → domains.status = 'verified'
3. SSL issued → domains.ssl_enabled = true
4. Domain activated → domains.status = 'active'
```

### Usage Tracking Flow
```
1. Order placed → webhook fires
2. Usage counter incremented → orders_count++
3. Check limits → compare with plan.max_orders_per_month
4. If over → calculate overage charges
```

---

## **🛠️ Maintenance**

### Monthly Usage Reset
```sql
-- Create new usage counters for next month
INSERT INTO usage_counters (
  tenant_id,
  period_start,
  period_end
)
SELECT 
  id,
  DATE_TRUNC('month', NOW() + INTERVAL '1 month'),
  DATE_TRUNC('month', NOW() + INTERVAL '2 months')
FROM tenants
WHERE status = 'active';
```

### Archive Old Events
```sql
-- Archive events older than 13 months
DELETE FROM events 
WHERE created_at < NOW() - INTERVAL '13 months';
```

### Clean Up Expired Trials
```sql
-- Update subscriptions where trial has ended
UPDATE subscriptions
SET status = 'unpaid'
WHERE status = 'trialing'
  AND trial_end < NOW()
  AND stripe_subscription_id IS NULL;
```

---

## **📚 Related Documentation**

- [SAAS-DATABASE-SETUP.md](SAAS-DATABASE-SETUP.md) - Setup and testing guide
- [README.md](README.md#6) - System architecture overview
- [ROADMAP_TRACKER.md](ROADMAP_TRACKER.md) - Development roadmap

---

**Last Updated:** October 21, 2025  
**Schema Version:** 1.0

