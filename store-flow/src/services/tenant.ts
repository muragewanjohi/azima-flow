/**
 * Tenant Service
 * 
 * Handles tenant resolution, validation, and caching
 */

import { createClient } from "@supabase/supabase-js"
import Redis from "ioredis"
import {
  TenantContext,
  TenantLookupResult,
  TenantSource,
  CachedTenant,
  TenantNotFoundError,
  TenantSuspendedError,
  TenantStatus,
} from "../types/tenant-context"

export class TenantService {
  private supabase: ReturnType<typeof createClient>
  private redis: Redis
  private cacheTTL: number
  private debug: boolean

  constructor() {
    // Initialize Supabase client for SaaS database
    console.log('[TenantService] Initializing with:', {
      url: process.env.SAAS_SUPABASE_URL ? 'SET' : 'MISSING',
      key: process.env.SAAS_SUPABASE_SERVICE_KEY ? 'SET' : 'MISSING',
    })
    
    this.supabase = createClient(
      process.env.SAAS_SUPABASE_URL!,
      process.env.SAAS_SUPABASE_SERVICE_KEY!, // Service role key for server-side
      {
        db: { schema: "public" },
      }
    )

    // Initialize Redis for caching
    this.redis = new Redis(process.env.REDIS_URL || "redis://localhost:6379", {
      lazyConnect: true,
      retryStrategy: (times) => {
        const delay = Math.min(times * 50, 2000)
        return delay
      },
    })

    this.cacheTTL = parseInt(process.env.TENANT_CACHE_TTL || "300") // 5 minutes default
    this.debug = process.env.TENANT_DEBUG === "true"

    // Connect to Redis
    this.redis.connect().catch((err) => {
      console.error("Redis connection error:", err)
    })
  }

  /**
   * Resolve tenant by subdomain
   */
  async getTenantBySubdomain(
    subdomain: string
  ): Promise<TenantLookupResult> {
    try {
      // Check cache first
      const cached = await this.getCachedTenant(`subdomain:${subdomain}`)
      if (cached) {
        this.log(`Cache hit for subdomain: ${subdomain}`)
        return {
          success: true,
          tenant: this.cachedToContext(cached),
          source: "subdomain",
        }
      }

      // Query SaaS database
      this.log(`Cache miss for subdomain: ${subdomain}, querying DB`)
      console.log('[TenantService] Querying database for subdomain:', subdomain)
      
      const { data, error } = await this.supabase
        .from("tenants")
        .select(
          "id, business_name, subdomain, medusa_region_id, status, metadata"
        )
        .eq("subdomain", subdomain)
        .single()

      console.log('[TenantService] Query result:', {
        found: !!data,
        error: error?.message,
        errorCode: error?.code,
        data: data ? { id: data.id, subdomain: data.subdomain, status: data.status } : null
      })

      if (error || !data) {
        console.log('[TenantService] Tenant not found or error occurred')
        return {
          success: false,
          source: "subdomain",
          error: "Tenant not found",
        }
      }

      // Validate status
      if (data.status === "suspended") {
        throw new TenantSuspendedError(data.id)
      }

      if (data.status !== "active") {
        return {
          success: false,
          source: "subdomain",
          error: `Tenant status is ${data.status}`,
        }
      }

      // Build tenant context
      const tenant: TenantContext = {
        tenantId: data.id,
        regionId: data.medusa_region_id,
        subdomain: data.subdomain,
        businessName: data.business_name,
        status: data.status as TenantStatus,
        metadata: data.metadata || {},
      }

      // Cache the result
      await this.cacheTenant(`subdomain:${subdomain}`, tenant)

      return {
        success: true,
        tenant,
        source: "subdomain",
      }
    } catch (error) {
      if (error instanceof TenantSuspendedError) {
        throw error
      }

      console.error("Error resolving tenant by subdomain:", error)
      return {
        success: false,
        source: "subdomain",
        error: error instanceof Error ? error.message : "Unknown error",
      }
    }
  }

  /**
   * Resolve tenant by custom domain
   */
  async getTenantByDomain(domain: string): Promise<TenantLookupResult> {
    try {
      // Check cache first
      const cached = await this.getCachedTenant(`domain:${domain}`)
      if (cached) {
        this.log(`Cache hit for domain: ${domain}`)
        return {
          success: true,
          tenant: this.cachedToContext(cached),
          source: "custom_domain",
        }
      }

      // Query domains table first
      this.log(`Cache miss for domain: ${domain}, querying DB`)
      const { data: domainData, error: domainError } = await this.supabase
        .from("domains")
        .select("tenant_id, status")
        .eq("domain", domain)
        .eq("status", "active")
        .single()

      if (domainError || !domainData) {
        return {
          success: false,
          source: "custom_domain",
          error: "Domain not found or not active",
        }
      }

      // Get tenant details
      const { data: tenantData, error: tenantError } = await this.supabase
        .from("tenants")
        .select(
          "id, business_name, subdomain, medusa_region_id, status, metadata"
        )
        .eq("id", domainData.tenant_id)
        .single()

      if (tenantError || !tenantData) {
        return {
          success: false,
          source: "custom_domain",
          error: "Tenant not found",
        }
      }

      // Validate status
      if (tenantData.status === "suspended") {
        throw new TenantSuspendedError(tenantData.id)
      }

      if (tenantData.status !== "active") {
        return {
          success: false,
          source: "custom_domain",
          error: `Tenant status is ${tenantData.status}`,
        }
      }

      // Build tenant context
      const tenant: TenantContext = {
        tenantId: tenantData.id,
        regionId: tenantData.medusa_region_id,
        subdomain: tenantData.subdomain,
        customDomain: domain,
        businessName: tenantData.business_name,
        status: tenantData.status as TenantStatus,
        metadata: tenantData.metadata || {},
      }

      // Cache the result
      await this.cacheTenant(`domain:${domain}`, tenant)

      return {
        success: true,
        tenant,
        source: "custom_domain",
      }
    } catch (error) {
      if (error instanceof TenantSuspendedError) {
        throw error
      }

      console.error("Error resolving tenant by domain:", error)
      return {
        success: false,
        source: "custom_domain",
        error: error instanceof Error ? error.message : "Unknown error",
      }
    }
  }

