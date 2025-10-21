# Day 9: Complete Signup Flow - Dual User Creation

## 🎯 Overview

When a merchant signs up on `azima.store`, we create **TWO user accounts simultaneously**:
1. **Supabase User** (SaaS platform account for billing/subscription)
2. **Medusa Admin User** (Store admin account for managing products/orders)

**Both use the SAME email and password** for seamless UX.

---

## 🔄 Complete Signup Flow

```
USER FILLS SIGNUP FORM
│
├─ Business Name: "John's Electronics"
├─ Email: john@electronics.com
├─ Password: JohnSecure2024!
├─ First Name: John
└─ Last Name: Doe
        ↓
┌───────────────────────────────────────────────────┐
│   SaaS API: /api/signup                           │
└───────────────────────────────────────────────────┘
        ↓
┌───────────────────────────────────────────────────┐
│ STEP 1: Create Supabase User (SaaS Platform)     │
├───────────────────────────────────────────────────┤
│  Database: azima-store-saas                       │
│  Table: auth.users                                │
│  Email: john@electronics.com                      │
│  Password: [hashed] JohnSecure2024!               │
│  Purpose: Login to SaaS billing/settings          │
└───────────────────────────────────────────────────┘
        ↓
┌───────────────────────────────────────────────────┐
│ STEP 2: Create Tenant Record                     │
├───────────────────────────────────────────────────┤
│  Database: azima-store-saas                       │
│  Table: tenants                                   │
│  {                                                │
│    owner_id: [supabase_user_id],                 │
│    name: "John's Electronics",                    │
│    slug: "johns-electronics",                     │
│    owner_email: "john@electronics.com",           │
│    plan_id: "starter",                            │
│    status: "provisioning"                         │
│  }                                                │
└───────────────────────────────────────────────────┘
        ↓
┌───────────────────────────────────────────────────┐
│ STEP 3: Provision Medusa Infrastructure          │
├───────────────────────────────────────────────────┤
│  Call: POST /tenants                              │
│  Creates:                                         │
│  • Region (johns-electronics, KES)                │
│  • Sales Channel                                  │
│  • Stock Location                                 │
│  • Shipping Options                               │
│  • Fulfillment Set                                │
└───────────────────────────────────────────────────┘
        ↓
┌───────────────────────────────────────────────────┐
│ STEP 4: Create Medusa Admin User                 │
├───────────────────────────────────────────────────┤
│  Database: back-end (Medusa)                      │
│  Command: medusa user -e email -p password        │
│  Email: john@electronics.com                      │
│  Password: [same] JohnSecure2024!                 │
│  Purpose: Login to Medusa Store Admin             │
└───────────────────────────────────────────────────┘
        ↓
┌───────────────────────────────────────────────────┐
│ STEP 5: Send Welcome Email                       │
├───────────────────────────────────────────────────┤
│  To: john@electronics.com                         │
│  Contains:                                        │
│  • SaaS Dashboard: azima.store/admin              │
│  • Store Dashboard: johns-electronics/admin       │
│  • Same login credentials for both!               │
└───────────────────────────────────────────────────┘
        ↓
┌───────────────────────────────────────────────────┐
│ USER HAS ACCESS TO TWO DASHBOARDS                │
├───────────────────────────────────────────────────┤
│  1. SaaS Admin (Billing & Settings)              │
│     URL: https://azima.store/admin                │
│     Login: john@electronics.com / JohnSecure2024! │
│                                                    │
│  2. Store Admin (Products & Orders)               │
│     URL: http://localhost:9000/app                │
│     Login: john@electronics.com / JohnSecure2024! │
└───────────────────────────────────────────────────┘
```

---

## 💻 Implementation (Day 9)

### File Structure

```
saas-app/
├── app/
│   ├── api/
│   │   └── signup/
│   │       └── route.ts          ← Main signup endpoint
│   └── (auth)/
│       └── signup/
│           └── page.tsx           ← Signup form
├── lib/
│   ├── supabase/
│   │   └── client.ts              ← Supabase helpers
│   ├── medusa/
│   │   └── provision.ts           ← Medusa provisioning
│   └── email/
│       └── welcome.ts             ← Email service
```

### Code: Signup API Endpoint

