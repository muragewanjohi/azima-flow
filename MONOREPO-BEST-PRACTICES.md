# Monorepo Best Practices for Azima.Store

## 📋 **Decision: Keep Monorepo for MVP**

**Recommendation:** ✅ Keep backend and frontend in the same repository for now.

**Reasoning:**
- Solo developer (easier coordination)
- Tight coupling between Medusa backend and Next.js storefront
- Shared TypeScript types and utilities
- Faster iteration during MVP phase
- Atomic commits across both projects

**When to split:** After MVP, when you have a team or need separate permissions.

---

## 🏗️ **Current Repository Structure**

```
azima-flow/                          (Root - Monorepo)
├── package.json                     (Root workspace configuration)
├── .gitignore                       (Shared ignore rules)
├── README.md                        (Project documentation)
├── ROADMAP_TRACKER.md              (Development roadmap)
│
├── store-flow/                      (Backend - Medusa)
│   ├── package.json                (Backend dependencies)
│   ├── medusa-config.ts            (Medusa configuration)
│   ├── railway.json                (Railway deployment config)
│   ├── .env                        (Backend environment)
│   └── src/                        (Backend source code)
│
└── store-flow-storefront/          (Frontend - Next.js)
    ├── package.json                (Frontend dependencies)
    ├── next.config.js              (Next.js configuration)
    ├── .env.local                  (Frontend environment)
    └── src/                        (Frontend source code)
```

---

## ✅ **Monorepo Advantages for Your SaaS**

### **1. Shared TypeScript Types**

Create a shared types package:

```
azima-flow/
├── packages/
│   └── shared-types/
│       ├── package.json
│       ├── tsconfig.json
│       └── src/
│           ├── index.ts
│           ├── product.types.ts
│           ├── cart.types.ts
│           └── order.types.ts
```

**Example:** `packages/shared-types/src/product.types.ts`
```typescript
// Shared between backend and frontend
export interface Product {
  id: string
  title: string
  description: string
  price: number
  variants: Variant[]
}

export interface Variant {
  id: string
  title: string
  sku: string
  inventory_quantity: number
}
```

**Usage in frontend:**
```typescript
import { Product } from '@azima/shared-types'
```

**Usage in backend:**
```typescript
import { Product } from '@azima/shared-types'
```

### **2. Atomic Commits**

Make changes to API and frontend in one commit:

```bash
# Change API endpoint + update frontend in one commit
git add store-flow/src/api/products/route.ts
git add store-flow-storefront/src/lib/data/products.ts
git commit -m "feat: add product filtering API and frontend"
```

### **3. Simplified Development**

```bash
# Clone once, get everything
git clone https://github.com/muragewanjohi/azima-flow.git
cd azima-flow

# Install all dependencies
npm install

# Run both backend and frontend
npm run dev
```

---

## 🚀 **Optimized Workspace Setup**

### **Root package.json** (Already created ✅)

Use npm workspaces to manage both projects:

```json
{
  "workspaces": [
    "store-flow",
    "store-flow-storefront"
  ],
  "scripts": {
    "dev": "concurrently \"npm run dev:backend\" \"npm run dev:frontend\"",
    "dev:backend": "npm run dev --workspace=store-flow",
    "dev:frontend": "npm run dev --workspace=store-flow-storefront",
    "build": "npm run build:backend && npm run build:frontend"
  }
}
```

### **Quick Commands**

```bash
# Install dependencies for both projects
npm install

# Run backend only
npm run dev:backend

# Run frontend only
npm run dev:frontend

# Run both simultaneously
npm run dev

# Build both projects
npm run build
```

---

## 📁 **Recommended Folder Structure (Future)**

As your project grows, consider this structure:

```
azima-flow/
├── package.json                    (Root workspace)
├── .github/
│   └── workflows/
│       ├── backend-deploy.yml      (CI/CD for backend)
│       └── frontend-deploy.yml     (CI/CD for frontend)
│
├── packages/                       (Shared packages)
│   ├── shared-types/              (TypeScript types)
│   ├── shared-utils/              (Common utilities)
│   └── shared-config/             (ESLint, Prettier config)
│
├── apps/
│   ├── backend/                   (Medusa - currently store-flow)
│   │   ├── package.json
│   │   └── railway.json
│   └── storefront/                (Next.js - currently store-flow-storefront)
│       ├── package.json
│       └── vercel.json
│
└── docs/                          (Documentation)
    ├── API.md
    ├── SETUP.md
    └── CONTRIBUTING.md
```

---

## 🔧 **Deployment Configuration**

### **Backend (Railway)**

**File:** `store-flow/railway.json`
```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "npm install && npm run build"
  },
  "deploy": {
    "startCommand": "npm run start",
    "restartPolicyType": "ON_FAILURE"
  }
}
```

**Railway Settings:**
- Root Directory: `store-flow`
- Build Command: Auto-detected from railway.json
- Start Command: Auto-detected from railway.json

### **Frontend (Vercel)**

**File:** `store-flow-storefront/vercel.json` (create later)
```json
{
  "buildCommand": "npm run build",
  "devCommand": "npm run dev",
  "installCommand": "npm install",
  "framework": "nextjs",
  "outputDirectory": ".next"
}
```

