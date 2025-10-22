/**
 * Region Filtering Utilities
 * 
 * Helper functions to apply region-based filtering to Medusa queries
 */

import { MedusaRequest } from "@medusajs/framework/http"
import { InvalidRegionError } from "../types/tenant-context"

/**
 * Get region filter object for Medusa queries
 * 
 * @param req - Medusa request with tenant context
 * @param options - Additional filter options
 * @returns Filter object to pass to Medusa query
 */
export function getRegionFilter(
  req: MedusaRequest,
  options?: {
    throwIfMissing?: boolean
    allowedRegions?: string[]
  }
): { region_id?: string } {
  const regionId = req.tenantContext?.regionId

  if (!regionId) {
    if (options?.throwIfMissing) {
      throw new InvalidRegionError("missing")
    }
    return {}
  }

  // Validate against allowed regions if provided
  if (options?.allowedRegions && !options.allowedRegions.includes(regionId)) {
    throw new InvalidRegionError(regionId)
  }

  return {
    region_id: regionId,
  }
}

/**
 * Ensure query is scoped to tenant's region
 * 
 * Modifies filter object in-place to include region restriction
 */
export function scopeToRegion(
  req: MedusaRequest,
  filter: Record<string, any>
): Record<string, any> {
  const regionId = req.tenantContext?.regionId

  if (regionId) {
    filter.region_id = regionId
  }

  return filter
}

/**
 * Validate that a region ID matches the tenant's region
 * 
 * @param req - Medusa request with tenant context
 * @param regionId - Region ID to validate
 * @param throwOnMismatch - Whether to throw error on mismatch
 * @returns True if valid, false otherwise
 */
export function validateRegionAccess(
  req: MedusaRequest,
  regionId: string,
  throwOnMismatch: boolean = false
): boolean {
  const tenantRegionId = req.tenantContext?.regionId

  if (!tenantRegionId) {
    // No tenant context - might be allowed for some routes
    return true
  }

  const isValid = tenantRegionId === regionId

  if (!isValid && throwOnMismatch) {
    throw new InvalidRegionError(regionId)
  }

  return isValid
}

/**
 * Get products filter with region scope
 * 
 * @param req - Medusa request with tenant context
 * @param additionalFilters - Additional filters to apply
 * @returns Combined filter object
 */
export function getProductsFilter(
  req: MedusaRequest,
  additionalFilters?: Record<string, any>
): Record<string, any> {
  const regionFilter = getRegionFilter(req, { throwIfMissing: false })

  return {
    ...regionFilter,
    ...additionalFilters,
  }
}

/**
 * Get orders filter with region scope
 * 
 * @param req - Medusa request with tenant context
 * @param additionalFilters - Additional filters to apply
 * @returns Combined filter object
 */
export function getOrdersFilter(
  req: MedusaRequest,
  additionalFilters?: Record<string, any>
): Record<string, any> {
  const regionFilter = getRegionFilter(req, { throwIfMissing: false })

  return {
    ...regionFilter,
    ...additionalFilters,
  }
}

/**
 * Get customers filter with region scope
 * 
 * @param req - Medusa request with tenant context
 * @param additionalFilters - Additional filters to apply
 * @returns Combined filter object
 */
export function getCustomersFilter(
  req: MedusaRequest,
  additionalFilters?: Record<string, any>
): Record<string, any> {
  const regionFilter = getRegionFilter(req, { throwIfMissing: false })

  return {
    ...regionFilter,
    ...additionalFilters,
  }
}

/**
 * Check if request has valid tenant context
 * 
 * @param req - Medusa request
 * @returns True if tenant context exists and is active
 */
export function hasTenantContext(req: MedusaRequest): boolean {
  return (
    !!req.tenantContext &&
    !!req.tenantContext.regionId &&
    req.tenantContext.status === "active"
  )
}

/**
 * Get safe region ID
 * 
 * Returns region ID if valid, or null
 */
export function getSafeRegionId(req: MedusaRequest): string | null {
  if (!hasTenantContext(req)) {
    return null
  }

  return req.tenantContext!.regionId
}

/**
 * Build region-scoped query parameters
 * 
 * Useful for query string construction
 */
export function buildRegionQueryParams(
  req: MedusaRequest
): Record<string, string> {
  const regionId = getSafeRegionId(req)

  if (!regionId) {
    return {}
  }

  return {
    region_id: regionId,
  }
}

/**
 * Validate array of entities belong to tenant's region
 * 
 * @param req - Medusa request with tenant context
 * @param entities - Array of entities with region_id property
 * @param throwOnMismatch - Whether to throw on mismatch
 * @returns True if all entities match, false otherwise
 */
export function validateEntitiesRegion<T extends { region_id?: string }>(
  req: MedusaRequest,
  entities: T[],
  throwOnMismatch: boolean = false
): boolean {
  const tenantRegionId = req.tenantContext?.regionId

  if (!tenantRegionId) {
    return true
  }

  const allValid = entities.every((entity) => {
    return !entity.region_id || entity.region_id === tenantRegionId
  })

  if (!allValid && throwOnMismatch) {
    throw new InvalidRegionError("Entity region mismatch")
  }

  return allValid
}

