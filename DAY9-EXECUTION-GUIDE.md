# **Day 9: Real Products Integration & API Layer**

## **🎯 Overview**

**Goal:** Replace mock product endpoints with real database queries and implement the SaaS API integration layer.

**Focus Areas:**
1. **Real Products Integration** - Connect to Medusa's product service
2. **API Integration Layer** - Create SaaS signup and user provisioning APIs
3. **Database Integration** - Use real products with tenant isolation

---

## **📋 Pre-Day 9 Checklist**

### **✅ Prerequisites (Day 8 Complete)**
- [x] Tenant isolation middleware working
- [x] Region-based filtering implemented
- [x] Mock endpoints tested and working
- [x] Authentication system in place
- [x] Error handling implemented

### **🔧 Environment Setup**
- [ ] Medusa server running on `localhost:9000`
- [ ] Redis running for caching
- [ ] Supabase databases connected
- [ ] Test tenant data available

---

## **🚀 Phase 1: Real Products Integration**

### **Step 1.1: Fix Service Resolution Error**

**Problem:** `AwilixResolutionError: Could not resolve 'productService'`

**Solution:** Use Medusa v2's proper service injection

**File:** `store-flow/src/services/product-helper.ts`
```typescript
import { MedusaRequest } from "@medusajs/framework/http"

export class ProductServiceHelper {
  /**
   * Get products filtered by region_id
   */
  static async getProductsByRegion(
    req: MedusaRequest,
    regionId: string,
    options: {
      limit?: number
      offset?: number
      q?: string
    } = {}
  ) {
    try {
      // Get the product module service
      const productModuleService = req.scope.resolve("productModuleService")
      
      // Build filter with region_id
      const filter: any = {
        region_id: regionId
      }
      
      // Add search query if provided
      if (options.q) {
        filter.title = { $ilike: `%${options.q}%` }
      }
      
      // Query products
      const [products, count] = await productModuleService.listAndCount(
        filter,
        {
          limit: options.limit || 50,
          offset: options.offset || 0,
          relations: ["variants", "images", "categories"]
        }
      )
      
      return { products, count }
    } catch (error) {
      console.error("Error fetching products by region:", error)
      throw error
    }
  }
  
  /**
   * Get admin products with additional admin context
   */
  static async getAdminProductsByRegion(
    req: MedusaRequest,
    regionId: string,
    options: any = {}
  ) {
    try {
      const productModuleService = req.scope.resolve("productModuleService")
      
      // Admin-specific filter
      const filter: any = {
        region_id: regionId,
        // Add admin-specific filters here
      }
      
      const [products, count] = await productModuleService.listAndCount(
        filter,
        {
          limit: options.limit || 50,
          offset: options.offset || 0,
          relations: ["variants", "images", "categories", "tags"]
        }
      )
      
      return { products, count }
    } catch (error) {
      console.error("Error fetching admin products by region:", error)
      throw error
    }
  }
}
```

### **Step 1.2: Update Store Products Endpoint**

**File:** `store-flow/src/api/store/products-real/route.ts`
```typescript
import { MedusaRequest, MedusaResponse } from "@medusajs/framework/http"
import { ProductServiceHelper } from "../../../services/product-helper"

export async function GET(
  req: MedusaRequest,
  res: MedusaResponse
) {
  try {
    // Check tenant context
    if (!req.tenantContext) {
      return res.status(400).json({
        success: false,
        message: "No tenant context found",
        hint: "Add x-tenant-subdomain header to your request",
      })
    }

    // Get query parameters
    const limit = parseInt(req.query.limit as string) || 50
    const offset = parseInt(req.query.offset as string) || 0
    const q = req.query.q as string | undefined

    // Get products from database
    const { products, count } = await ProductServiceHelper.getProductsByRegion(
      req,
      req.tenantContext.regionId,
      { limit, offset, q }
    )

    // Return real products
    res.json({
      success: true,
      message: "Products retrieved successfully!",
      products,
      count,
      region_id: req.tenantContext.regionId,
      tenant_id: req.tenantContext.tenantId,
      pagination: {
        limit,
        offset,
        total: count,
        has_more: (offset + limit) < count
      }
    })
  } catch (error) {
    console.error("Error fetching store products:", error)
    res.status(500).json({
      success: false,
      error: "Internal server error",
      message: "Failed to fetch products",
    })
  }
}

export const AUTHENTICATE = false
```

