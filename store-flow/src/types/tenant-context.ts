/**
 * Tenant Context Type Definitions
 * 
 * Provides TypeScript types for multi-tenant isolation
 */

import { MedusaRequest } from "@medusajs/framework/http"

/**
 * Tenant status from SaaS database
 */
export type TenantStatus = 
  | "provisioning"
  | "active"
  | "suspended"
  | "error"
  | "deleted"

/**
 * Tenant context attached to requests
 */
export interface TenantContext {
  /**
   * Tenant UUID from SaaS database
   */
  tenantId: string

  /**
   * Medusa region ID this tenant is associated with
   */
  regionId: string

  /**
   * Tenant subdomain (e.g., "johns-store")
   */
  subdomain?: string

  /**
   * Custom domain if configured (e.g., "custom.com")
   */
  customDomain?: string

  /**
   * Tenant business name
   */
  businessName?: string

  /**
   * Tenant status
   */
  status: TenantStatus

  /**
   * Tenant metadata
   */
  metadata?: Record<string, any>
}

/**
 * Tenant resolution source
 */
export type TenantSource = 
  | "subdomain"
  | "custom_domain"
  | "api_key"
  | "admin_jwt"
  | "header"
  | "unknown"

/**
 * Tenant lookup result
 */
export interface TenantLookupResult {
  success: boolean
  tenant?: TenantContext
  source: TenantSource
  error?: string
}

/**
 * Cached tenant data
 */
export interface CachedTenant {
  tenantId: string
  regionId: string
  subdomain?: string
  customDomain?: string
  businessName?: string
  status: TenantStatus
  cachedAt: number
}

/**
 * Admin user metadata (stored in Medusa user table)
 */
export interface AdminUserMetadata {
  /**
   * Region this admin user is scoped to
   */
  regionId: string

  /**
   * Tenant ID (for cross-reference with SaaS DB)
   */
  tenantId?: string

  /**
   * Additional metadata
   */
  [key: string]: any
}

/**
 * Extended Medusa request with tenant context
 */
export interface MedusaRequestWithTenant extends MedusaRequest {
  tenantContext?: TenantContext
  tenantSource?: TenantSource
}

/**
 * Tenant service configuration
 */
export interface TenantServiceConfig {
  /**
   * Supabase connection for SaaS database
   */
  supabaseUrl: string
  supabaseKey: string

  /**
   * Redis connection for caching
   */
  redisUrl: string

  /**
   * Cache TTL in seconds (default: 300 = 5 minutes)
   */
  cacheTTL?: number

  /**
   * Enable debug logging
   */
  debug?: boolean
}

/**
 * Region validation options
 */
export interface RegionValidationOptions {
  /**
   * Require region to be active
   */
  requireActive?: boolean

  /**
   * Throw error if validation fails
   */
  throwOnError?: boolean
}

/**
 * Tenant error types
 */
export class TenantError extends Error {
  constructor(
    message: string,
    public code: string,
    public statusCode: number = 400
  ) {
    super(message)
    this.name = "TenantError"
  }
}

export class TenantNotFoundError extends TenantError {
  constructor(identifier: string) {
    super(
      `Tenant not found: ${identifier}`,
      "TENANT_NOT_FOUND",
      404
    )
  }
}

export class TenantSuspendedError extends TenantError {
  constructor(tenantId: string) {
    super(
      "This store has been suspended. Please contact support.",
      "TENANT_SUSPENDED",
      403
    )
  }
}

export class InvalidRegionError extends TenantError {
  constructor(regionId: string) {
    super(
      `Invalid region: ${regionId}`,
      "INVALID_REGION",
      400
    )
  }
}

export class CrossTenantAccessError extends TenantError {
  constructor() {
    super(
      "You don't have permission to access this resource",
      "CROSS_TENANT_ACCESS",
      403
    )
  }
}

/**
 * Extend MedusaRequest type globally
 */
declare module "@medusajs/framework/http" {
  interface MedusaRequest {
    tenantContext?: TenantContext
    tenantSource?: TenantSource
  }
}