**Vercel Settings:**
- Root Directory: `store-flow-storefront`
- Framework Preset: Next.js
- Build Command: Auto-detected

---

## 🎯 **CI/CD Strategy for Monorepo**

### **GitHub Actions: Separate Workflows**

**File:** `.github/workflows/backend-deploy.yml`
```yaml
name: Deploy Backend to Railway

on:
  push:
    branches: [main]
    paths:
      - 'store-flow/**'
      - '.github/workflows/backend-deploy.yml'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to Railway
        run: echo "Railway auto-deploys on push"
```

**File:** `.github/workflows/frontend-deploy.yml`
```yaml
name: Deploy Frontend to Vercel

on:
  push:
    branches: [main]
    paths:
      - 'store-flow-storefront/**'
      - '.github/workflows/frontend-deploy.yml'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to Vercel
        run: echo "Vercel auto-deploys on push"
```

**Benefits:**
- Only deploys what changed
- Faster CI/CD (doesn't rebuild both on every change)
- Clear deployment logs

---

## 📝 **.gitignore Best Practices**

```gitignore
# Root level ignores
node_modules/
.DS_Store
*.log
.env
.env.local

# Build outputs
.next/
dist/
.medusa/
build/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
Thumbs.db
```

---

## 🔄 **Migration Path: Monorepo → Polyrepo (Future)**

If you decide to split later, here's the process:

### **Step 1: Create New Repositories**
```bash
# Create backend repo
gh repo create azima-flow-backend --private

# Create frontend repo
gh repo create azima-flow-storefront --private
```

### **Step 2: Extract with History**
```bash
# Extract backend with git history
git subtree split -P store-flow -b backend-only
cd ../azima-flow-backend
git pull ../azima-flow backend-only

# Extract frontend with git history
git subtree split -P store-flow-storefront -b frontend-only
cd ../azima-flow-storefront
git pull ../azima-flow frontend-only
```

### **Step 3: Create Shared Package**
```bash
# Publish shared types to npm (private)
npm publish @azima/shared-types --access restricted
```

### **Step 4: Update Dependencies**
```json
// Backend package.json
{
  "dependencies": {
    "@azima/shared-types": "^1.0.0"
  }
}

// Frontend package.json
{
  "dependencies": {
    "@azima/shared-types": "^1.0.0"
  }
}
```

---

## ✅ **Current Recommendations**

### **For Now (MVP Phase):**

1. ✅ **Keep monorepo** - It's working well for solo development
2. ✅ **Use npm workspaces** - Already configured in root package.json
3. ✅ **Configure root directories** - Railway and Vercel know where to build
4. ✅ **Share code liberally** - Create shared packages when needed
5. ✅ **Commit atomically** - Make API + frontend changes together

### **After 6-12 Months (Scale Phase):**

1. 🔄 **Consider splitting** if:
   - You have a team (3+ developers)
   - Need different access controls
   - Want independent deployment schedules
   - Supporting multiple storefronts

2. 📦 **Or evolve monorepo** with:
   - Turborepo for faster builds
   - Nx for advanced monorepo features
   - Lerna for package versioning

---

## 🌟 **Alternative: Monorepo Tools (Future)**

If your monorepo grows complex, consider:

### **Turborepo**
```bash
npx create-turbo@latest
```
**Benefits:**
- Incremental builds
- Remote caching
- Parallel execution
- Better for multiple packages

### **Nx**
```bash
npx create-nx-workspace@latest
```
**Benefits:**
- Dependency graph
- Affected commands (only build what changed)
- Plugin ecosystem
- Great for large teams

---

## 📊 **Decision Matrix**

| Factor | Monorepo | Polyrepo |
|--------|----------|----------|
| **Team Size** | 1-3 devs ✅ | 4+ devs ✅ |
| **Shared Code** | Easy ✅ | Hard ❌ |
| **Deployment** | Complex ⚠️ | Simple ✅ |
| **Type Safety** | Easy ✅ | Hard ❌ |
| **CI/CD Speed** | Moderate ⚠️ | Fast ✅ |
| **Learning Curve** | Low ✅ | Low ✅ |
| **Versioning** | Coupled ⚠️ | Independent ✅ |
| **Your Current Stage** | **Perfect ✅** | Overkill ❌ |

---

## 🎯 **Final Recommendation**

**For your MVP (next 6 months):**

✅ **Keep the monorepo** - You're doing it right!

**Why:**
- You're solo (no coordination issues)
- Fast iteration is critical for MVP
- Shared types between backend/frontend
- Simpler local development
- One source of truth

**Action Items:**
1. ✅ Keep current structure (already done)
2. ✅ Use npm workspaces (already configured)
3. ✅ Set Railway root directory to `store-flow` (fixing now)
4. ✅ Set Vercel root directory to `store-flow-storefront` (later)
5. 📝 Create shared packages only when needed

**Revisit this decision:** After MVP launch, when you have users and potentially a team.

---

**You made the right choice! The monorepo structure is perfect for your current stage.** 🚀