  /**
   * Resolve tenant by API key
   */
  async getTenantByApiKey(apiKey: string): Promise<TenantLookupResult> {
    try {
      // Hash the API key
      const crypto = await import("crypto")
      const keyHash = crypto.createHash("sha256").update(apiKey).digest("hex")

      // Query API keys table
      const { data: apiKeyData, error: apiKeyError } = await this.supabase
        .from("api_keys")
        .select("tenant_id, is_active")
        .eq("key_hash", keyHash)
        .eq("is_active", true)
        .single()

      if (apiKeyError || !apiKeyData) {
        return {
          success: false,
          source: "api_key",
          error: "Invalid or inactive API key",
        }
      }

      // Get tenant details
      const { data: tenantData, error: tenantError } = await this.supabase
        .from("tenants")
        .select(
          "id, business_name, subdomain, medusa_region_id, status, metadata"
        )
        .eq("id", apiKeyData.tenant_id)
        .single()

      if (tenantError || !tenantData) {
        return {
          success: false,
          source: "api_key",
          error: "Tenant not found",
        }
      }

      // Validate status
      if (tenantData.status === "suspended") {
        throw new TenantSuspendedError(tenantData.id)
      }

      if (tenantData.status !== "active") {
        return {
          success: false,
          source: "api_key",
          error: `Tenant status is ${tenantData.status}`,
        }
      }

      // Update API key last_used_at
      await this.supabase
        .from("api_keys")
        .update({
          last_used_at: new Date().toISOString(),
          usage_count: apiKeyData.usage_count + 1,
        })
        .eq("key_hash", keyHash)

      // Build tenant context
      const tenant: TenantContext = {
        tenantId: tenantData.id,
        regionId: tenantData.medusa_region_id,
        subdomain: tenantData.subdomain,
        businessName: tenantData.business_name,
        status: tenantData.status as TenantStatus,
        metadata: tenantData.metadata || {},
      }

      return {
        success: true,
        tenant,
        source: "api_key",
      }
    } catch (error) {
      if (error instanceof TenantSuspendedError) {
        throw error
      }

      console.error("Error resolving tenant by API key:", error)
      return {
        success: false,
        source: "api_key",
        error: error instanceof Error ? error.message : "Unknown error",
      }
    }
  }

  /**
   * Cache tenant data
   */
  private async cacheTenant(
    key: string,
    tenant: TenantContext
  ): Promise<void> {
    try {
      const cached: CachedTenant = {
        tenantId: tenant.tenantId,
        regionId: tenant.regionId,
        subdomain: tenant.subdomain,
        customDomain: tenant.customDomain,
        businessName: tenant.businessName,
        status: tenant.status,
        cachedAt: Date.now(),
      }

      await this.redis.setex(
        `tenant:${key}`,
        this.cacheTTL,
        JSON.stringify(cached)
      )
      this.log(`Cached tenant: ${key}`)
    } catch (error) {
      console.error("Error caching tenant:", error)
      // Don't throw - caching failure shouldn't break the request
    }
  }

  /**
   * Get cached tenant data
   */
  private async getCachedTenant(
    key: string
  ): Promise<CachedTenant | null> {
    try {
      const cached = await this.redis.get(`tenant:${key}`)
      if (!cached) {
        return null
      }

      const data: CachedTenant = JSON.parse(cached)
      return data
    } catch (error) {
      console.error("Error getting cached tenant:", error)
      return null
    }
  }

  /**
   * Convert cached tenant to context
   */
  private cachedToContext(cached: CachedTenant): TenantContext {
    return {
      tenantId: cached.tenantId,
      regionId: cached.regionId,
      subdomain: cached.subdomain,
      customDomain: cached.customDomain,
      businessName: cached.businessName,
      status: cached.status,
      metadata: {},
    }
  }

  /**
   * Invalidate tenant cache
   */
  async invalidateCache(subdomain?: string, domain?: string): Promise<void> {
    try {
      const keys: string[] = []

      if (subdomain) {
        keys.push(`tenant:subdomain:${subdomain}`)
      }

      if (domain) {
        keys.push(`tenant:domain:${domain}`)
      }

      if (keys.length > 0) {
        await this.redis.del(...keys)
        this.log(`Invalidated cache for: ${keys.join(", ")}`)
      }
    } catch (error) {
      console.error("Error invalidating cache:", error)
    }
  }

  /**
   * Log debug messages
   */
  private log(message: string): void {
    if (this.debug) {
      console.log(`[TenantService] ${message}`)
    }
  }

  /**
   * Cleanup resources
   */
  async cleanup(): Promise<void> {
    await this.redis.quit()
  }
}

// Export singleton instance
export const tenantService = new TenantService()

