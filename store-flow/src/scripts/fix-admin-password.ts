/**
 * Fix Admin Password Script
 * Deletes and recreates admin user with proper password
 */

import { ExecArgs } from "@medusajs/framework/types"
import { ContainerRegistrationKeys, Modules } from "@medusajs/framework/utils"

export default async function run({ container }: ExecArgs) {
  const logger = container.resolve(ContainerRegistrationKeys.LOGGER)
  const userModuleService = container.resolve(Modules.USER)
  
  const email = "admin@demostore.com"
  const password = "demo123456"
  
  try {
    logger.info("🔧 Fixing admin user password...")
    
    // Find the user
    const users = await userModuleService.listUsers({ email })
    
    if (users.length > 0) {
      logger.info(`Found user: ${email}, deleting...`)
      await userModuleService.deleteUsers([users[0].id])
      logger.info("✅ User deleted")
    }
    
    logger.info("Creating new user with password...")
    const newUser = await userModuleService.createUsers({
      email,
      first_name: "Demo",
      last_name: "Admin",
    })
    
    logger.info(`✅ User created: ${newUser.id}`)
    logger.info(`\nNow use the Medusa CLI to set the password:`)
    logger.info(`node_modules\\.bin\\medusa user -e ${email} -p ${password}`)
    
  } catch (error) {
    logger.error("❌ Error:", error)
  }
}