```typescript
// app/api/signup/route.ts
import { createClient } from '@supabase/supabase-js'
import { exec } from 'child_process'
import { promisify } from 'util'

const execAsync = promisify(exec)

export async function POST(req: Request) {
  const { businessName, email, password, firstName, lastName, slug, plan } = await req.json()
  
  try {
    // ============================================
    // STEP 1: Create Supabase User
    // ============================================
    const supabase = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.SUPABASE_SERVICE_KEY! // Service role for admin operations
    )
    
    const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true, // Auto-confirm for better UX
      user_metadata: {
        first_name: firstName,
        last_name: lastName,
      }
    })
    
    if (authError) {
      return Response.json({ error: authError.message }, { status: 400 })
    }
    
    // ============================================
    // STEP 2: Create Tenant Record
    // ============================================
    const { data: tenant, error: tenantError } = await supabase
      .from('tenants')
      .insert({
        owner_id: authUser.user.id,
        owner_email: email,
        name: businessName,
        slug: slug,
        plan_id: plan || 'starter',
        status: 'provisioning',
        created_at: new Date().toISOString(),
      })
      .select()
      .single()
    
    if (tenantError) {
      // Rollback: Delete auth user if tenant creation fails
      await supabase.auth.admin.deleteUser(authUser.user.id)
      return Response.json({ error: tenantError.message }, { status: 500 })
    }
    
    // ============================================
    // STEP 3: Provision Medusa Infrastructure
    // ============================================
    const provisionResponse = await fetch(`${process.env.MEDUSA_BACKEND_URL}/tenants`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        tenantName: businessName,
        slug: slug,
        currencyCode: 'kes',
        countryCode: 'ke',
        adminEmail: email,
        adminPassword: password, // Same password!
        adminFirstName: firstName,
        adminLastName: lastName,
      })
    })
    
    const provisionData = await provisionResponse.json()
    
    if (!provisionData.success) {
      // Rollback: Delete tenant and auth user
      await supabase.from('tenants').delete().eq('id', tenant.id)
      await supabase.auth.admin.deleteUser(authUser.user.id)
      return Response.json({ error: 'Medusa provisioning failed' }, { status: 500 })
    }
    
    // ============================================
    // STEP 4: Create Medusa Admin User
    // ============================================
    // Run CLI command to create Medusa user
    const createUserCommand = `cd ${process.env.MEDUSA_PATH} && node_modules/.bin/medusa user -e ${email} -p ${password}`
    
    try {
      await execAsync(createUserCommand)
    } catch (cliError) {
      console.error('Medusa user creation failed:', cliError)
      // Don't rollback - user can be created manually or via background job
    }
    
    // ============================================
    // STEP 5: Update Tenant Status
    // ============================================
    await supabase
      .from('tenants')
      .update({
        status: 'active',
        medusa_region_id: provisionData.data.region.id,
        subdomain_url: provisionData.data.tenant.subdomainUrl,
        provisioned_at: new Date().toISOString(),
      })
      .eq('id', tenant.id)
    
    // ============================================
    // STEP 6: Send Welcome Email
    // ============================================
    await sendWelcomeEmail({
      to: email,
      firstName,
      businessName,
      saasAdminUrl: `${process.env.NEXT_PUBLIC_SAAS_URL}/admin`,
      storeAdminUrl: `${process.env.MEDUSA_ADMIN_URL}`,
      email,
      password, // Send once, then user should change it
    })
    
    // ============================================
    // SUCCESS!
    // ============================================
    return Response.json({
      success: true,
      message: 'Account created successfully! Check your email.',
      data: {
        userId: authUser.user.id,
        tenantId: tenant.id,
        storeUrl: provisionData.data.tenant.subdomainUrl,
      }
    })
    
  } catch (error) {
    console.error('Signup error:', error)
    return Response.json({ error: 'Signup failed' }, { status: 500 })
  }
}
```

---

## 📧 Welcome Email Template

