-- ============================================================================
-- SaaS Database Schema Tests
-- ============================================================================
-- Purpose: Comprehensive tests for the SaaS database schema
-- Run this AFTER schema and seed scripts
-- ============================================================================

-- ============================================================================
-- TEST 1: Verify All Tables Exist
-- ============================================================================

SELECT 
  'TEST 1: Tables Exist' as test_name,
  COUNT(*) as table_count,
  CASE 
    WHEN COUNT(*) = 8 THEN '✅ PASS' 
    ELSE '❌ FAIL' 
  END as status
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN (
    'plans', 'tenants', 'subscriptions', 'usage_counters',
    'domains', 'webhooks', 'api_keys', 'events'
  );

-- ============================================================================
-- TEST 2: Verify RLS is Enabled
-- ============================================================================

SELECT 
  'TEST 2: RLS Enabled' as test_name,
  COUNT(*) as tables_with_rls,
  CASE 
    WHEN COUNT(*) = 8 THEN '✅ PASS' 
    ELSE '❌ FAIL' 
  END as status
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN (
    'plans', 'tenants', 'subscriptions', 'usage_counters',
    'domains', 'webhooks', 'api_keys', 'events'
  )
  AND rowsecurity = true;

-- ============================================================================
-- TEST 3: Verify Plans Seeded
-- ============================================================================

SELECT 
  'TEST 3: Plans Seeded' as test_name,
  COUNT(*) as plan_count,
  CASE 
    WHEN COUNT(*) >= 5 THEN '✅ PASS' 
    ELSE '❌ FAIL' 
  END as status
FROM plans;

-- Display plan details
SELECT 
  tier,
  name,
  monthly_price_cents / 100.0 as monthly_usd,
  max_products,
  max_orders_per_month
FROM plans
ORDER BY sort_order;

-- ============================================================================
-- TEST 4: Verify Enums Created
-- ============================================================================

SELECT 
  'TEST 4: Enums Created' as test_name,
  COUNT(*) as enum_count,
  CASE 
    WHEN COUNT(*) >= 5 THEN '✅ PASS' 
    ELSE '❌ FAIL' 
  END as status
FROM pg_type 
WHERE typname IN (
  'tenant_status', 'plan_tier', 'subscription_status',
  'domain_status', 'webhook_event_type'
);

-- ============================================================================
-- TEST 5: Verify Indexes Created
-- ============================================================================

SELECT 
  'TEST 5: Indexes Created' as test_name,
  COUNT(*) as index_count,
  CASE 
    WHEN COUNT(*) >= 20 THEN '✅ PASS' 
    ELSE '❌ FAIL' 
  END as status
FROM pg_indexes 
WHERE schemaname = 'public'
  AND tablename IN (
    'plans', 'tenants', 'subscriptions', 'usage_counters',
    'domains', 'webhooks', 'api_keys', 'events'
  );

-- ============================================================================
-- TEST 6: Verify Triggers Created
-- ============================================================================

SELECT 
  'TEST 6: Triggers Created' as test_name,
  COUNT(*) as trigger_count,
  CASE 
    WHEN COUNT(*) >= 7 THEN '✅ PASS' 
    ELSE '❌ FAIL' 
  END as status
FROM pg_trigger 
WHERE tgname LIKE '%updated_at%';

-- ============================================================================
-- TEST 7: Verify Helper Functions
-- ============================================================================

SELECT 
  'TEST 7: Helper Functions' as test_name,
  COUNT(*) as function_count,
  CASE 
    WHEN COUNT(*) >= 3 THEN '✅ PASS' 
    ELSE '❌ FAIL' 
  END as status
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname IN (
    'get_user_tenant_id',
    'user_owns_tenant',
    'get_current_usage'
  );

-- ============================================================================
-- TEST 8: Create Test Tenant (Integration Test)
-- ============================================================================

-- Note: This requires a real user ID from auth.users
-- Replace the UUID below with an actual user ID from your Supabase project

DO $$
DECLARE
  test_tenant_id UUID;
  test_user_id UUID;
  free_plan_id UUID;
  test_subscription_id UUID;
