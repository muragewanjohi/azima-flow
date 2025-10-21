#!/bin/bash

# Test Tenant Provisioning API
# Usage: ./test-api.sh

echo "🧪 Testing Tenant Provisioning API"
echo "=================================="
echo ""

# Test 1: Create Nairobi Electronics tenant
echo "Test 1: Creating Nairobi Electronics tenant..."
curl -X POST http://localhost:9000/tenants \
  -H "Content-Type: application/json" \
  -d '{
    "tenantName": "Nairobi Electronics",
    "slug": "nairobi-electronics",
    "adminEmail": "admin@nairobielectronics.co.ke",
    "adminPassword": "secure123456",
    "adminFirstName": "John",
    "adminLastName": "Kamau"
  }'

echo ""
echo ""
echo "=================================="
echo "✅ Test complete!"
echo ""
echo "Login details:"
echo "URL: http://localhost:9000/app"
echo "Email: admin@nairobielectronics.co.ke"
echo "Password: secure123456"

