/**
 * Simple products test endpoint
 * 
 * Tests tenant-scoped product filtering without authentication
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

    // For now, just return the tenant info and region
    // In a real implementation, you'd query Medusa for products in this region
    return res.json({
      success: true,
      message: "Tenant-scoped products endpoint working!",
      tenant: {
        tenantId: req.tenantContext.tenantId,
        regionId: req.tenantContext.regionId,
        subdomain: req.tenantContext.subdomain,
        businessName: req.tenantContext.businessName,
      },
      note: "This would normally return products filtered by region_id",
      regionFilter: {
        region_id: regionId
      }
    })
  } catch (error) {
    console.error("Error in test-products endpoint:", error)
    return res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    })
  }
}

// No authentication required
export const AUTHENTICATE = false

