/**
 * Tenant-scoped products endpoint
 * 
 * Example of how to implement region-based filtering in Store API routes
 */

import { MedusaRequest, MedusaResponse } from "@medusajs/framework/http"
import { requireTenantContext } from "../../../middlewares/tenant-context"
import { getProductsFilter, getSafeRegionId } from "../../../utils/region-filter"

/**
 * GET /store/products-scoped
 * 
 * Returns products scoped to the current tenant's region
 * 
 * Query params:
 * - limit: number (default: 50)
 * - offset: number (default: 0)
 * - q: string (search query)
 */
export async function GET(
  req: MedusaRequest,
  res: MedusaResponse
) {
  try {
    // Ensure tenant context exists
    if (!req.tenantContext) {
      return res.status(400).json({
        error: "Missing tenant context",
        message: "This endpoint requires a valid tenant",
      })
    }

    // Get query parameters
    const limit = parseInt(req.query.limit as string) || 50
    const offset = parseInt(req.query.offset as string) || 0
    const q = req.query.q as string | undefined

    // Build filter with region scope
    const filter = getProductsFilter(req, {
      ...(q && { q }),
    })

    // For now, let's just return the tenant context and filter info
    // In a real implementation, you'd query the actual products here
    const mockProducts = [
      {
        id: "prod_1",
        title: "Sample Product 1",
        description: "This is a sample product for tenant: " + req.tenantContext.tenantId,
        region_id: req.tenantContext.regionId,
      },
      {
        id: "prod_2", 
        title: "Sample Product 2",
        description: "Another sample product for tenant: " + req.tenantContext.tenantId,
        region_id: req.tenantContext.regionId,
      }
    ]

    // Return mock products with tenant context
    res.json({
      products: mockProducts,
      count: mockProducts.length,
      limit,
      offset,
      region_id: req.tenantContext.regionId,
      tenant_id: req.tenantContext.tenantId,
      note: "This is a mock response. In production, you'd query actual products from Medusa.",
      filter_applied: filter,
    })
  } catch (error) {
    console.error("Error fetching scoped products:", error)
    res.status(500).json({
      error: "Internal server error",
      message: "Failed to fetch products",
    })
  }
}

/**
 * Example showing how to use middleware explicitly
 * 
 * You can also apply the middleware in medusa-config.ts globally
 */
export const config = {
  middlewares: [requireTenantContext],
}

// Disable auth requirement for development testing
export const AUTHENTICATE = false

