# Day 5: Railway Deployment - Supabase Database Version

## ⚡ Quick Start for Supabase Users

Since you're already using Supabase PostgreSQL, you only need to add **Redis** to Railway, not another database!

---

## 📋 **Simplified Checklist**

### **Part 1: Railway Account Setup (15 min)**

- [ ] Visit [railway.app](https://railway.app)
- [ ] Click "Start a New Project"
- [ ] Login with GitHub
- [ ] Authorize Railway
- [ ] Verify email

---

### **Part 2: Create Railway Project (20 min)**

#### Create New Project
- [ ] Click "+ New Project"
- [ ] Select "Deploy from GitHub repo"
- [ ] Choose `muragewanjohi/azima-flow`
- [ ] Wait for initial setup

#### Add ONLY Redis (NOT PostgreSQL!)
- [ ] Click "+ New" 
- [ ] Select "Database" → "Add Redis"
- [ ] Wait for provisioning (1-2 minutes)
- [ ] ✅ Done! (No PostgreSQL needed)

#### Configure Medusa Service
- [ ] Click on the Medusa service
- [ ] Go to Settings → Service Settings
- [ ] Set "Root Directory" to: `store-flow`
- [ ] Save changes

---

### **Part 3: Generate Secrets (5 min)**

```bash
# Generate JWT_SECRET
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"

# Generate COOKIE_SECRET
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

- [ ] Copy both secrets and save them securely

---

### **Part 4: Configure Environment Variables (15 min)**

In Railway → Medusa Service → Variables:

#### Database (Use Existing Supabase!)
```env
DATABASE_URL=postgresql://postgres.aaadfbrxcggeltebobpm:SiF3iS1xDl9hnTBb@aws-1-us-east-2.pooler.supabase.com:6543/postgres?connection_limit=5&pool_timeout=20&connect_timeout=10
```

- [ ] Add `DATABASE_URL` with your **existing Supabase connection string**

#### Redis (Railway Service)
- [ ] Add `REDIS_URL` = `${{Redis.REDIS_URL}}`

#### Environment
- [ ] Add `NODE_ENV` = `production`
- [ ] Add `PORT` = `9000`

#### CORS
- [ ] Add `STORE_CORS` = `http://localhost:8000`
- [ ] Add `ADMIN_CORS` = `http://localhost:7001`
- [ ] Add `AUTH_CORS` = `http://localhost:7001`

#### Secrets
- [ ] Add `JWT_SECRET` = [your generated secret]
- [ ] Add `COOKIE_SECRET` = [your generated secret]

#### Optional
- [ ] Add `MEDUSA_ADMIN_ONBOARDING_TYPE` = `default`

---

### **Part 5: Deploy (15 min)**

```bash
# Commit the railway.json file
git add store-flow/railway.json
git commit -m "Add Railway deployment configuration"
git push origin main
```

- [ ] Push code to GitHub
- [ ] Watch deployment in Railway dashboard
- [ ] Wait for "SUCCESS" status (5-10 minutes)

---

### **Part 6: Run Migrations (15 min)**

**Important:** Your migrations will run on your **Supabase database**, not Railway!

#### Option A: Railway CLI
```bash
npm install -g @railway/cli
railway login
railway link
railway run npm run db:migrate
```

#### Option B: Local Migration
Since your Supabase `DATABASE_URL` is already in `.env`:
```bash
cd store-flow
npm run db:migrate
```

- [ ] Run migrations (choose one option)
- [ ] Verify migrations completed successfully

---

### **Part 7: Generate Public Domain (5 min)**

- [ ] Go to Medusa service → Settings → Networking
- [ ] Click "Generate Domain"
- [ ] Copy your URL (e.g., `https://your-app.up.railway.app`)
- [ ] Save this URL

---

### **Part 8: Test Deployment (15 min)**

#### Health Check
```bash
curl https://your-app.up.railway.app/health
```

- [ ] Test health endpoint
- [ ] Should return `{"status":"ok"}`

#### Store API
```bash
curl https://your-app.up.railway.app/store/products
```

- [ ] Test store API
- [ ] Should return products or empty array

#### Admin Panel
- [ ] Open `https://your-app.up.railway.app/app`
- [ ] Verify admin panel loads
- [ ] Create admin account if needed

---

### **Part 9: Verify Database Connection (10 min)**

#### Check Supabase Connection
- [ ] Go to Supabase dashboard
- [ ] Open `back-end` project
- [ ] Go to Database → Tables
- [ ] Verify Medusa tables exist (cart, product, order, etc.)
- [ ] Check Table Editor for recent data

#### Check Railway Logs
- [ ] Go to Railway → Medusa Service → Logs
- [ ] Look for successful database connections
- [ ] Should see: "Database connection established"
- [ ] No errors about PostgreSQL connection

---

### **Part 10: Set Up Monitoring (10 min)**

- [ ] Railway → Medusa Service → Metrics
- [ ] Verify CPU, Memory, Network metrics visible
- [ ] Check Deployments → View logs
- [ ] Logs should show no critical errors

---

## ✅ **Completion Checklist**

- [ ] ✅ Railway account created
- [ ] ✅ Railway project with 2 services (Medusa + Redis only)
- [ ] ✅ Supabase DATABASE_URL configured in Railway
- [ ] ✅ Redis connected from Railway
- [ ] ✅ Code deployed successfully
- [ ] ✅ Migrations applied to Supabase database
- [ ] ✅ Public domain generated
- [ ] ✅ Health endpoint working
- [ ] ✅ Admin panel accessible
- [ ] ✅ Supabase tables populated

---

## 🎯 **Your Final Architecture**

```
┌────────────────────────────────────────┐
│          VERCEL (Later)                │
│     Next.js Storefront                 │
└────────────┬───────────────────────────┘
             │
             ├─────────────────┐
             │                 │
             ▼                 ▼
┌────────────────────┐  ┌──────────────────┐
│      RAILWAY       │  │    SUPABASE      │
│  ┌──────────────┐  │  │  ┌────────────┐  │
│  │    Medusa    │──┼──┼─▶│ PostgreSQL │  │
│  │   Backend    │  │  │  │ (Database) │  │
│  └──────┬───────┘  │  │  └────────────┘  │
│         │          │  │  ┌────────────┐  │
│  ┌──────▼───────┐  │  │  │  Storage   │  │
│  │    Redis     │  │  │  │  (Assets)  │  │
│  └──────────────┘  │  │  └────────────┘  │
└────────────────────┘  └──────────────────┘
```

**Benefits:**
- ✅ Lower costs (one less database)
- ✅ Simpler management (one database to maintain)
- ✅ Better for multi-tenant (Supabase RLS)
- ✅ Unified backups
- ✅ Easier debugging

---

## 🚨 **Important Notes**

### ⚠️ **Connection Pooling**

Your Supabase `DATABASE_URL` already includes connection pooling:
```
?connection_limit=5&pool_timeout=20&connect_timeout=10
```

This is important because:
- Railway will have multiple instances connecting
- Supabase has connection limits on free tier
- Pooling prevents "too many connections" errors

### ⚠️ **Database Location**

Your Supabase database is in `aws-1-us-east-2` (Ohio).  
Your Railway app will likely be in `us-west-1` (Oregon) by default.

**Impact:** ~30-50ms additional latency for database queries.

**Optimization (Optional):**
- Deploy Railway to `us-east-1` (closest to database)
- In Railway Project Settings → Select Region → US East

### ⚠️ **Backup Strategy**

Since your database is on Supabase:
- ✅ Supabase handles automatic backups
- ✅ Point-in-time recovery available (paid plans)
- ⚠️ Railway does NOT backup your database
- 💡 Consider manual exports for critical data

---

## 💡 **Pro Tips**

1. **Monitor Supabase Database Usage**
   - Free tier: 500MB database size
   - Check usage in Supabase Dashboard
   - Clean up test data regularly

2. **Connection Limits**
   - Supabase free tier: ~10 concurrent connections
   - Your `connection_limit=5` is good for MVP
   - Increase for production if needed

3. **Redis Usage**
   - Use Redis for session storage
   - Cache frequently accessed products
   - Store job queues for async tasks
   - Reduces database load

4. **Environment Separation**
   - Consider separate Supabase projects for dev/prod
   - Or use separate schemas in same database
   - Keeps production data safe

---

## 🔧 **Troubleshooting**

### Issue: "Too many connections" error

**Cause:** Connection pool exhausted  
**Fix:**
```env
# Reduce connection limit
DATABASE_URL=...?connection_limit=3&pool_timeout=30
```

### Issue: Slow database queries

**Cause:** Geographic distance Railway ↔ Supabase  
**Fix:**
- Deploy Railway to US East region
- Add database indexes
- Use Redis caching

### Issue: Migrations timeout

**Cause:** Network latency  
**Fix:**
```env
# Increase timeout
DATABASE_URL=...&connect_timeout=30&pool_timeout=60
```

### Issue: Can't connect to Supabase

**Cause:** Connection pooler might be down  
**Fix:** Try direct connection:
```env
# Use direct connection (port 5432) instead of pooler (6543)
DATABASE_URL=postgresql://postgres...@aws-1-us-east-2.aws.supabase.com:5432/postgres
```

---

## 📊 **Cost Comparison**

### Option A: Railway PostgreSQL + Supabase
- Railway PostgreSQL: ~$1-2/month
- Railway Redis: ~$0.50-1/month
- Railway Medusa: ~$3-4/month
- Supabase: Free tier
- **Total: ~$4.50-7/month**

### Option B: Supabase Only (Your Setup) ✅
- Railway Redis: ~$0.50-1/month
- Railway Medusa: ~$3-4/month
- Supabase: Free tier
- **Total: ~$3.50-5/month**

**Savings: ~$1-2/month** + simpler architecture!

---

## ✅ **Success Criteria**

Day 5 is complete when:

1. ✅ `https://your-app.up.railway.app/health` returns success
2. ✅ Admin panel loads at `/app`
3. ✅ Railway shows 2 services: Medusa + Redis (NOT 3!)
4. ✅ Supabase shows Medusa tables in `back-end` project
5. ✅ No database connection errors in Railway logs

---

## 📞 **Need Help?**

- Check Railway logs first
- Verify Supabase connection string is correct
- Test connection locally before deploying
- Check Supabase Dashboard → Database → Connection Info

---

**Estimated Time:** 1.5-2 hours (faster than full guide!)  
**Difficulty:** Easy-Medium  
**Cost:** $3.50-5/month (cheaper than alternative!)

**Ready to deploy! 🚀**

