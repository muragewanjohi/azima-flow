/**
 * Tenant Provisioning Script
 * 
 * Automates the creation of new tenant stores in the multi-tenant SaaS platform.
 * Each tenant gets:
 * - A dedicated Medusa Region
 * - An admin user account
 * - Default sales channel and stock location
 * - Basic shipping and payment configuration
 */

import { ExecArgs } from "@medusajs/framework/types"
import {
  ContainerRegistrationKeys,
  Modules,
} from "@medusajs/framework/utils"
import {
  createRegionsWorkflow,
  createSalesChannelsWorkflow,
  createStockLocationsWorkflow,
  createShippingProfilesWorkflow,
  createShippingOptionsWorkflow,
  createTaxRegionsWorkflow,
  linkSalesChannelsToStockLocationWorkflow,
} from "@medusajs/medusa/core-flows"

interface ProvisionTenantInput {
  // Tenant details
  tenantName: string
  tenantEmail: string
  slug: string // for subdomain (e.g., 'acme' -> acme.azima.store)
  
  // Region configuration
  currencyCode: string // e.g., 'kes', 'usd'
  countryCode: string // e.g., 'ke', 'us'
  
  // Admin user
  adminEmail: string
  adminPassword: string
  adminFirstName: string
  adminLastName: string
  
  // Optional
  companyAddress?: {
    address1: string
    city: string
    countryCode: string
    postalCode?: string
    province?: string
  }
}

interface ProvisioningResult {
  success: boolean
  tenant: {
    slug: string
    subdomainUrl: string
  }
  region?: {
    id: string
    name: string
    currencyCode: string
  }
  adminUser?: {
    id: string
    email: string
  }
  salesChannel?: {
    id: string
    name: string
  }
  stockLocation?: {
    id: string
    name: string
  }
  errors?: string[]
}

