# Day 5: Railway Deployment - Quick Start Checklist ✅

Use this checklist to complete Day 5 tasks step-by-step.

---

## ⏱️ **Time Estimate: 2-3 hours**

---

## **Part 1: Account Setup (15 minutes)**

- [ ] **1.1** Visit [railway.app](https://railway.app)
- [ ] **1.2** Click "Start a New Project"
- [ ] **1.3** Login with GitHub
- [ ] **1.4** Authorize Railway to access your repositories
- [ ] **1.5** Verify your email address

---

## **Part 2: Create Railway Project (30 minutes)**

### Create New Project
- [ ] **2.1** Click "+ New Project" in Railway dashboard
- [ ] **2.2** Select "Deploy from GitHub repo"
- [ ] **2.3** Choose `muragewanjohi/azima-flow` repository
- [ ] **2.4** Wait for initial setup

### Add PostgreSQL Database
- [ ] **2.5** Click "+ New" in your project
- [ ] **2.6** Select "Database" → "Add PostgreSQL"
- [ ] **2.7** Wait for provisioning (1-2 minutes)
- [ ] **2.8** Copy the `DATABASE_URL` (you'll need it later)

### Add Redis Service
- [ ] **2.9** Click "+ New" again
- [ ] **2.10** Select "Database" → "Add Redis"
- [ ] **2.11** Wait for provisioning (1-2 minutes)
- [ ] **2.12** Copy the `REDIS_URL` (you'll need it later)

### Configure Medusa Service
- [ ] **2.13** Click on the Medusa service (auto-created from GitHub)
- [ ] **2.14** Go to Settings → Service Settings
- [ ] **2.15** Set "Root Directory" to: `store-flow`
- [ ] **2.16** Save changes

---

## **Part 3: Generate Secrets (5 minutes)**

Run these commands on your local machine:

```bash
# Generate JWT_SECRET
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"

# Copy the output and save it

# Generate COOKIE_SECRET
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"

# Copy this output too and save it
```

- [ ] **3.1** Run first command and copy `JWT_SECRET`
- [ ] **3.2** Run second command and copy `COOKIE_SECRET`
- [ ] **3.3** Save both secrets in a secure note (you'll add them in the next step)

---

## **Part 4: Configure Environment Variables (20 minutes)**

In Railway, go to your Medusa service → Variables tab:

### Required Variables
- [ ] **4.1** Add `NODE_ENV` = `production`
- [ ] **4.2** Add `DATABASE_URL` = `${{Postgres.DATABASE_URL}}`
- [ ] **4.3** Add `REDIS_URL` = `${{Redis.REDIS_URL}}`
- [ ] **4.4** Add `PORT` = `9000`

### CORS Configuration
- [ ] **4.5** Add `STORE_CORS` = `http://localhost:8000` (update later with your Vercel URL)
- [ ] **4.6** Add `ADMIN_CORS` = `http://localhost:7001`
- [ ] **4.7** Add `AUTH_CORS` = `http://localhost:7001`

### Secrets (use the ones you generated in Part 3)
- [ ] **4.8** Add `JWT_SECRET` = `[your-generated-secret]`
- [ ] **4.9** Add `COOKIE_SECRET` = `[your-generated-secret]`

### Optional
- [ ] **4.10** Add `MEDUSA_ADMIN_ONBOARDING_TYPE` = `default`

---

## **Part 5: Deploy Configuration Files (10 minutes)**

The `railway.json` file has already been created for you!

Now commit and push it:

```bash
cd store-flow
git status
git add railway.json
git commit -m "Add Railway deployment configuration"
git push origin main
```

- [ ] **5.1** Verify `railway.json` exists in `store-flow/` directory
- [ ] **5.2** Run `git status` to check
- [ ] **5.3** Add the file: `git add railway.json`
- [ ] **5.4** Commit: `git commit -m "Add Railway deployment configuration"`
- [ ] **5.5** Push: `git push origin main`
- [ ] **5.6** Watch deployment in Railway dashboard

---

## **Part 6: Monitor Deployment (15 minutes)**

- [ ] **6.1** Go to Railway dashboard
- [ ] **6.2** Click on your Medusa service
- [ ] **6.3** Click "Deployments" tab
- [ ] **6.4** Watch the build logs (should take 5-10 minutes)
- [ ] **6.5** Wait for "SUCCESS" status
- [ ] **6.6** If failed, check logs for errors

### If Build Fails:
Common fixes:
- Check that Root Directory is set to `store-flow`
- Verify all environment variables are set
- Check build logs for specific errors
- Redeploy if needed

---

## **Part 7: Run Database Migrations (15 minutes)**

### Option A: Using Railway CLI (Recommended)

```bash
# Install Railway CLI globally
npm install -g @railway/cli

# Login to Railway
railway login

# Link to your project
railway link

# Run migrations
railway run npm run db:migrate
```

- [ ] **7.1** Install Railway CLI: `npm install -g @railway/cli`
- [ ] **7.2** Login: `railway login`
- [ ] **7.3** Link to project: `railway link` (select your project)
- [ ] **7.4** Run migrations: `railway run npm run db:migrate`
- [ ] **7.5** Verify migrations completed successfully

### Option B: Using Railway Dashboard

- [ ] **7.1** Go to your Medusa service in Railway
- [ ] **7.2** Click Settings → Deploy
- [ ] **7.3** Under "Custom Start Command", temporarily add: `npm run db:migrate`
- [ ] **7.4** Click "Deploy"
- [ ] **7.5** After migration completes, change back to: `npm run start`

---

## **Part 8: Generate Public Domain (5 minutes)**

- [ ] **8.1** Go to your Medusa service in Railway
- [ ] **8.2** Click Settings → Networking
- [ ] **8.3** Click "Generate Domain"
- [ ] **8.4** Copy your URL (e.g., `https://your-app.up.railway.app`)
- [ ] **8.5** Save this URL - you'll need it for your storefront

---

## **Part 9: Test Deployment (15 minutes)**

### Test Health Endpoint

```bash
# Replace with your actual Railway URL
curl https://your-app.up.railway.app/health
```

- [ ] **9.1** Open terminal
- [ ] **9.2** Run health check with your Railway URL
- [ ] **9.3** Verify you get a response (should return JSON with status)

### Test Store API

```bash
curl https://your-app.up.railway.app/store/products
```

- [ ] **9.4** Test store API endpoint
- [ ] **9.5** Should return empty array `[]` or products if seeded

### Test Admin Panel

- [ ] **9.6** Open browser to `https://your-app.up.railway.app/app`
- [ ] **9.7** You should see the Medusa admin login page
- [ ] **9.8** Create an admin account if prompted

---

## **Part 10: Set Up Monitoring (10 minutes)**

### Railway Built-in Monitoring
- [ ] **10.1** Go to your Medusa service
- [ ] **10.2** Click "Metrics" tab
- [ ] **10.3** Verify you can see CPU, Memory, and Network metrics
- [ ] **10.4** Click "Deployments" → View recent deployment logs

### Configure Notifications (Optional)
- [ ] **10.5** Go to Project Settings
- [ ] **10.6** Check "Integrations" for Slack/Discord options
- [ ] **10.7** Connect if desired (can skip for now)

---

## **Part 11: Document Your Setup (10 minutes)**

Create a file to save your Railway configuration:

- [ ] **11.1** Create a secure note with:
  - Railway Project URL
  - Railway Public Domain
  - Database URL format
  - Redis URL format
  - JWT_SECRET (keep secure!)
  - COOKIE_SECRET (keep secure!)

- [ ] **11.2** Update `ROADMAP_TRACKER.md`:
  - Mark Day 5 tasks as complete
  - Add any notes about your Railway setup

---

## **Part 12: Update Storefront Configuration (5 minutes)**

Later, when deploying your storefront to Vercel:

```bash
cd ../store-flow-storefront
```

Update `.env.local`:
```env
NEXT_PUBLIC_MEDUSA_BACKEND_URL=https://your-app.up.railway.app
```

- [ ] **12.1** Note your Railway URL for later
- [ ] **12.2** When deploying storefront, update this variable
- [ ] **12.3** Also update `STORE_CORS` in Railway to include Vercel URL

---

## **✅ Day 5 Completion Checklist**

Before marking Day 5 as complete, verify:

- [ ] ✅ Railway account created and verified
- [ ] ✅ Railway project with 3 services (Medusa, PostgreSQL, Redis)
- [ ] ✅ Environment variables configured correctly
- [ ] ✅ Code deployed successfully
- [ ] ✅ Database migrations completed
- [ ] ✅ Public domain generated
- [ ] ✅ Health endpoint returns success
- [ ] ✅ Admin panel accessible
- [ ] ✅ Monitoring dashboard working
- [ ] ✅ Configuration documented

---

## **🎉 Success Criteria**

You've successfully completed Day 5 when:

1. ✅ Your Railway URL returns `{"status":"ok"}` from `/health`
2. ✅ You can access the admin panel at `https://your-app.up.railway.app/app`
3. ✅ Logs show no critical errors
4. ✅ All services are running (green status in Railway)

---

## **🚨 Common Issues & Quick Fixes**

### Issue: Build fails with "Cannot find module"
**Fix:** Check that Root Directory is set to `store-flow`

### Issue: App crashes immediately
**Fix:** Check environment variables, especially `DATABASE_URL` and `REDIS_URL`

### Issue: Can't access admin panel
**Fix:** 
1. Check deployment logs
2. Verify migrations ran successfully
3. Try redeploying

### Issue: Database connection error
**Fix:**
1. Verify PostgreSQL service is running
2. Check `DATABASE_URL` includes `${{Postgres.DATABASE_URL}}`
3. Restart Medusa service

---

## **📚 Resources**

- **Detailed Guide:** `DAY5-RAILWAY-DEPLOYMENT.md`
- **Railway Docs:** https://docs.railway.app/
- **Medusa Docs:** https://docs.medusajs.com/deployment
- **Railway Status:** https://status.railway.app/

---

## **⏭️ What's Next?**

After completing Day 5:

1. **Mark tasks complete** in `ROADMAP_TRACKER.md`
2. **Document** your Railway URLs and configuration
3. **Prepare for Week 1, Day 6:** Region Provisioning Script
4. **Optional:** Seed some test products to verify everything works

---

**Estimated Total Time:** 2-3 hours  
**Difficulty:** Moderate  
**Prerequisites:** Completed Days 1-4

**Good luck! 🚀**

