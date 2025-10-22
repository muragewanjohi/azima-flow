/**
 * Tenant Context Middleware
 * 
 * Extracts tenant information from incoming requests and attaches to req.tenantContext
 */

import { MedusaNextFunction, MedusaRequest, MedusaResponse } from "@medusajs/framework/http"
import { tenantService } from "../services/tenant"
import {
  TenantSource,
  TenantNotFoundError,
  TenantSuspendedError,
} from "../types/tenant-context"

/**
 * Extract subdomain from hostname
 * 
 * Examples:
 * - johns-store.azima.store → johns-store
 * - localhost:9000 → null (development)
 * - azima.store → null (main domain)
 */
function extractSubdomain(hostname: string): string | null {
  const baseDomain = process.env.BASE_DOMAIN || "azima.store"
  
  // Remove port if present
  const host = hostname.split(":")[0]
  
  // Check if it's a subdomain of base domain
  if (host.endsWith(`.${baseDomain}`)) {
    const subdomain = host.replace(`.${baseDomain}`, "")
    return subdomain || null
  }
  
  // Check if it's the base domain itself
  if (host === baseDomain) {
    return null
  }
  
  // Development: localhost, 127.0.0.1, etc.
  if (
    host === "localhost" ||
    host.startsWith("127.") ||
    host.startsWith("192.168.") ||
    host.startsWith("10.")
  ) {
    // In development, check for x-tenant-subdomain header
    return null
  }
  
  // Otherwise, treat it as a custom domain
  return null
}

/**
 * Check if hostname is a custom domain
 */
function isCustomDomain(hostname: string): boolean {
  const baseDomain = process.env.BASE_DOMAIN || "azima.store"
  const host = hostname.split(":")[0]
  
  // Not a subdomain and not localhost
  if (
    !host.endsWith(`.${baseDomain}`) &&
    host !== baseDomain &&
    host !== "localhost" &&
    !host.startsWith("127.") &&
    !host.startsWith("192.168.") &&
    !host.startsWith("10.")
  ) {
    return true
  }
  
  return false
}

/**
 * Tenant Context Middleware
 * 
 * Resolution priority:
 * 1. x-api-key header (for API access)
 * 2. x-tenant-subdomain header (for development/testing)
 * 3. Subdomain extraction (johns-store.azima.store)
 * 4. Custom domain lookup (custom.com)
 */
export async function tenantContextMiddleware(
  req: MedusaRequest,
  res: MedusaResponse,
  next: MedusaNextFunction
) {
  try {
    const hostname = req.hostname || req.get("host") || ""
    console.log('[TenantMiddleware] Processing request:', {
      hostname,
      path: req.path,
      headers: {
        'x-tenant-subdomain': req.get("x-tenant-subdomain"),
        'x-api-key': req.get("x-api-key") ? 'SET' : 'NOT SET',
        'host': req.get("host")
      }
    })
    
    let tenantResult = null
    let source: TenantSource = "unknown"

    // Priority 1: API Key
    const apiKey = req.get("x-api-key")
    if (apiKey) {
      console.log('[TenantMiddleware] Resolving by API key')
      tenantResult = await tenantService.getTenantByApiKey(apiKey)
      source = "api_key"
    }

    // Priority 2: Explicit header (development/testing)
    if (!tenantResult?.success) {
      const explicitSubdomain = req.get("x-tenant-subdomain")
      if (explicitSubdomain) {
        console.log('[TenantMiddleware] Resolving by subdomain header:', explicitSubdomain)
        tenantResult = await tenantService.getTenantBySubdomain(
          explicitSubdomain
        )
        source = "header"
        console.log('[TenantMiddleware] Result:', { success: tenantResult?.success, error: tenantResult?.error })
      }
    }

    // Priority 3: Subdomain extraction
    if (!tenantResult?.success) {
      const subdomain = extractSubdomain(hostname)
      if (subdomain) {
        tenantResult = await tenantService.getTenantBySubdomain(subdomain)
        source = "subdomain"
      }
    }

    // Priority 4: Custom domain
    if (!tenantResult?.success && isCustomDomain(hostname)) {
      const domain = hostname.split(":")[0]
      tenantResult = await tenantService.getTenantByDomain(domain)
      source = "custom_domain"
    }

    // If tenant found, attach to request
    if (tenantResult?.success && tenantResult.tenant) {
      req.tenantContext = tenantResult.tenant
      req.tenantSource = source

      // Log successful resolution
      if (process.env.TENANT_DEBUG === "true") {
        console.log(`[TenantContext] Resolved tenant:`, {
          tenantId: tenantResult.tenant.tenantId,
          regionId: tenantResult.tenant.regionId,
          source,
          hostname,
        })
      }

      next()
    } else {
      // No tenant found - decide if this is an error
      const path = req.path

      // Allow health checks and static assets without tenant
      if (
        path === "/health" ||
        path === "/healthz" ||
        path.startsWith("/static") ||
        path.startsWith("/_next")
      ) {
        next()
        return
      }

      // For admin routes, we might get tenant from JWT later
      if (path.startsWith("/admin")) {
        // Admin region guard will handle this
        next()
        return
      }

      // For store routes, tenant is required
      if (path.startsWith("/store")) {
        throw new TenantNotFoundError(hostname)
      }

      // For other routes, allow without tenant (for now)
      next()
    }
  } catch (error) {
    // Handle specific tenant errors
    if (error instanceof TenantNotFoundError) {
      res.status(404).json({
        error: "Tenant not found",
        message: error.message,
        code: error.code,
      })
      return
    }

    if (error instanceof TenantSuspendedError) {
      res.status(403).json({
        error: "Store suspended",
        message: error.message,
        code: error.code,
      })
      return
    }

    // Generic error
    console.error("Tenant context middleware error:", error)
    res.status(500).json({
      error: "Internal server error",
      message: "Failed to resolve tenant context",
    })
  }
}

/**
 * Require tenant context
 * 
 * Middleware that ensures tenantContext exists on request
 * Use this for routes that absolutely require a tenant
 */
export function requireTenantContext(
  req: MedusaRequest,
  res: MedusaResponse,
  next: MedusaNextFunction
) {
  if (!req.tenantContext) {
    res.status(400).json({
      error: "Missing tenant context",
      message: "This endpoint requires a valid tenant context",
    })
    return
  }

  next()
}

/**
 * Get region ID from tenant context
 * 
 * Utility to safely get region ID from request
 */
export function getRegionId(req: MedusaRequest): string | null {
  return req.tenantContext?.regionId || null
}

/**
 * Get tenant ID from tenant context
 * 
 * Utility to safely get tenant ID from request
 */
export function getTenantId(req: MedusaRequest): string | null {
  return req.tenantContext?.tenantId || null
}

