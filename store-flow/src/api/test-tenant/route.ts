/**
 * Simple tenant context test endpoint
 * 
 * No authentication required - just tests tenant resolution
 */

import { MedusaRequest, MedusaResponse } from "@medusajs/framework/http"

export async function GET(
  req: MedusaRequest,
  res: MedusaResponse
) {
  try {
    // Check if tenant context was attached by middleware
    if (req.tenantContext) {
      return res.json({
        success: true,
        message: "Tenant context resolved successfully!",
        tenant: {
          tenantId: req.tenantContext.tenantId,
          regionId: req.tenantContext.regionId,
          subdomain: req.tenantContext.subdomain,
          businessName: req.tenantContext.businessName,
          status: req.tenantContext.status,
        },
        source: req.tenantSource,
      })
    } else {
      return res.status(400).json({
        success: false,
        message: "No tenant context found",
        hint: "Add x-tenant-subdomain header to your request",
      })
    }
  } catch (error) {
    console.error("Error in test-tenant endpoint:", error)
    return res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    })
  }
}

// No authentication required
export const AUTHENTICATE = false