### **Step 1.3: Update Admin Products Endpoint**

**File:** `store-flow/src/api/admin/products-real/route.ts`
```typescript
import { MedusaRequest, MedusaResponse } from "@medusajs/framework/http"
import { ProductServiceHelper } from "../../../services/product-helper"

export async function GET(
  req: MedusaRequest,
  res: MedusaResponse
) {
  try {
    // Check tenant context
    if (!req.tenantContext) {
      return res.status(400).json({
        success: false,
        message: "No tenant context found",
        hint: "Add x-tenant-subdomain header to your request",
      })
    }

    // Check authentication (mock for now)
    const authHeader = req.headers.authorization
    const mockToken = authHeader?.replace('Bearer ', '')
    
    if (!mockToken || !mockToken.startsWith('mock_jwt_token_')) {
      return res.status(401).json({
        success: false,
        message: "Invalid or missing authentication token",
        hint: "Use the token from /test-auth endpoint",
      })
    }

    // Get query parameters
    const limit = parseInt(req.query.limit as string) || 50
    const offset = parseInt(req.query.offset as string) || 0
    const q = req.query.q as string | undefined

    // Get admin products from database
    const { products, count } = await ProductServiceHelper.getAdminProductsByRegion(
      req,
      req.tenantContext.regionId,
      { limit, offset, q }
    )

    // Return real admin products
    res.json({
      success: true,
      message: "Admin products retrieved successfully!",
      products,
      count,
      region_id: req.tenantContext.regionId,
      tenant_id: req.tenantContext.tenantId,
      admin_context: true,
      pagination: {
        limit,
        offset,
        total: count,
        has_more: (offset + limit) < count
      }
    })
  } catch (error) {
    console.error("Error fetching admin products:", error)
    res.status(500).json({
      success: false,
      error: "Internal server error",
      message: "Failed to fetch admin products",
    })
  }
}

export const AUTHENTICATE = false
```

### **Step 1.4: Add New Endpoints to Middleware**

**File:** `store-flow/src/api/middlewares.ts`
```typescript
// Add these new routes
{
  matcher: "/store/products-real",
  middlewares: [tenantContextMiddleware],
},
{
  matcher: "/admin/products-real",
  middlewares: [tenantContextMiddleware],
},
```

---

## **🚀 Phase 2: SaaS API Integration Layer**

### **Step 2.1: Create SaaS Signup API**

**File:** `store-flow/src/api/saas/signup/route.ts`
```typescript
import { MedusaRequest, MedusaResponse } from "@medusajs/framework/http"
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.SAAS_SUPABASE_URL!,
  process.env.SAAS_SUPABASE_SERVICE_KEY!
)

export async function POST(
  req: MedusaRequest,
  res: MedusaResponse
) {
  try {
    const { 
      businessName, 
      email, 
      password, 
      firstName, 
      lastName 
    } = req.body

    // Validate input
    if (!businessName || !email || !password || !firstName || !lastName) {
      return res.status(400).json({
        success: false,
        message: "All fields are required",
      })
    }

    // Step 1: Create Supabase user
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email,
      password,
      user_metadata: {
        first_name: firstName,
        last_name: lastName,
        business_name: businessName
      }
    })

    if (authError) {
      return res.status(400).json({
        success: false,
        message: "Failed to create user",
        error: authError.message
      })
    }

    // Step 2: Create tenant record
    const { data: tenantData, error: tenantError } = await supabase
      .from('tenants')
      .insert({
        business_name: businessName,
        subdomain: businessName.toLowerCase().replace(/\s+/g, '-'),
        slug: businessName.toLowerCase().replace(/\s+/g, '-'),
        owner_id: authData.user.id,
        status: 'provisioning'
      })
      .select()
      .single()

    if (tenantError) {
      return res.status(400).json({
        success: false,
        message: "Failed to create tenant",
        error: tenantError.message
      })
    }

    // Step 3: Provision Medusa infrastructure
    // (This would call your existing tenant provisioning API)
    
    // Step 4: Create Medusa admin user
    // (This would use Medusa CLI or API)

    res.json({
      success: true,
      message: "Signup successful!",
      user: {
        id: authData.user.id,
        email: authData.user.email,
        business_name: businessName
      },
      tenant: {
        id: tenantData.id,
        subdomain: tenantData.subdomain,
        status: tenantData.status
      }
    })
  } catch (error) {
    console.error("Error in signup:", error)
    res.status(500).json({
      success: false,
      error: "Internal server error",
      message: "Failed to process signup",
    })
  }
}

export const AUTHENTICATE = false
```

