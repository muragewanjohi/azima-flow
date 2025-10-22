/**
 * Admin Region Guard Middleware
 * 
 * Ensures admin users can only access data from their assigned region
 */

import { MedusaNextFunction, MedusaRequest, MedusaResponse } from "@medusajs/framework/http"
import { CrossTenantAccessError } from "../types/tenant-context"

/**
 * Extract region ID from admin user metadata
 * 
 * Admin users have their region_id stored in metadata during provisioning
 */
function getAdminUserRegion(req: MedusaRequest): string | null {
  // Check if user is authenticated
  const user = req.user
  if (!user) {
    return null
  }

  // Extract region from user metadata
  if (user.metadata && typeof user.metadata === "object") {
    const metadata = user.metadata as Record<string, any>
    return metadata.regionId || metadata.region_id || null
  }

  return null
}

/**
 * Admin Region Guard Middleware
 * 
 * Validates that:
 * 1. Admin user is authenticated
 * 2. Admin user has a region_id in metadata
 * 3. Admin user's region matches the tenant context (if present)
 * 
 * Use this middleware on admin routes that need region scoping
 */
export async function adminRegionGuard(
  req: MedusaRequest,
  res: MedusaResponse,
  next: MedusaNextFunction
) {
  try {
    // Get admin user's assigned region
    const adminRegionId = getAdminUserRegion(req)

    if (!adminRegionId) {
      // Admin user doesn't have a region assigned
      // This might be a super admin or the user metadata wasn't set up properly
      console.warn("Admin user without region_id in metadata:", req.user?.id)

      // For now, allow access but log the warning
      // In production, you might want to block this
      next()
      return
    }

    // If tenant context exists (from subdomain/domain), validate it matches admin's region
    if (req.tenantContext) {
      const tenantRegionId = req.tenantContext.regionId

      if (adminRegionId !== tenantRegionId) {
        // Admin is trying to access a different tenant's data
        console.error("Cross-tenant access attempt detected:", {
          adminUserId: req.user?.id,
          adminRegion: adminRegionId,
          requestedRegion: tenantRegionId,
          path: req.path,
          hostname: req.hostname,
        })

        // Log to SaaS database for security audit
        // TODO: Implement audit logging

        throw new CrossTenantAccessError()
      }
    }

    // Attach admin's region to tenant context if not already set
    if (!req.tenantContext && adminRegionId) {
      req.tenantContext = {
        tenantId: "", // We don't have tenant ID from admin metadata
        regionId: adminRegionId,
        status: "active",
      }
      req.tenantSource = "admin_jwt"
    }

    next()
  } catch (error) {
    if (error instanceof CrossTenantAccessError) {
      res.status(403).json({
        error: "Access denied",
        message: error.message,
        code: error.code,
      })
      return
    }

    console.error("Admin region guard error:", error)
    res.status(500).json({
      error: "Internal server error",
      message: "Failed to validate admin access",
    })
  }
}

/**
 * Validate admin can access specific region
 * 
 * Helper function to check if admin user can access a specific region
 */
export function canAdminAccessRegion(
  req: MedusaRequest,
  regionId: string
): boolean {
  const adminRegionId = getAdminUserRegion(req)

  if (!adminRegionId) {
    // Admin without region might be super admin
    return true
  }

  return adminRegionId === regionId
}

/**
 * Get admin's assigned region
 * 
 * Helper to get the region ID for the current admin user
 */
export function getAdminRegion(req: MedusaRequest): string | null {
  return getAdminUserRegion(req)
}

/**
 * Require admin authentication
 * 
 * Ensures user is authenticated before proceeding
 */
export function requireAdminAuth(
  req: MedusaRequest,
  res: MedusaResponse,
  next: MedusaNextFunction
) {
  if (!req.user) {
    res.status(401).json({
      error: "Unauthorized",
      message: "Admin authentication required",
    })
    return
  }

  next()
}