export default async function provisionTenant(
  container: any,
  input: ProvisionTenantInput
): Promise<ProvisioningResult> {
  
  const logger = container.resolve(ContainerRegistrationKeys.LOGGER)
  const userModuleService = container.resolve(Modules.USER)
  const fulfillmentModuleService = container.resolve(Modules.FULFILLMENT)
  
  logger.info(`\n🚀 Starting tenant provisioning for: ${input.tenantName}`)
  logger.info(`   Slug: ${input.slug}`)
  logger.info(`   Email: ${input.adminEmail}`)
  logger.info(`   Currency: ${input.currencyCode.toUpperCase()}`)
  logger.info(`   Country: ${input.countryCode.toUpperCase()}\n`)

  const errors: string[] = []
  let regionId: string | undefined
  let salesChannelId: string | undefined
  let stockLocationId: string | undefined

  try {
    // Step 1: Validate inputs
    logger.info("📋 Step 1: Validating inputs...")
    validateInputs(input)
    logger.info("✅ Inputs validated\n")

    // Step 2: Create Region using workflow
    logger.info("🌍 Step 2: Creating Medusa Region...")
    const { result: regionResult } = await createRegionsWorkflow(container).run({
      input: {
        regions: [{
          name: input.tenantName,
          currency_code: input.currencyCode.toLowerCase(),
          // NOTE: NOT assigning countries to allow multiple tenants in same country
          // Countries will be stored in metadata instead
          payment_providers: ["pp_system_default"],
          metadata: {
            tenant_slug: input.slug,
            tenant_email: input.tenantEmail,
            country_code: input.countryCode.toLowerCase(),
            provisioned_at: new Date().toISOString(),
          }
        }]
      }
    })
    
    const region = regionResult[0]
    regionId = region.id
    logger.info(`✅ Region created: ${region.id} - ${region.name}\n`)

    // Step 3: Skip Tax Region (would conflict with multiple tenants in same country)
    // Tax configuration will be handled per-tenant in Day 8 middleware
    logger.info("💰 Step 3: Skipping tax region (multi-tenant setup)...\n")

    // Step 4: Create Admin User with auto-generated password
    logger.info("👤 Step 4: Creating admin user...")
    
    // For production: auto-generate secure password if not provided
    const adminPassword = input.adminPassword || generateSecurePassword()
    
    // Store user email and password for email notification
    const adminCredentials = {
      email: input.adminEmail,
      password: adminPassword,
      firstName: input.adminFirstName,
      lastName: input.adminLastName,
    }
    
    logger.info(`✅ Admin credentials prepared: ${adminCredentials.email}`)
    logger.info(`⚠️  Next step: Create user via CLI or send invite\n`)

    // Step 5: Create Sales Channel using workflow
    logger.info("📺 Step 5: Creating sales channel...")
    const { result: salesChannelResult } = await createSalesChannelsWorkflow(container).run({
      input: {
        salesChannelsData: [{
          name: `${input.tenantName} - Web Store`,
          description: `Main sales channel for ${input.tenantName}`,
        }]
      }
    })
    
    const salesChannel = salesChannelResult[0]
    salesChannelId = salesChannel.id
    logger.info(`✅ Sales channel created: ${salesChannel.id}\n`)

    // Step 6: Create Stock Location using workflow
    logger.info("📦 Step 6: Creating stock location...")
    const address = input.companyAddress || {
      address_1: "Default Address",
      city: getDefaultCity(input.countryCode),
      country_code: input.countryCode.toLowerCase(),
    }
    
    const { result: stockLocationResult } = await createStockLocationsWorkflow(container).run({
      input: {
        locations: [{
          name: `${input.tenantName} - Main Warehouse`,
          address: address,
          metadata: {
            tenant_slug: input.slug,
            country_code: input.countryCode.toLowerCase(),
          }
        }]
      }
    })
    
    const stockLocation = stockLocationResult[0]
    stockLocationId = stockLocation.id
    logger.info(`✅ Stock location created: ${stockLocation.id}\n`)

    // Step 7: Link Sales Channel to Stock Location
    logger.info("🔗 Step 7: Linking sales channel to stock location...")
    await linkSalesChannelsToStockLocationWorkflow(container).run({
      input: {
        id: stockLocationId,
        add: [salesChannelId],
      }
    })
    logger.info("✅ Sales channel linked to stock location\n")

    // Step 8: Create Shipping Profile
    logger.info("🚚 Step 8: Creating shipping profile...")
    const shippingProfiles = await fulfillmentModuleService.listShippingProfiles({
      type: "default"
    })
    let shippingProfile = shippingProfiles.length ? shippingProfiles[0] : null
    
    if (!shippingProfile) {
      const { result: shippingProfileResult } = await createShippingProfilesWorkflow(container).run({
        input: {
          data: [{
            name: "Default Shipping Profile",
            type: "default",
          }]
        }
      })
      shippingProfile = shippingProfileResult[0]
    }
    logger.info(`✅ Shipping profile ready: ${shippingProfile.id}\n`)

    // Step 9: Create Fulfillment Set (without geo_zones to avoid country conflicts)
    logger.info("📍 Step 9: Creating fulfillment set...")
    const fulfillmentSet = await fulfillmentModuleService.createFulfillmentSets({
      name: `${input.tenantName} Delivery`,
      type: "shipping",
      service_zones: [{
        name: input.tenantName,
        // NOTE: Not setting geo_zones to allow multiple tenants
        // Geo-restrictions will be handled in storefront/checkout logic
      }]
    })
    logger.info(`✅ Fulfillment set created: ${fulfillmentSet.id}\n`)

    // Step 10: Link Fulfillment Set to Stock Location
    logger.info("🔗 Step 10: Linking fulfillment set to stock location...")
    const link = container.resolve(ContainerRegistrationKeys.LINK)
    await link.create({
      [Modules.STOCK_LOCATION]: {
        stock_location_id: stockLocationId,
      },
      [Modules.FULFILLMENT]: {
        fulfillment_set_id: fulfillmentSet.id,
      },
    })
    await link.create({
      [Modules.STOCK_LOCATION]: {
        stock_location_id: stockLocationId,
      },
      [Modules.FULFILLMENT]: {
        fulfillment_provider_id: "manual_manual",
      },
    })
    logger.info("✅ Fulfillment links created\n")

    // Step 11: Create Shipping Option
    logger.info("🚢 Step 11: Creating shipping option...")
    const defaultShippingPrice = getDefaultShippingPrice(input.currencyCode)
    
    await createShippingOptionsWorkflow(container).run({
      input: [{
        name: "Standard Shipping",
        price_type: "flat",
        provider_id: "manual_manual",
        service_zone_id: fulfillmentSet.service_zones[0].id,
        shipping_profile_id: shippingProfile.id,
        type: {
          label: "Standard",
          description: "Standard delivery (3-5 business days)",
          code: "standard",
        },
        prices: [{
          currency_code: input.currencyCode.toLowerCase(),
          amount: defaultShippingPrice,
        }, {
          region_id: regionId,
          amount: defaultShippingPrice,
        }],
        rules: [{
          attribute: "enabled_in_store",
          value: "true",
          operator: "eq",
        }, {
          attribute: "is_return",
          value: "false",
          operator: "eq",
        }],
      }]
    })
    
    logger.info(`✅ Shipping option created (${formatPrice(defaultShippingPrice, input.currencyCode)})\n`)

    // Success!
    logger.info("🎉 Tenant infrastructure provisioned successfully!\n")
    logger.info("═".repeat(60))
    logger.info(`   Subdomain URL: https://${input.slug}.azima.store`)
    logger.info(`   Region ID: ${regionId}`)
    logger.info("═".repeat(60))
    logger.info("\n")
    logger.info("⚠️  NEXT STEP: Create admin user with password:")
    logger.info(`   medusa user -e ${adminCredentials.email} -p ${adminCredentials.password}`)
    logger.info("\n")

    return {
      success: true,
      tenant: {
        slug: input.slug,
        subdomainUrl: `https://${input.slug}.azima.store`,
      },
      region: {
        id: regionId,
        name: region.name,
        currencyCode: region.currency_code,
      },
      adminUser: {
        email: adminCredentials.email,
        password: adminCredentials.password,
        firstName: adminCredentials.firstName,
        lastName: adminCredentials.lastName,
        createCommand: `medusa user -e ${adminCredentials.email} -p ${adminCredentials.password}`
      },
      salesChannel: {
        id: salesChannelId,
        name: salesChannel.name,
      },
      stockLocation: {
        id: stockLocationId,
        name: stockLocation.name,
      },
    }

  } catch (error) {
    logger.error("❌ Provisioning failed:", error)
    
    errors.push(error.message || "Unknown error during provisioning")

    return {
      success: false,
      tenant: {
        slug: input.slug,
        subdomainUrl: `https://${input.slug}.azima.store`,
      },
      errors,
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

function generateSecurePassword(length: number = 16): string {
  const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
  let password = ""
  const crypto = require('crypto')
  
  for (let i = 0; i < length; i++) {
    const randomIndex = crypto.randomInt(0, charset.length)
    password += charset[randomIndex]
  }
  
  return password
}

function validateInputs(input: ProvisionTenantInput): void {
  if (!input.tenantName || input.tenantName.trim().length === 0) {
    throw new Error("Tenant name is required")
  }
  
  if (!input.slug || !/^[a-z0-9-]+$/.test(input.slug)) {
    throw new Error("Slug must contain only lowercase letters, numbers, and hyphens")
  }
  
  if (!input.adminEmail || !isValidEmail(input.adminEmail)) {
    throw new Error("Valid admin email is required")
  }
  
  if (!input.adminPassword || input.adminPassword.length < 8) {
    throw new Error("Admin password must be at least 8 characters")
  }
  
  if (!input.currencyCode || input.currencyCode.length !== 3) {
    throw new Error("Currency code must be 3 characters (e.g., USD, KES)")
  }
  
  if (!input.countryCode || input.countryCode.length !== 2) {
    throw new Error("Country code must be 2 characters (e.g., US, KE)")
  }
}

function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email)
}

function getDefaultShippingPrice(currencyCode: string): number {
  // Prices in smallest currency unit (cents)
  const priceMap: Record<string, number> = {
    usd: 500,    // $5.00
    eur: 500,    // €5.00
    gbp: 400,    // £4.00
    kes: 50000,  // KES 500
    ngn: 250000, // NGN 2500
    zar: 8000,   // ZAR 80
  }
  
  return priceMap[currencyCode.toLowerCase()] || 500
}

function getDefaultCity(countryCode: string): string {
  const cityMap: Record<string, string> = {
    ke: "Nairobi",
    us: "New York",
    gb: "London",
    ng: "Lagos",
    za: "Johannesburg",
  }
  
  return cityMap[countryCode.toLowerCase()] || "Default City"
}

function formatPrice(amount: number, currencyCode: string): string {
  const formatted = (amount / 100).toFixed(2)
  return `${currencyCode.toUpperCase()} ${formatted}`
}


// ============================================================================
// CLI Entry Point (for testing)
// ============================================================================

// Example usage:
// npx medusa exec ./src/scripts/provision-tenant.ts

/*
const testInput: ProvisionTenantInput = {
  tenantName: "Acme Store",
  tenantEmail: "hello@acme.com",
  slug: "acme",
  currencyCode: "kes",
  countryCode: "ke",
  adminEmail: "admin@acme.com",
  adminPassword: "supersecret123",
  adminFirstName: "John",
  adminLastName: "Doe",
  companyAddress: {
    address1: "123 Main Street",
    city: "Nairobi",
    countryCode: "ke",
    province: "Nairobi",
  }
}

// Run: provisionTenant(container, testInput)
*/

