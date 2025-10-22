/**
 * Simple admin test endpoint
 * 
 * Tests admin tenant-scoped functionality without authentication
 */

import { MedusaRequest, MedusaResponse } from "@medusajs/framework/http"

export async function GET(
  req: MedusaRequest,
  res: MedusaResponse
) {
  try {
    // Check if tenant context was attached by middleware
    if (!req.tenantContext) {
      return res.status(400).json({
        success: false,
        message: "No tenant context found",
        hint: "Add x-tenant-subdomain header to your request",
      })
    }

    // Get products scoped to tenant's region
    const regionId = req.tenantContext.regionId
    
    if (!regionId) {
      return res.status(400).json({
        success: false,
        message: "No region ID found for tenant",
        tenant: req.tenantContext,
      })
    }

    // Mock admin products
    const mockAdminProducts = [
      {
        id: "admin_prod_1",
        title: "Admin Product 1",
        description: "Admin-managed product for tenant: " + req.tenantContext.tenantId,
        region_id: regionId,
        admin_notes: "This product is managed by admin",
        status: "active",
        created_by: "admin_user",
      },
      {
        id: "admin_prod_2", 
        title: "Admin Product 2",
        description: "Another admin product for tenant: " + req.tenantContext.tenantId,
        region_id: regionId,
        admin_notes: "This product needs review",
        status: "draft",
        created_by: "admin_user",
      }
    ]

    return res.json({
      success: true,
      message: "Admin tenant-scoped products endpoint working!",
      tenant: {
        tenantId: req.tenantContext.tenantId,
        regionId: req.tenantContext.regionId,
        subdomain: req.tenantContext.subdomain,
        businessName: req.tenantContext.businessName,
      },
      products: mockAdminProducts,
      count: mockAdminProducts.length,
      regionFilter: {
        region_id: regionId
      },
      note: "This would normally return products filtered by region_id with admin permissions"
    })
  } catch (error) {
    console.error("Error in test-admin endpoint:", error)
    return res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    })
  }
}

// No authentication required
export const AUTHENTICATE = false