### **Step 2.2: Create Tenant Provisioning API**

**File:** `store-flow/src/api/saas/tenants/route.ts`
```typescript
import { MedusaRequest, MedusaResponse } from "@medusajs/framework/http"

export async function POST(
  req: MedusaRequest,
  res: MedusaResponse
) {
  try {
    const { tenantId } = req.body

    if (!tenantId) {
      return res.status(400).json({
        success: false,
        message: "Tenant ID is required",
      })
    }

    // Provision Medusa infrastructure
    // 1. Create Region
    // 2. Create Sales Channel
    // 3. Create Stock Location
    // 4. Create Shipping Options
    // 5. Create Fulfillment Set

    // Mock response for now
    res.json({
      success: true,
      message: "Tenant provisioned successfully!",
      tenant_id: tenantId,
      medusa_region_id: "reg_mock_" + Date.now(),
      status: "provisioned"
    })
  } catch (error) {
    console.error("Error provisioning tenant:", error)
    res.status(500).json({
      success: false,
      error: "Internal server error",
      message: "Failed to provision tenant",
    })
  }
}

export const AUTHENTICATE = false
```

---

## **🧪 Testing Strategy**

### **Phase 1 Testing: Real Products**
1. **Test store products endpoint:**
   ```bash
   curl -H "x-tenant-subdomain: johns-store" \
        http://localhost:9000/store/products-real
   ```

2. **Test admin products endpoint:**
   ```bash
   # Get token first
   curl -X POST http://localhost:9000/test-auth \
        -H "Content-Type: application/json" \
        -d '{"email": "admin@azima.store", "password": "supersecret"}'
   
   # Use token
   curl -H "x-tenant-subdomain: johns-store" \
        -H "Authorization: Bearer YOUR_TOKEN" \
        http://localhost:9000/admin/products-real
   ```

### **Phase 2 Testing: SaaS APIs**
1. **Test signup API:**
   ```bash
   curl -X POST http://localhost:9000/saas/signup \
        -H "Content-Type: application/json" \
        -d '{
          "businessName": "Test Store",
          "email": "test@example.com",
          "password": "password123",
          "firstName": "Test",
          "lastName": "User"
        }'
   ```

2. **Test tenant provisioning:**
   ```bash
   curl -X POST http://localhost:9000/saas/tenants \
        -H "Content-Type: application/json" \
        -d '{"tenantId": "your-tenant-id"}'
   ```

---

## **📊 Success Criteria**

### **Phase 1: Real Products**
- [ ] Store products endpoint returns real data
- [ ] Admin products endpoint returns real data
- [ ] Region filtering works correctly
- [ ] Error handling works for database issues
- [ ] Performance is acceptable

### **Phase 2: SaaS APIs**
- [ ] Signup API creates users and tenants
- [ ] Tenant provisioning API works
- [ ] Error handling for all scenarios
- [ ] Integration between Supabase and Medusa

---

## **🚀 Next Steps After Day 9**

**Day 10: Sprint 0 Review & Testing**
- Test complete tenant provisioning flow
- Verify database connections
- Test deployment pipeline
- Document setup process
- Plan Sprint 1 tasks

---

**Ready to start Day 9?** Let's begin with Phase 1: Real Products Integration! 🎯
