/**
 * Simple authentication test endpoint
 * 
 * This endpoint tests if we can authenticate users
 * without relying on the complex admin auth system
 */

import { MedusaRequest, MedusaResponse } from "@medusajs/framework/http"

export async function POST(
  req: MedusaRequest,
  res: MedusaResponse
) {
  try {
    const { email, password } = req.body

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email and password are required",
      })
    }

    // For now, let's just return a mock success
    // In a real implementation, you'd validate against the database
    const mockUsers = [
      { email: "admin@azima.store", password: "supersecret", name: "Admin User" },
      { email: "admin@nakurushop.com", password: "nakuru123456", name: "Nakuru Admin" },
      { email: "admin@myelectronics.co.ke", password: "test123456", name: "Electronics Admin" },
    ]

    const user = mockUsers.find(u => u.email === email && u.password === password)

    if (user) {
      return res.json({
        success: true,
        message: "Authentication successful!",
        user: {
          email: user.email,
          name: user.name,
        },
        token: "mock_jwt_token_" + Date.now(), // Mock token for testing
        note: "This is a mock authentication for testing purposes"
      })
    } else {
      return res.status(401).json({
        success: false,
        message: "Invalid credentials",
        hint: "Check your email and password"
      })
    }
  } catch (error) {
    console.error("Error in test-auth endpoint:", error)
    return res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    })
  }
}

// No authentication required for this test endpoint
export const AUTHENTICATE = false
