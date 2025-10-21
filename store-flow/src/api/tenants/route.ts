/**
 * Tenant Provisioning API Endpoint (Public - for testing)
 * 
 * POST /tenants
 * 
 * Creates a new tenant with all required Medusa infrastructure
 * 
 * TODO: Add API key authentication before production
 */

import type { MedusaRequest, MedusaResponse } from "@medusajs/framework/http"
import provisionTenant from "../../scripts/provision-tenant"

type CreateTenantRequest = {
  tenantName: string
  tenantEmail: string
  slug: string
  currencyCode: string
  countryCode: string
  adminEmail: string
  adminPassword: string
  adminFirstName: string
  adminLastName: string
  companyAddress?: {
    address_1: string
    city: string
    country_code: string
    province?: string
    postal_code?: string
  }
}

export async function POST(
  req: MedusaRequest<CreateTenantRequest>,
  res: MedusaResponse
) {
  try {
    // Validate request body
    const {
      tenantName,
      tenantEmail,
      slug,
      currencyCode,
      countryCode,
      adminEmail,
      adminPassword,
      adminFirstName,
      adminLastName,
      companyAddress
    } = req.body

    // Basic validation
    if (!tenantName || !slug || !adminEmail || !adminPassword) {
      return res.status(400).json({
        success: false,
        error: "Missing required fields: tenantName, slug, adminEmail, adminPassword"
      })
    }

    // Provision the tenant
    const result = await provisionTenant(req.scope, {
      tenantName,
      tenantEmail: tenantEmail || `hello@${slug}.azima.store`,
      slug,
      currencyCode: currencyCode || "kes",
      countryCode: countryCode || "ke",
      adminEmail,
      adminPassword,
      adminFirstName: adminFirstName || "Admin",
      adminLastName: adminLastName || "User",
      companyAddress
    })

    if (result.success) {
      return res.status(201).json({
        success: true,
        message: "Tenant provisioned successfully",
        data: {
          tenant: result.tenant,
          region: result.region,
          adminUser: result.adminUser,
          salesChannel: result.salesChannel,
          stockLocation: result.stockLocation
        }
      })
    } else {
      return res.status(500).json({
        success: false,
        error: "Tenant provisioning failed",
        errors: result.errors
      })
    }

  } catch (error) {
    console.error("Tenant creation error:", error)
    return res.status(500).json({
      success: false,
      error: error.message || "Internal server error"
    })
  }
}

