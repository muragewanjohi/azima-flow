# Day 5: Railway Deployment Setup Guide

## Overview
Complete Day 5 tasks for deploying Medusa backend to Railway:
- [ ] Create Railway account and project
- [ ] Set up Medusa deployment pipeline
- [ ] Configure environment variables
- [ ] Test deployment process
- [ ] Set up monitoring

---

## **Step 1: Create Railway Account and Project**

### 1.1 Sign Up for Railway

1. **Visit Railway**: Go to [railway.app](https://railway.app)
2. **Sign Up**: Click "Start a New Project"
3. **Connect GitHub**: 
   - Click "Login with GitHub"
   - Authorize Railway to access your repositories
4. **Verify Email**: Check your email and verify your account

### 1.2 Understanding Railway Plans

**Free Tier (Starter Plan):**
- $5 free credit per month
- No credit card required
- Perfect for development and testing
- Limitations:
  - 500 hours of usage
  - 1GB memory
  - 1GB disk

**Paid Plans (if needed later):**
- **Developer Plan**: $5/month + usage
- **Team Plan**: $20/month + usage
- Pay only for what you use

**Recommendation for MVP:** Start with the free tier, upgrade when needed.

---

## **Step 2: Set Up Medusa Deployment Pipeline**

### 2.1 Create New Project

1. **Dashboard**: Go to your Railway dashboard
2. **New Project**: Click "+ New Project"
3. **Deploy from GitHub repo**: Select this option
4. **Select Repository**: Choose `muragewanjohi/azima-flow`
5. **Configure Deployment**:
   - Railway will auto-detect the repository structure

### 2.2 Add PostgreSQL Database

1. **Add Service**: In your Railway project, click "+ New"
2. **Database**: Select "Database" → "Add PostgreSQL"
3. **Wait for Provisioning**: Railway will create a PostgreSQL instance
4. **Note Database URL**: Railway automatically generates `DATABASE_URL`

### 2.3 Add Redis Service

1. **Add Service**: Click "+ New" again
2. **Database**: Select "Database" → "Add Redis"
3. **Wait for Provisioning**: Railway will create a Redis instance
4. **Note Redis URL**: Railway automatically generates `REDIS_URL`

### 2.4 Configure Medusa Service

1. **Add Service**: Click "+ New" → "GitHub Repo"
2. **Select Repository**: Choose your `azima-flow` repository
3. **Configure Root Directory**:
   - Go to Service Settings
   - Set "Root Directory" to `store-flow`
4. **Configure Build Command**:
   ```bash
   npm install && npm run build
   ```
5. **Configure Start Command**:
   ```bash
   npm run start
   ```

### 2.5 Set Up Build Configuration

Create a `railway.json` file in the `store-flow` directory:

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "npm install && npm run build"
  },
  "deploy": {
    "startCommand": "npm run start",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

### 2.6 Configure Port and Networking

1. **Port Configuration**:
   - Railway auto-detects port 9000 (Medusa default)
   - If needed, add environment variable: `PORT=9000`

2. **Public Domain**:
   - Go to Settings → Networking
   - Click "Generate Domain"
   - You'll get a URL like: `https://your-app.up.railway.app`
   - Note this URL for your storefront configuration

---

## **Step 3: Configure Environment Variables**

### 3.1 Required Environment Variables

In Railway dashboard, go to your Medusa service → Variables tab.

Add the following variables:

```env
# Database (Auto-populated by Railway when you connect PostgreSQL)
DATABASE_URL=${{Postgres.DATABASE_URL}}

# Redis (Auto-populated by Railway when you connect Redis)
REDIS_URL=${{Redis.REDIS_URL}}

# Node Environment
NODE_ENV=production

# CORS Origins (Update these with your actual domains)
STORE_CORS=https://your-storefront.vercel.app,http://localhost:8000
ADMIN_CORS=https://your-admin.vercel.app,http://localhost:7001
AUTH_CORS=https://your-admin.vercel.app,http://localhost:7001

# JWT Secrets (Generate strong secrets for production)
JWT_SECRET=your-generated-jwt-secret-here-make-it-long-and-random
COOKIE_SECRET=your-generated-cookie-secret-here-also-long-and-random

# Medusa Admin
MEDUSA_ADMIN_ONBOARDING_TYPE=default

# Port (Optional, Railway auto-detects)
PORT=9000
```

### 3.2 Generate Strong Secrets

Use these commands to generate secure secrets:

```bash
# Generate JWT_SECRET
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"

# Generate COOKIE_SECRET
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

### 3.3 Variable References

Railway uses `${{SERVICE.VARIABLE}}` syntax for referencing variables between services:

- `${{Postgres.DATABASE_URL}}` - References PostgreSQL database URL
- `${{Redis.REDIS_URL}}` - References Redis URL

These are automatically populated when you connect services.

---

## **Step 4: Test Deployment Process**

### 4.1 Trigger Initial Deployment

1. **Push to GitHub**:
   ```bash
   cd store-flow
   git add railway.json
   git commit -m "Add Railway deployment configuration"
   git push origin main
   ```

2. **Monitor Deployment**:
   - Railway automatically triggers a deployment
   - Watch the build logs in Railway dashboard
   - Look for successful build messages

### 4.2 Run Database Migrations

After deployment, you need to run migrations:

1. **Option A: Using Railway CLI**
   ```bash
   # Install Railway CLI
   npm install -g @railway/cli
   
   # Login to Railway
   railway login
   
   # Link to your project
   railway link
   
   # Run migrations
   railway run npm run db:migrate
   ```

2. **Option B: Using Railway Dashboard**
   - Go to your Medusa service
   - Click "Deploy" → "Custom Deployment"
   - Add a one-time command: `npm run db:migrate`

### 4.3 Verify Deployment

1. **Check Health Endpoint**:
   ```bash
   curl https://your-app.up.railway.app/health
   ```
   
   Expected response:
   ```json
   {
     "status": "ok"
   }
   ```

2. **Check Store API**:
   ```bash
   curl https://your-app.up.railway.app/store/products
   ```

3. **Access Admin Panel**:
   - Open: `https://your-app.up.railway.app/app`
   - Create admin user account

### 4.4 Common Deployment Issues

**Issue 1: Build Fails**
```
Error: Cannot find module '@medusajs/medusa'
```
**Solution**: Ensure `node_modules` is not in `.gitignore` or Railway is running `npm install`

**Issue 2: Database Connection Error**
```
Error: connect ECONNREFUSED
```
**Solution**: 
- Verify `DATABASE_URL` is set correctly
- Check PostgreSQL service is running
- Ensure services are in the same Railway project

**Issue 3: Port Binding Error**
```
Error: listen EADDRINUSE :::9000
```
**Solution**: Remove `PORT` env variable and let Railway auto-detect

**Issue 4: Migration Fails**
```
Error: relation "product" already exists
```
**Solution**: This is normal if migrations were run before. Skip if tables exist.

---

## **Step 5: Set Up Monitoring**

### 5.1 Railway Built-in Monitoring

Railway provides basic monitoring out of the box:

1. **Metrics Dashboard**:
   - Go to your service → Metrics tab
   - View CPU usage, Memory usage, Network traffic

2. **Logs**:
   - Go to Deployments → View Logs
   - Real-time log streaming
   - Filter by service

3. **Alerts** (Available on paid plans):
   - Set up alerts for service failures
   - Email notifications

### 5.2 Configure Application Logging

Update your Medusa configuration to improve logging in production.

Create `store-flow/logging-config.js`:

```javascript
module.exports = {
  projectConfig: {
    // ... existing config
    logging: {
      level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
      // Add structured logging
      format: 'json'
    }
  }
}
```

### 5.3 Health Check Endpoint

Railway automatically monitors your app's health. Verify it works:

Create `store-flow/src/api/health/route.ts`:

```typescript
import type { MedusaRequest, MedusaResponse } from "@medusajs/framework/http"

export async function GET(
  req: MedusaRequest,
  res: MedusaResponse
): Promise<void> {
  res.json({
    status: "ok",
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV
  })
}
```

### 5.4 External Monitoring (Optional - for later)

For production, consider adding:

1. **Sentry** (Error Tracking):
   ```bash
   npm install @sentry/node
   ```

2. **Better Stack** (Logs):
   - Free tier available
   - Better log search and analysis

3. **Uptime Robot** (Uptime Monitoring):
   - Free tier: 50 monitors
   - Checks every 5 minutes

### 5.5 Set Up Deployment Notifications

1. **GitHub Integration**:
   - Railway automatically comments on commits
   - Shows deployment status

2. **Slack/Discord** (Optional):
   - Go to Project Settings → Integrations
   - Connect Slack/Discord for deployment notifications

---

## **Step 6: Performance Optimization**

### 6.1 Enable Build Cache

Railway automatically caches dependencies, but you can optimize:

In `railway.json`:
```json
{
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "npm ci --prefer-offline && npm run build"
  }
}
```

### 6.2 Configure Connection Pooling

Update your `DATABASE_URL` to include pooling:

```env
DATABASE_URL=postgresql://user:pass@host:5432/db?connection_limit=10&pool_timeout=30
```

### 6.3 Optimize Memory Usage

In Railway service settings:
- Start with 1GB RAM (free tier)
- Monitor usage in Metrics
- Upgrade if needed (paid plans)

---

## **Step 7: Verify Day 5 Completion**

Check that all Day 5 tasks are completed:

- [ ] ✅ Railway account created and verified
- [ ] ✅ Railway project created with services (Medusa, PostgreSQL, Redis)
- [ ] ✅ Deployment pipeline configured with `railway.json`
- [ ] ✅ Environment variables configured
- [ ] ✅ Database migrations run successfully
- [ ] ✅ Deployment tested and health endpoint working
- [ ] ✅ Monitoring dashboard configured
- [ ] ✅ Logs accessible and readable

---

## **Step 8: Update Storefront Configuration**

After Railway deployment, update your storefront to connect to Railway backend:

1. **Update `.env.local` in `store-flow-storefront`**:
   ```env
   NEXT_PUBLIC_MEDUSA_BACKEND_URL=https://your-app.up.railway.app
   ```

2. **Update CORS in Railway**:
   - Add your Vercel deployment URL to `STORE_CORS`
   - Example: `https://your-store.vercel.app`

3. **Test End-to-End**:
   - Deploy storefront to Vercel
   - Verify it connects to Railway backend
   - Test product fetching and cart operations

---

## **Railway CLI Reference**

### Installation
```bash
npm install -g @railway/cli
```

### Common Commands
```bash
# Login to Railway
railway login

# Link to project
railway link

# View logs
railway logs

# Run commands in Railway environment
railway run <command>

# Open project in browser
railway open

# Show environment variables
railway variables

# Deploy manually
railway up
```

---

## **Cost Estimation (Railway)**

### Free Tier Usage
- **Included**: $5 free credit/month
- **Estimated Usage for MVP**:
  - Medusa backend: ~$3-4/month
  - PostgreSQL: ~$1-2/month
  - Redis: ~$0.50-1/month
  - **Total**: ~$4.50-7/month (slightly over free tier)

### Paid Tier Recommendation
- Start with **Developer Plan** ($5/month + usage)
- Estimated total: **$10-15/month** for early stage
- Scale as you grow

### Cost Optimization Tips
1. **Use Serverless/Edge for Storefront** (Vercel - stay in free tier)
2. **Optimize Database Queries** (reduce connection time)
3. **Use Redis Caching** (reduce database load)
4. **Monitor Resource Usage** (Railway dashboard)

---

## **Troubleshooting Guide**

### Build Issues

**Problem**: Dependencies not installing
```bash
# Solution: Clear cache and rebuild
railway run npm cache clean --force
railway run npm install
```

**Problem**: TypeScript errors during build
```bash
# Solution: Check tsconfig.json
railway run npm run build -- --verbose
```

### Runtime Issues

**Problem**: App crashes after deployment
```bash
# Solution: Check logs
railway logs --tail 100

# Check specific service
railway logs --service medusa-backend
```

**Problem**: Database connection timeout
```bash
# Solution: Verify DATABASE_URL
railway variables | grep DATABASE_URL

# Test connection
railway run node -e "console.log(process.env.DATABASE_URL)"
```

### Migration Issues

**Problem**: Migrations fail on Railway
```bash
# Solution: Run migrations manually
railway run npm run db:migrate

# Reset database (caution: data loss)
railway run npm run db:reset
```

---

## **Next Steps: Week 1**

Once Day 5 is complete, you'll move to **Week 1: Core Infrastructure**

**Day 6 (Monday):** Region Provisioning Script
- Design tenant provisioning workflow
- Create Medusa Region creation script
- Implement admin user creation
- Set up default tax/shipping zones
- Test provisioning process

---

## **Resources**

- [Railway Documentation](https://docs.railway.app/)
- [Railway CLI Reference](https://docs.railway.app/develop/cli)
- [Medusa Deployment Guide](https://docs.medusajs.com/deployment)
- [Railway Discord Community](https://discord.gg/railway)

---

## **Checklist for Completion**

Mark each item as you complete it:

### Account Setup
- [ ] Railway account created
- [ ] GitHub connected to Railway
- [ ] Email verified

### Project Setup
- [ ] New Railway project created
- [ ] PostgreSQL database added
- [ ] Redis service added
- [ ] Medusa service configured

### Configuration
- [ ] `railway.json` created
- [ ] Environment variables set
- [ ] Secrets generated
- [ ] CORS configured

### Deployment
- [ ] Code pushed to GitHub
- [ ] Deployment triggered successfully
- [ ] Build completed without errors
- [ ] Database migrations run
- [ ] Health endpoint accessible

### Verification
- [ ] Store API responds correctly
- [ ] Admin panel accessible
- [ ] Logs visible in Railway
- [ ] Metrics dashboard working

### Documentation
- [ ] Railway URLs documented
- [ ] Environment variables backed up
- [ ] Deployment process documented

---

**Status:** 🟡 In Progress  
**Next:** Complete all tasks and mark Day 5 as ✅ COMPLETED in `ROADMAP_TRACKER.md`

