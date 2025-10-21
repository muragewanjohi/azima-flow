/**
 * CLI Tool for Tenant Provisioning
 * 
 * Usage:
 *   npx medusa exec ./src/scripts/provision-cli.ts
 * 
 * This will prompt for tenant details and provision a new store.
 */

import provisionTenant from "./provision-tenant"
import { ExecArgs } from "@medusajs/framework/types"
import { ContainerRegistrationKeys } from "@medusajs/framework/utils"

export default async function run({ container }: ExecArgs) {
  const logger = container.resolve(ContainerRegistrationKeys.LOGGER)
  logger.info("\n")
  logger.info("═".repeat(60))
  logger.info("   AZIMA.STORE - TENANT PROVISIONING CLI")
  logger.info("═".repeat(60))
  logger.info("\n")

  // Example tenant - Replace with actual CLI prompts or API input
  const exampleTenant = {
    tenantName: "Demo Store",
    tenantEmail: "hello@demostore.com",
    slug: "demo",
    currencyCode: "kes",
    countryCode: "ke",
    adminEmail: "admin@demostore.com",
    adminPassword: "demo123456",
    adminFirstName: "Demo",
    adminLastName: "Admin",
    companyAddress: {
      address_1: "123 Demo Street",
      city: "Nairobi",
      country_code: "ke",
      province: "Nairobi",
    }
  }

  logger.info("📝 Using example tenant configuration:")
  logger.info(JSON.stringify(exampleTenant, null, 2))
  logger.info("\n")
  
  logger.info("⚠️  WARNING: This will create a new tenant in your Medusa instance!")
  logger.info("   Press Ctrl+C to cancel, or wait 3 seconds to continue...\n")
  
  // Wait 3 seconds before provisioning
  await new Promise(resolve => setTimeout(resolve, 3000))

  try {
    const result = await provisionTenant(container, exampleTenant)
    
    if (result.success) {
      logger.info("\n✅ PROVISIONING SUCCESSFUL!\n")
      logger.info("Tenant Details:")
      logger.info("───────────────────────────────────────")
      logger.info(`Subdomain:        ${result.tenant.subdomainUrl}`)
      logger.info(`Region ID:        ${result.region?.id}`)
      logger.info(`Admin User ID:    ${result.adminUser?.id}`)
      logger.info(`Admin Email:      ${result.adminUser?.email}`)
      logger.info(`Sales Channel:    ${result.salesChannel?.id}`)
      logger.info(`Stock Location:   ${result.stockLocation?.id}`)
      logger.info("───────────────────────────────────────\n")
      
      logger.info("🎯 Next Steps:")
      logger.info("1. Login to admin dashboard:")
      logger.info(`   URL: http://localhost:9000/app`)
      logger.info(`   Email: ${exampleTenant.adminEmail}`)
      logger.info(`   Password: ${exampleTenant.adminPassword}`)
      logger.info("\n2. Add products to your store")
      logger.info("3. Configure payment methods")
      logger.info("4. Set up your storefront\n")
      
    } else {
      logger.info("\n❌ PROVISIONING FAILED!\n")
      logger.info("Errors:")
      result.errors?.forEach((error, index) => {
        logger.info(`${index + 1}. ${error}`)
      })
      logger.info("\n")
    }
    
  } catch (error) {
    logger.error("\n❌ UNEXPECTED ERROR:\n", error)
    logger.info("\n")
  }
}

