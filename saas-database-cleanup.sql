-- ============================================================================
-- SaaS Database Cleanup Script
-- ============================================================================
-- Purpose: Clean up existing schema before fresh installation
-- WARNING: This will DELETE ALL DATA in these tables!
-- Use only when you need to reset the schema completely
-- ============================================================================

-- ============================================================================
-- STEP 1: Drop Tables (in dependency order)
-- ============================================================================

-- Drop dependent tables first
DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS api_keys CASCADE;
DROP TABLE IF EXISTS webhooks CASCADE;
DROP TABLE IF EXISTS domains CASCADE;
DROP TABLE IF EXISTS usage_counters CASCADE;
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS tenants CASCADE;
DROP TABLE IF EXISTS plans CASCADE;

-- ============================================================================
-- STEP 2: Drop Functions
-- ============================================================================

DROP FUNCTION IF EXISTS get_current_usage(UUID);
DROP FUNCTION IF EXISTS user_owns_tenant(UUID);
DROP FUNCTION IF EXISTS get_user_tenant_id();
DROP FUNCTION IF EXISTS update_updated_at_column();

-- ============================================================================
-- STEP 3: Drop Types/Enums
-- ============================================================================

DROP TYPE IF EXISTS webhook_event_type;
DROP TYPE IF EXISTS domain_status;
DROP TYPE IF EXISTS subscription_status;
DROP TYPE IF EXISTS plan_tier;
DROP TYPE IF EXISTS tenant_status;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 
  'Cleanup Complete!' as status,
  'All tables, functions, and types have been dropped.' as message;

SELECT 
  'Remaining tables (should be empty):' as info,
  COUNT(*) as table_count
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN (
    'plans', 'tenants', 'subscriptions', 'usage_counters',
    'domains', 'webhooks', 'api_keys', 'events'
  );

-- ============================================================================
-- NEXT STEPS
-- ============================================================================

SELECT '
✅ Cleanup complete!

Next steps:
1. Run saas-database-schema.sql to recreate the schema
2. Run saas-database-seed.sql to populate plans
3. Run saas-database-tests.sql to verify

' as next_steps;

-- ============================================================================
-- END OF CLEANUP
-- ============================================================================

