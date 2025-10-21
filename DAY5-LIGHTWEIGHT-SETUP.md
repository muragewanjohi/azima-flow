# Day 5: Lightweight Railway Setup (1-2 Hours)

## 🎯 **Goal: Validate Deployment Works, Then Move On**

This is a **minimal setup** to complete Week 0 foundation. You'll build features locally and use Railway when needed.

---

## ⏱️ **Time Estimate: 1-2 hours total**

---

## 📋 **Quick Checklist**

### **Part 1: Railway Account** (10 min)
- [ ] Go to [railway.app](https://railway.app)
- [ ] Sign up with GitHub
- [ ] Verify email

### **Part 2: Create Project** (15 min)
- [ ] Click "+ New Project"
- [ ] Select "Deploy from GitHub repo"
- [ ] Choose `azima-flow` repository
- [ ] Add **Redis** service only (NOT PostgreSQL)
- [ ] Set Root Directory to `store-flow`

### **Part 3: Environment Variables** (20 min)
Copy your existing `.env` values to Railway:

```env
NODE_ENV=production
DATABASE_URL=postgresql://postgres.aaadfbrxcggeltebobpm:SiF3iS1xDl9hnTBb@aws-1-us-east-2.pooler.supabase.com:6543/postgres?connection_limit=5&pool_timeout=20&connect_timeout=10
REDIS_URL=${{Redis.REDIS_URL}}
STORE_CORS=http://localhost:8000
ADMIN_CORS=http://localhost:7001
AUTH_CORS=http://localhost:7001
JWT_SECRET=[your-existing-secret]
COOKIE_SECRET=[your-existing-secret]
```

- [ ] Copy DATABASE_URL from local `.env`
- [ ] Copy JWT_SECRET and COOKIE_SECRET
- [ ] Add other variables

### **Part 4: Deploy & Verify** (30 min)
- [ ] Push to GitHub (triggers auto-deploy)
- [ ] Wait for build to complete
- [ ] Generate public domain
- [ ] Test: `curl https://your-app.up.railway.app/health`
- [ ] If it works, you're done! ✅

### **Part 5: Document & Move On** (5 min)
- [ ] Save Railway URL in notes
- [ ] Mark Day 5 complete in ROADMAP_TRACKER.md
- [ ] **Stop thinking about Railway!**

---

## 🎯 **Success Criteria**

Day 5 is complete when:
- ✅ Railway project exists
- ✅ One successful deployment
- ✅ Health endpoint returns 200
- ✅ Railway URL documented

**Don't worry about:**
- ❌ Perfect configuration
- ❌ Monitoring setup
- ❌ Detailed testing
- ❌ Multiple deployments

---

## 🚀 **After Day 5**

### **Week 1-4: Focus on Local Development**

```bash
# Your daily workflow
cd store-flow
npm run dev          # Develop locally

# When you push to GitHub
git push origin main # Railway auto-deploys (ignore it)
```

### **When to Use Railway:**
- 🧪 Need to test production environment
- 🌐 Demo to someone
- 🐛 Debug production-only issue
- 📱 Test on mobile device

### **When to IGNORE Railway:**
- 🔧 Daily feature development
- 🧪 Unit/integration testing
- 🚀 Quick iterations
- 📝 Learning/experimenting

---

## 💡 **Key Principle**

**"Deploy infrastructure early, but develop locally"**

Railway is your **safety net** - it's there when you need it, but you won't need it often during development.

---

## ✅ **Complete This Today, Then Move to Day 6**

**Time box this:** 2 hours maximum

If you hit issues:
- Skip it for now
- Focus on Days 6-10 (local development)
- Come back to Railway later

**The goal is progress, not perfection!**

---

**Ready? Let's do a quick Railway setup and move on!** 🚀