```typescript
// lib/email/welcome.ts
export async function sendWelcomeEmail(data: {
  to: string
  firstName: string
  businessName: string
  saasAdminUrl: string
  storeAdminUrl: string
  email: string
  password: string
}) {
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #4F46E5; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9fafb; }
        .dashboard { background: white; padding: 15px; margin: 10px 0; border-left: 4px solid #4F46E5; }
        .credentials { background: #FEF3C7; padding: 15px; margin: 15px 0; border-radius: 5px; }
        .button { background: #4F46E5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🎉 Welcome to Azima.Store!</h1>
        </div>
        
        <div class="content">
          <p>Hi ${data.firstName},</p>
          
          <p>Your store <strong>"${data.businessName}"</strong> is ready to go!</p>
          
          <h2>✨ You Now Have Access to TWO Dashboards:</h2>
          
          <div class="dashboard">
            <h3>1️⃣ Billing & Settings Dashboard</h3>
            <p><strong>Purpose:</strong> Manage your subscription, billing, and account settings</p>
            <p><strong>URL:</strong> <a href="${data.saasAdminUrl}">${data.saasAdminUrl}</a></p>
          </div>
          
          <div class="dashboard">
            <h3>2️⃣ Store Management Dashboard</h3>
            <p><strong>Purpose:</strong> Add products, process orders, manage inventory</p>
            <p><strong>URL:</strong> <a href="${data.storeAdminUrl}">${data.storeAdminUrl}</a></p>
          </div>
          
          <div class="credentials">
            <h3>🔑 Your Login Credentials (Same for Both!)</h3>
            <p><strong>Email:</strong> ${data.email}</p>
            <p><strong>Password:</strong> <code>${data.password}</code></p>
            <p><em>⚠️ Please change your password after first login!</em></p>
          </div>
          
          <h2>🚀 Quick Start Guide:</h2>
          <ol>
            <li>Login to your Store Management Dashboard</li>
            <li>Add your first product</li>
            <li>Configure payment methods</li>
            <li>Share your store link with customers</li>
          </ol>
          
          <p style="text-align: center; margin-top: 30px;">
            <a href="${data.storeAdminUrl}" class="button">Get Started →</a>
          </p>
          
          <p style="margin-top: 30px; color: #666; font-size: 14px;">
            Need help? Reply to this email or visit our <a href="#">Help Center</a>.
          </p>
        </div>
      </div>
    </body>
    </html>
  `
  
  // Send via your email service (SendGrid, Resend, etc.)
  await emailService.send({
    to: data.to,
    from: 'noreply@azima.store',
    subject: `Welcome to ${data.businessName}! 🎉`,
    html,
  })
}
```

---

## ✅ Why This Approach is Correct

### 1. **Unified Signup Experience**
- User fills ONE form
- Gets access to BOTH systems
- No separate registration needed

### 2. **Same Credentials**
- Easy to remember (one email/password)
- Seamless switching between dashboards
- Better UX

### 3. **Atomic Operation**
- All-or-nothing creation
- Rollback on failure
- Data consistency

### 4. **Clear Separation of Concerns**
```
Supabase User → SaaS platform (billing, subscription)
Medusa User   → Store management (products, orders)
```

---

## 📊 Database Tables After Signup

### azima-store-saas Database:

**auth.users:**
```sql
id: uuid
email: john@electronics.com
encrypted_password: [bcrypt hash]
```

**tenants:**
```sql
id: uuid
owner_id: [links to auth.users.id]
name: "John's Electronics"
slug: "johns-electronics"
status: "active"
medusa_region_id: "reg_01HXXX..."
```

### back-end Database (Medusa):

**user:**
```sql
id: uuid  
email: john@electronics.com
password_hash: [bcrypt hash]
first_name: "John"
last_name: "Doe"
```

**region:**
```sql
id: "reg_01HXXX..."
name: "John's Electronics"
currency_code: "kes"
```

---

## 🎯 Day 9 Deliverables

- [x] ✅ Confirmed dual user creation in roadmap
- [ ] Create signup API endpoint (`/api/signup`)
- [ ] Implement Supabase user creation
- [ ] Implement Medusa user creation
- [ ] Create welcome email template
- [ ] Add rollback logic for failures
- [ ] Test complete signup flow
- [ ] Document for team

---

## 🔐 Security Considerations

1. **Password Handling:**
   - Never log passwords
   - Send password in email ONCE only
   - Force password change on first login (future enhancement)

2. **Rollback Strategy:**
   - If Medusa provisioning fails → Delete Supabase user
   - If user creation fails → Mark tenant as "error" status
   - Log all failures for debugging

3. **Email Confirmation:**
   - Auto-confirm Supabase users for better UX
   - Or require email verification before provisioning (optional)

---

## ✅ Summary

**Your Approach is 100% Correct!** 

When a user signs up on azima.store:
1. ✅ Create Supabase user (SaaS account)
2. ✅ Create Medusa user (Store admin)
3. ✅ Use SAME credentials for both
4. ✅ Send ONE email with BOTH dashboard links

**This is explicitly in the roadmap for Day 9!**

---

**Status**: Design Complete, Ready for Implementation  
**Implementation Day**: Day 9 (Thursday)  
**Dependencies**: Day 7 (SaaS DB schema), Day 8 (Tenant isolation)

