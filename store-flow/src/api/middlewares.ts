/**
 * Global API Middlewares
 * 
 * Register middlewares that run on all API routes
 */

import { defineMiddlewares } from "@medusajs/medusa"
import { tenantContextMiddleware } from "../middlewares/tenant-context"

export default defineMiddlewares({
  routes: [
    {
      matcher: "/store/*",
      middlewares: [tenantContextMiddleware],
    },
    {
      matcher: "/admin/*",
      middlewares: [tenantContextMiddleware],
    },
    {
      matcher: "/test-tenant",
      middlewares: [tenantContextMiddleware],
    },
    {
      matcher: "/test-products",
      middlewares: [tenantContextMiddleware],
    },
    {
      matcher: "/test-admin",
      middlewares: [tenantContextMiddleware],
    },
    {
      matcher: "/test-auth",
      middlewares: [],
    },
    {
      matcher: "/admin/products-scoped-mock",
      middlewares: [tenantContextMiddleware],
    },
  ],
})