BEGIN
  -- Try to get a user ID from auth.users (if any exist)
  SELECT id INTO test_user_id FROM auth.users LIMIT 1;
  
  IF test_user_id IS NULL THEN
    RAISE NOTICE 'TEST 8: SKIPPED - No users in auth.users';
    RETURN;
  END IF;

  -- Get free plan
  SELECT id INTO free_plan_id FROM plans WHERE tier = 'free';

  -- Create test tenant
  INSERT INTO tenants (
    business_name,
    subdomain,
    slug,
    owner_id,
    status
  ) VALUES (
    'Test Store ' || to_char(NOW(), 'YYYYMMDDHH24MISS'),
    'test-' || to_char(NOW(), 'YYYYMMDDHH24MISS'),
    'test-' || to_char(NOW(), 'YYYYMMDDHH24MISS'),
    test_user_id,
    'active'
  ) RETURNING id INTO test_tenant_id;

  -- Create subscription
  INSERT INTO subscriptions (
    tenant_id,
    plan_id,
    status,
    current_period_start,
    current_period_end
  ) VALUES (
    test_tenant_id,
    free_plan_id,
    'trialing',
    NOW(),
    NOW() + INTERVAL '30 days'
  ) RETURNING id INTO test_subscription_id;

  -- Create usage counter
  INSERT INTO usage_counters (
    tenant_id,
    subscription_id,
    period_start,
    period_end,
    orders_count,
    products_count
  ) VALUES (
    test_tenant_id,
    test_subscription_id,
    DATE_TRUNC('month', NOW()),
    DATE_TRUNC('month', NOW()) + INTERVAL '1 month',
    0,
    0
  );

  -- Create domain
  INSERT INTO domains (
    tenant_id,
    domain,
    is_primary,
    status
  ) VALUES (
    test_tenant_id,
    'test-' || to_char(NOW(), 'YYYYMMDDHH24MISS') || '.example.com',
    true,
    'pending_verification'
  );

  -- Create webhook
  INSERT INTO webhooks (
    tenant_id,
    url,
    events,
    is_active
  ) VALUES (
    test_tenant_id,
    'https://example.com/webhook',
    ARRAY['orders.created', 'orders.paid']::webhook_event_type[],
    true
  );

  -- Create API key
  INSERT INTO api_keys (
    tenant_id,
    name,
    key_prefix,
    key_hash,
    scopes
  ) VALUES (
    test_tenant_id,
    'Test API Key',
    'azima_test',
    encode(sha256(('test-key-' || test_tenant_id::text)::bytea), 'hex'),
    ARRAY['read', 'write']::TEXT[]
  );

  -- Create event
  INSERT INTO events (
    tenant_id,
    user_id,
    event_type,
    event_category,
    resource_type,
    resource_id,
    payload
  ) VALUES (
    test_tenant_id,
    test_user_id,
    'tenant.created',
    'tenant_management',
    'tenant',
    test_tenant_id::TEXT,
    jsonb_build_object('test', true, 'created_at', NOW())
  );

  RAISE NOTICE 'TEST 8: ✅ PASS - Created test tenant: %', test_tenant_id;
END $$;

-- ============================================================================
-- TEST 9: Verify Foreign Key Constraints
-- ============================================================================

SELECT 
  'TEST 9: Foreign Keys' as test_name,
  COUNT(*) as fk_count,
  CASE 
    WHEN COUNT(*) >= 10 THEN '✅ PASS' 
    ELSE '❌ FAIL' 
  END as status
FROM information_schema.table_constraints 
WHERE constraint_schema = 'public'
  AND constraint_type = 'FOREIGN KEY'
  AND table_name IN (
    'tenants', 'subscriptions', 'usage_counters',
    'domains', 'webhooks', 'api_keys', 'events'
  );

-- ============================================================================
-- TEST 10: Verify Unique Constraints
-- ============================================================================

SELECT 
  'TEST 10: Unique Constraints' as test_name,
  COUNT(*) as unique_count,
  CASE 
    WHEN COUNT(*) >= 5 THEN '✅ PASS' 
    ELSE '❌ FAIL' 
  END as status
FROM information_schema.table_constraints 
WHERE constraint_schema = 'public'
  AND constraint_type = 'UNIQUE'
  AND table_name IN (
    'plans', 'tenants', 'subscriptions', 'domains', 'api_keys'
  );

-- ============================================================================
-- TEST 11: Test Subdomain Validation
-- ============================================================================

DO $$
BEGIN
  -- Try to create tenant with invalid subdomain
  BEGIN
    INSERT INTO tenants (
      business_name,
      subdomain,
      slug,
      owner_id,
      status
    ) VALUES (
      'Invalid Test',
      'INVALID-SUBDOMAIN-123!',
      'test',
      '00000000-0000-0000-0000-000000000000',
      'active'
    );
    RAISE NOTICE 'TEST 11: ❌ FAIL - Invalid subdomain was accepted';
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'TEST 11: ✅ PASS - Invalid subdomain rejected correctly';
  END;
END $$;

-- ============================================================================
-- TEST 12: Test Updated_at Trigger
-- ============================================================================

