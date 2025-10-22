# **Real Products Integration Plan**

## **🎯 Overview**

This document outlines the plan to replace mock product endpoints with real database queries using Medusa's product service.

## **📋 Current Status (Day 8)**

### **✅ Completed**
- Tenant isolation middleware working
- Region-based filtering logic implemented
- Mock endpoints for testing
- Error handling and validation

### **🔄 Next Steps (Day 9+)**
- Connect to Medusa Product Service
- Implement real database queries
- Add proper authentication
- Handle database errors

---

## **🔧 Implementation Phases**

### **Phase 1: Service Integration (Day 9)**

#### **1.1 Fix Service Resolution**
**Problem:** `AwilixResolutionError: Could not resolve 'productService'`

**Solution:** Use Medusa v2's proper service injection
```typescript
// Instead of:
const productService = req.scope.resolve("productService")

// Use:
const productModuleService = req.scope.resolve("productModuleService")
```

#### **1.2 Create Product Service Helper**
```typescript
// store-flow/src/services/product-helper.ts
export class ProductServiceHelper {
  static async getProductsByRegion(
    productModuleService: any,
    regionId: string,
    options: any = {}
  ) {
    // Query products filtered by region_id
    return await productModuleService.listAndCount(
      { region_id: regionId },
      options
    )
  }
}
```

### **Phase 2: Real Endpoints (Day 9)**

#### **2.1 Update Store Products Endpoint**
```typescript
// store-flow/src/api/store/products-scoped/route.ts
export async function GET(req: MedusaRequest, res: MedusaResponse) {
  try {
    // Get product service
    const productModuleService = req.scope.resolve("productModuleService")
    
    // Build region filter
    const filter = getProductsFilter(req, { region_id: req.tenantContext.regionId })
    
    // Query real products
    const [products, count] = await productModuleService.listAndCount(
      filter,
      { limit, offset }
    )
    
    res.json({ products, count, region_id: req.tenantContext.regionId })
  } catch (error) {
    // Handle errors
  }
}
```

#### **2.2 Update Admin Products Endpoint**
```typescript
// store-flow/src/api/admin/products-scoped/route.ts
export async function GET(req: MedusaRequest, res: MedusaResponse) {
  try {
    // Get product service
    const productModuleService = req.scope.resolve("productModuleService")
    
    // Build admin-specific filter
    const filter = getProductsFilter(req, { 
      region_id: req.tenantContext.regionId,
      // Add admin-specific filters
    })
    
    // Query real products with admin context
    const [products, count] = await productModuleService.listAndCount(
      filter,
      { limit, offset }
    )
    
    res.json({ products, count, admin_context: true })
  } catch (error) {
    // Handle errors
  }
}
```

### **Phase 3: Authentication Integration (Day 9)**

#### **3.1 Fix Admin Authentication**
**Problem:** Real admin endpoints require proper JWT tokens

**Solution:** 
1. **Use Medusa's built-in auth** for real endpoints
2. **Keep mock endpoints** for testing
3. **Create hybrid approach** for development

#### **3.2 Authentication Strategy**
```typescript
// Option 1: Real authentication (production)
export const config = {
  middlewares: [requireAdminAuth, adminRegionGuard],
}

// Option 2: Mock authentication (development)
export const AUTHENTICATE = false

// Option 3: Hybrid (best of both)
const isDevelopment = process.env.NODE_ENV === 'development'
export const config = isDevelopment ? { AUTHENTICATE: false } : {
  middlewares: [requireAdminAuth, adminRegionGuard],
}
```

### **Phase 4: Database Schema Updates (Day 9)**

#### **4.1 Ensure Products Have Region ID**
```sql
-- Check if products table has region_id column
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'product' AND column_name = 'region_id';

-- If not, add it
ALTER TABLE product ADD COLUMN region_id VARCHAR(255);
```

#### **4.2 Create Region-Product Relationships**
```sql
-- Create index for performance
CREATE INDEX idx_product_region_id ON product(region_id);

-- Update existing products with region_id
UPDATE product SET region_id = 'reg_01JH9HNBBAWS9PS1F31S1XD9HNTBBQ' 
WHERE region_id IS NULL;
```

---

## **🚀 Implementation Timeline**

### **Day 9: Service Integration**
- [ ] Fix AwilixResolutionError
- [ ] Create ProductServiceHelper
- [ ] Update store products endpoint
- [ ] Update admin products endpoint
- [ ] Test with real database

### **Day 10: Authentication & Polish**
- [ ] Fix admin authentication
- [ ] Add proper error handling
- [ ] Performance optimization
- [ ] Documentation updates

---

## **🧪 Testing Strategy**

### **Development Testing**
1. **Keep mock endpoints** for quick testing
2. **Add real endpoints** alongside mocks
3. **Compare responses** to ensure consistency
4. **Gradually replace** mocks with real data

### **Production Testing**
1. **Test with real products** in database
2. **Verify region filtering** works correctly
3. **Test authentication** with real users
4. **Performance testing** with large datasets

---

## **📊 Expected Benefits**

### **Real Data Integration**
- ✅ **Actual products** from database
- ✅ **Real-time updates** when products change
- ✅ **Proper relationships** with variants, prices, etc.
- ✅ **Full Medusa functionality** available

### **Performance**
- ✅ **Database indexing** for fast queries
- ✅ **Caching** for frequently accessed data
- ✅ **Pagination** for large product catalogs
- ✅ **Search functionality** with real data

### **Maintainability**
- ✅ **Standard Medusa patterns** used
- ✅ **Proper error handling** for database issues
- ✅ **Type safety** with TypeScript
- ✅ **Easy to extend** with new features

---

## **🔧 Quick Start**

### **Step 1: Test Current Mock Endpoints**
```bash
# Test that mocks are working
curl -H "x-tenant-subdomain: johns-store" \
     http://localhost:9000/test-products
```

### **Step 2: Create Real Endpoints**
- Copy mock endpoints to new files
- Replace mock data with real service calls
- Test side-by-side with mocks

### **Step 3: Gradual Migration**
- Keep both mock and real endpoints
- Test real endpoints thoroughly
- Replace mocks when confident

---

**This plan ensures a smooth transition from mock data to real database integration while maintaining the tenant isolation functionality we've built!** 🎯
