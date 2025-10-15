# Railway Deployment Fix - Monorepo Configuration

## 🔴 **Problem**

**Error:** `Error creating build plan with Railpack`  
**Cause:** Railway is trying to build from the repository root, but your code has two separate projects (monorepo structure):
- `store-flow/` (Medusa backend) 
- `store-flow-storefront/` (Next.js frontend)

Railway gets confused and doesn't know which one to build.

---

## ✅ **Solution: Configure Root Directory**

You need to tell Railway to **only build from the `store-flow` directory**.

### **Method 1: Via Railway Dashboard (Recommended)**

#### **Step-by-Step Instructions:**

1. **Open Railway Dashboard**
   - Go to [railway.app](https://railway.app)
   - Click on your project: `azima-flow`

2. **Select the Service**
   - You should see your GitHub service (the one that failed)
   - Click on it to open service details

3. **Go to Settings**
   - In the left sidebar, click **"Settings"**

4. **Find "Source" Section**
   - Scroll down to find the "Source" section
   - Look for **"Root Directory"** field

5. **Set Root Directory**
   - In the "Root Directory" field, enter: `store-flow`
   - Click outside the field to auto-save
   - OR click the "Update" button if there is one

6. **Verify Configuration**
   - You should now see: `Root Directory: store-flow`
   - This tells Railway to build ONLY from the `store-flow` folder

7. **Trigger New Deployment**
   - Go to the "Deployments" tab
   - Click "Deploy" → "Redeploy" 
   - OR push a new commit to trigger automatic deployment

---

### **Method 2: Create Separate Railway Service**

If setting Root Directory doesn't work, create a new service:

1. **Delete Current Service** (if it exists)
   - Go to the failed service
   - Settings → Danger → Remove Service

2. **Add New Service**
   - Click "+ New" in your Railway project
   - Select "GitHub Repo"
   - Choose your `azima-flow` repository
   - **Important:** During setup, set "Root Directory" to `store-flow`

3. **Configure Variables**
   - Add all environment variables (see DAY5-SUPABASE-VERSION.md)
   - Don't forget: DATABASE_URL, REDIS_URL, secrets, etc.

---

### **Method 3: Use nixpacks.toml (Alternative)**

Create a `nixpacks.toml` file in your repository root:

**File:** `nixpacks.toml` (in repository root, not in store-flow)

```toml
[phases.setup]
nixPkgs = ['nodejs_20']

[phases.install]
cmds = ['cd store-flow && npm ci']

[phases.build]
cmds = ['cd store-flow && npm run build']

[start]
cmd = 'cd store-flow && npm run start'
```

Then commit and push:
```bash
git add nixpacks.toml
git commit -m "Add nixpacks configuration for monorepo"
git push origin main
```

---

## 🔍 **Verification Steps**

After setting Root Directory, verify in Railway:

### **Check Settings:**
1. Go to Service → Settings
2. Verify "Root Directory" shows: `store-flow`
3. Verify "Build Command" is: `npm install && npm run build`
4. Verify "Start Command" is: `npm run start`

### **Check Build Logs:**
1. Go to Deployments → Latest Deployment → View Logs
2. You should see:
   ```
   Setting working directory to: /app/store-flow
   Running: npm install
   ```
3. Should NOT see any errors about "creating build plan"

### **Success Indicators:**
- ✅ Build completes without errors
- ✅ You see "npm install" running in logs
- ✅ You see "npm run build" completing
- ✅ Deployment shows "SUCCESS" status

---

## 🚨 **Common Issues & Fixes**

### **Issue 1: Root Directory setting not saving**

**Symptoms:** Field resets after you enter it  
**Fix:**
- Try refreshing the page and setting it again
- Make sure you're clicking outside the field or pressing Enter
- Try a different browser

### **Issue 2: Still building from root**

**Symptoms:** Build logs show `/app` instead of `/app/store-flow`  
**Fix:**
- Delete the service and create a new one
- Use Method 3 (nixpacks.toml) instead
- Contact Railway support

### **Issue 3: "package.json not found"**

**Symptoms:** Error says can't find package.json  
**Fix:**
- Verify Root Directory is set to exactly: `store-flow` (no slashes)
- Check that `store-flow/package.json` exists in your repository
- Try: `git push` to ensure latest code is on GitHub

### **Issue 4: Environment variables not loading**

**Symptoms:** Build succeeds but app crashes with missing variables  
**Fix:**
- Go to Variables tab
- Re-add all required variables
- Especially: DATABASE_URL, REDIS_URL, JWT_SECRET, COOKIE_SECRET
- Redeploy after adding variables

---

## 📋 **Quick Checklist**

Before deploying, verify:

- [ ] `store-flow/package.json` exists in repository
- [ ] `store-flow/railway.json` exists in repository
- [ ] Root Directory is set to `store-flow` in Railway settings
- [ ] All environment variables are configured
- [ ] Redis service is running
- [ ] Latest code is pushed to GitHub

---

## 🎯 **Expected Railway Configuration**

### **Service Settings:**
```
Service Name: azima-flow (or medusa-backend)
Source: GitHub - muragewanjohi/azima-flow
Branch: main
Root Directory: store-flow
Builder: NIXPACKS
```

### **Build Settings:**
```
Build Command: npm install && npm run build (auto-detected)
Start Command: npm run start (auto-detected)
```

### **Environment Variables:**
```
NODE_ENV=production
DATABASE_URL=postgresql://postgres...@supabase.com:6543/postgres
REDIS_URL=${{Redis.REDIS_URL}}
STORE_CORS=http://localhost:8000
ADMIN_CORS=http://localhost:7001
AUTH_CORS=http://localhost:7001
JWT_SECRET=[your-secret]
COOKIE_SECRET=[your-secret]
PORT=9000
```

---

## 🔄 **Recommended Workflow**

### **For Monorepo Setup:**

1. **Deploy Backend (Medusa) to Railway:**
   - Root Directory: `store-flow`
   - Use the configuration above

2. **Deploy Frontend (Storefront) to Vercel** (later):
   - Root Directory: `store-flow-storefront`
   - Connect to Railway backend via env variables

This separation makes deployments cleaner and follows best practices.

---

## 💡 **Why This Happens**

Railway's build system (Nixpacks/Railpack) automatically detects your project type by:
1. Looking for `package.json` in the root
2. Looking for framework-specific files
3. Determining the build strategy

When you have a monorepo with multiple `package.json` files:
- It finds both `store-flow/package.json` and `store-flow-storefront/package.json`
- It gets confused about which one to build
- It fails with "Error creating build plan"

**Solution:** Tell it explicitly which directory to build from using Root Directory setting.

---

## 📚 **Additional Resources**

- [Railway Monorepo Documentation](https://docs.railway.app/deploy/monorepo)
- [Nixpacks Documentation](https://nixpacks.com/docs)
- [Railway Root Directory Guide](https://docs.railway.app/deploy/deployments#root-directory)

---

## ✅ **After Fixing**

Once you set the Root Directory and redeploy successfully:

1. **Verify Health Endpoint:**
   ```bash
   curl https://your-app.up.railway.app/health
   ```

2. **Check Admin Panel:**
   ```
   https://your-app.up.railway.app/app
   ```

3. **Update ROADMAP_TRACKER.md:**
   - Mark Day 5 as complete
   - Add notes about monorepo configuration

---

**Status:** Ready to fix! Follow Method 1 above. 🚀

