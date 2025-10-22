/**
 * Mock Admin tenant-scoped products endpoint
 * 
 * This version works with mock authentication for testing purposes
 */

import { MedusaRequest, MedusaResponse } from "@medusajs/framework/http"

export async function GET(
  req: MedusaRequest,
  res: MedusaResponse
) {
  try {
    // Check if tenant context was attached by middleware
    if (!req.tenantContext) {
      return res.status(400).json({
        success: false,
        message: "No tenant context found",
        hint: "Add x-tenant-subdomain header to your request",
      })
    }

    // Check for mock authentication token
    const authHeader = req.headers.authorization
    const mockToken = authHeader?.replace('Bearer ', '')
    
    if (!mockToken || !mockToken.startsWith('mock_jwt_token_')) {
      return res.status(401).json({
        success: false,
        message: "Invalid or missing authentication token",
        hint: "Use the token from /test-auth endpoint",
        example: "Authorization: Bearer mock_jwt_token_1234567890"
      })
    }

    // Get products scoped to tenant's region
    const regionId = req.tenantContext.regionId
    
    if (!regionId) {
      return res.status(400).json({
        success: false,
        message: "No region ID found for tenant",
        tenant: req.tenantContext,
      })
    }

    // Get query parameters
    const limit = parseInt(req.query.limit as string) || 50
    const offset = parseInt(req.query.offset as string) || 0
    const q = req.query.q as string | undefined

    // Mock admin products for now
    // In a real implementation, you'd query actual products from Medusa
    const mockProducts = [
      {
        id: "admin_prod_1",
        title: "Admin Product 1",
        description: "Admin-managed product for tenant: " + req.tenantContext.tenantId,
        region_id: regionId,
        admin_notes: "This product is managed by admin",
        status: "active",
        created_by: "admin_user",
        price: 2999,
        currency: "USD",
        inventory: 100,
        created_at: "2024-01-15T10:00:00Z",
        updated_at: "2024-01-15T10:00:00Z",
      },
      {
        id: "admin_prod_2", 
        title: "Admin Product 2",
        description: "Another admin product for tenant: " + req.tenantContext.tenantId,
        region_id: regionId,
        admin_notes: "This product needs review",
        status: "draft",
        created_by: "admin_user",
        price: 1599,
        currency: "USD",
        inventory: 50,
        created_at: "2024-01-16T14:30:00Z",
        updated_at: "2024-01-16T14:30:00Z",
      },
      {
        id: "admin_prod_3",
        title: "Admin Product 3",
        description: "Premium product for tenant: " + req.tenantContext.tenantId,
        region_id: regionId,
        admin_notes: "High-value product",
        status: "active",
        created_by: "admin_user",
        price: 4999,
        currency: "USD",
        inventory: 25,
        created_at: "2024-01-17T09:15:00Z",
        updated_at: "2024-01-17T09:15:00Z",
      }
    ]

    // Filter products by search query if provided
    let filteredProducts = mockProducts
    if (q) {
      filteredProducts = mockProducts.filter(product => 
        product.title.toLowerCase().includes(q.toLowerCase()) ||
        product.description.toLowerCase().includes(q.toLowerCase())
      )
    }

    // Apply pagination
    const paginatedProducts = filteredProducts.slice(offset, offset + limit)

    // Return mock admin products
    res.json({
      success: true,
      message: "Admin products retrieved successfully!",
      products: paginatedProducts,
      count: paginatedProducts.length,
      total: filteredProducts.length,
      region_id: regionId,
      tenant_id: req.tenantContext.tenantId,
      admin_user: "mock_admin_user",
      note: "This is a mock admin response. In production, you'd query actual products from Medusa.",
      filter_applied: {
        region_id: regionId,
        search_query: q || null
      },
      pagination: {
        limit,
        offset,
        total: filteredProducts.length,
        has_more: (offset + limit) < filteredProducts.length
      }
    })
  } catch (error) {
    console.error("Error fetching admin products:", error)
    res.status(500).json({
      success: false,
      error: "Internal server error",
      message: "Failed to fetch admin products",
    })
  }
}

// No authentication required for this mock endpoint
export const AUTHENTICATE = false