DO $$
DECLARE
  test_tenant_id UUID;
  original_updated_at TIMESTAMPTZ;
  new_updated_at TIMESTAMPTZ;
BEGIN
  -- Get a test tenant
  SELECT id, updated_at INTO test_tenant_id, original_updated_at 
  FROM tenants 
  WHERE subdomain LIKE 'test-%'
  LIMIT 1;

  IF test_tenant_id IS NULL THEN
    RAISE NOTICE 'TEST 12: SKIPPED - No test tenant found';
    RETURN;
  END IF;

  -- Sleep for 1 second
  PERFORM pg_sleep(1);

  -- Update the tenant
  UPDATE tenants 
  SET business_name = business_name || ' (Updated)'
  WHERE id = test_tenant_id;

  -- Check if updated_at changed
  SELECT updated_at INTO new_updated_at
  FROM tenants
  WHERE id = test_tenant_id;

  IF new_updated_at > original_updated_at THEN
    RAISE NOTICE 'TEST 12: ✅ PASS - updated_at trigger working';
  ELSE
    RAISE NOTICE 'TEST 12: ❌ FAIL - updated_at not updated';
  END IF;
END $$;

-- ============================================================================
-- TEST 13: Test RLS Policies (Service Role)
-- ============================================================================

-- Service role should see all tenants
SELECT 
  'TEST 13: Service Role Access' as test_name,
  COUNT(*) as tenant_count,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ PASS' 
    ELSE '⚠️  WARN - No tenants to test' 
  END as status
FROM tenants;

-- ============================================================================
-- TEST 14: Verify Cascade Deletes
-- ============================================================================

DO $$
DECLARE
  test_tenant_id UUID;
  related_count INTEGER;
BEGIN
  -- Get a test tenant
  SELECT id INTO test_tenant_id 
  FROM tenants 
  WHERE subdomain LIKE 'test-%'
  LIMIT 1;

  IF test_tenant_id IS NULL THEN
    RAISE NOTICE 'TEST 14: SKIPPED - No test tenant found';
    RETURN;
  END IF;

  -- Count related records before delete
  SELECT 
    COUNT(*) INTO related_count
  FROM (
    SELECT tenant_id FROM subscriptions WHERE tenant_id = test_tenant_id
    UNION ALL
    SELECT tenant_id FROM usage_counters WHERE tenant_id = test_tenant_id
    UNION ALL
    SELECT tenant_id FROM domains WHERE tenant_id = test_tenant_id
    UNION ALL
    SELECT tenant_id FROM webhooks WHERE tenant_id = test_tenant_id
    UNION ALL
    SELECT tenant_id FROM api_keys WHERE tenant_id = test_tenant_id
  ) related;

  -- Delete tenant (should cascade)
  DELETE FROM tenants WHERE id = test_tenant_id;

  -- Verify all related records are gone
  SELECT 
    COUNT(*) INTO related_count
  FROM (
    SELECT tenant_id FROM subscriptions WHERE tenant_id = test_tenant_id
    UNION ALL
    SELECT tenant_id FROM usage_counters WHERE tenant_id = test_tenant_id
    UNION ALL
    SELECT tenant_id FROM domains WHERE tenant_id = test_tenant_id
    UNION ALL
    SELECT tenant_id FROM webhooks WHERE tenant_id = test_tenant_id
    UNION ALL
    SELECT tenant_id FROM api_keys WHERE tenant_id = test_tenant_id
  ) related;

  IF related_count = 0 THEN
    RAISE NOTICE 'TEST 14: ✅ PASS - CASCADE delete working';
  ELSE
    RAISE NOTICE 'TEST 14: ❌ FAIL - % related records not deleted', related_count;
  END IF;
END $$;

-- ============================================================================
-- TEST SUMMARY
-- ============================================================================

SELECT '
╔══════════════════════════════════════════════════════════════╗
║                    TEST SUITE SUMMARY                        ║
╚══════════════════════════════════════════════════════════════╝

All tests completed. Check output above for results.

✅ PASS - Test passed successfully
❌ FAIL - Test failed, needs attention
⚠️  WARN - Test passed with warnings
SKIPPED - Test skipped (missing dependencies)

' as summary;

-- ============================================================================
-- CLEANUP TEST DATA
-- ============================================================================

-- Uncomment to clean up test data
-- DELETE FROM tenants WHERE subdomain LIKE 'test-%';

SELECT '
To clean up test data, run:
  DELETE FROM tenants WHERE subdomain LIKE ''test-%'';

' as cleanup_note;

-- ============================================================================
-- END OF TESTS
-- ============================================================================

