/**
 * Admin tenant-scoped products endpoint
 * 
 * Example of how to implement region-based filtering in Admin API routes
 */

import { MedusaRequest, MedusaResponse } from "@medusajs/framework/http"
import {
  adminRegionGuard,
  requireAdminAuth,
} from "../../../middlewares/admin-region-guard"
import { getProductsFilter } from "../../../utils/region-filter"

/**
 * GET /admin/products-scoped
 * 
 * Returns products scoped to the admin user's assigned region
 * 
 * Requires:
 * - Admin authentication
 * - Admin user must have region_id in metadata
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
    // Tenant context should be set by adminRegionGuard middleware
    if (!req.tenantContext) {
      return res.status(403).json({
        error: "Access denied",
        message: "Admin user must have an assigned region",
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

    // For now, let's return mock admin products
    // In a real implementation, you'd query actual products from Medusa
    const mockProducts = [
      {
        id: "prod_1",
        title: "Admin Product 1",
        description: "Admin view of product for tenant: " + req.tenantContext.tenantId,
        region_id: req.tenantContext.regionId,
        admin_notes: "This product is managed by admin user",
      },
      {
        id: "prod_2", 
        title: "Admin Product 2",
        description: "Another admin product for tenant: " + req.tenantContext.tenantId,
        region_id: req.tenantContext.regionId,
        admin_notes: "This product needs review",
      }
    ]

    // Return mock admin products
    res.json({
      products: mockProducts,
      count: mockProducts.length,
      limit,
      offset,
      region_id: req.tenantContext.regionId,
      admin_user_id: req.user?.id,
      note: "This is a mock admin response. In production, you'd query actual products from Medusa.",
      filter_applied: filter,
    })
  } catch (error) {
    console.error("Error fetching admin scoped products:", error)
    res.status(500).json({
      error: "Internal server error",
      message: "Failed to fetch products",
    })
  }
}

/**
 * Apply admin authentication and region guard middleware
 */
export const config = {
  middlewares: [requireAdminAuth, adminRegionGuard],
}

