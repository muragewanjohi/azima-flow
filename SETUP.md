# **Azima.Store - Development Setup Guide**

This guide will help you set up your local development environment for the Azima.Store multi-tenant e-commerce SaaS platform.

---

## **📋 Prerequisites**

Before you begin, ensure you have the following installed:

- **Node.js** (v20 or higher) - [Download here](https://nodejs.org/)
- **npm** (comes with Node.js)
- **Git** - [Download here](https://git-scm.com/)
- **VS Code** (recommended) - [Download here](https://code.visualstudio.com/)

### **Verify Installation**
```bash
node --version    # Should show v20+
npm --version     # Should show v10+
git --version     # Should show v2.30+
```

---

## **🚀 Quick Start**

### **1. Clone the Repository**
```bash
git clone https://github.com/muragewanjohi/azima-flow.git
cd azima-flow
```

### **2. Install Dependencies**

#### **Backend (Medusa)**
```bash
cd store-flow
npm install
```

#### **Frontend (Next.js Storefront)**
```bash
cd ../store-flow-storefront
npm install
```

### **3. Set Up Environment Variables**

#### **Backend Environment**
```bash
cd ../store-flow
cp .env.example .env
```

Edit `.env` with your configuration:
```env
# Database - Replace with your Supabase connection string
DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres

# Redis (optional for development)
REDIS_URL=redis://localhost:6379

# CORS
STORE_CORS=http://localhost:8000,http://localhost:3000
ADMIN_CORS=http://localhost:7001,http://localhost:7000
AUTH_CORS=http://localhost:7001,http://localhost:7000

# JWT Secrets (change these in production)
JWT_SECRET=supersecret
COOKIE_SECRET=supersecret

# Medusa Admin
MEDUSA_ADMIN_ONBOARDING_TYPE=default
MEDUSA_ADMIN_ONBOARDING_NEXTJS_DIRECTORY=../store-flow-storefront
```

#### **Frontend Environment**
```bash
cd ../store-flow-storefront
cp .env.example .env.local
```

Edit `.env.local` with your configuration:
```env
# Medusa Backend URL
NEXT_PUBLIC_MEDUSA_BACKEND_URL=http://localhost:9000

# Medusa Admin URL
NEXT_PUBLIC_MEDUSA_ADMIN_URL=http://localhost:7001

# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=your-supabase-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
```

### **4. Run Database Migrations**
```bash
cd ../store-flow
npm run db:migrate
```

### **5. Start Development Servers**

#### **Terminal 1: Backend (Medusa)**
```bash
cd store-flow
npm run dev
```
Backend will be available at: http://localhost:9000

#### **Terminal 2: Frontend (Next.js)**
```bash
cd store-flow-storefront
npm run dev
```
Frontend will be available at: http://localhost:8000

#### **Terminal 3: Admin (Medusa Admin)**
```bash
cd store-flow
npm run dev:admin
```
Admin will be available at: http://localhost:7001

---

## **🏗️ Project Structure**

```
azima-flow/
├── README.md                 # Project overview and documentation
├── ROADMAP_TRACKER.md        # Development roadmap and progress tracking
├── SETUP.md                  # This file - setup instructions
├── store-flow/               # Medusa backend
│   ├── src/                  # Source code
│   ├── medusa-config.ts      # Medusa configuration
│   ├── package.json          # Backend dependencies
│   └── .env                  # Backend environment variables
├── store-flow-storefront/    # Next.js storefront
│   ├── src/                  # Source code
│   ├── next.config.js        # Next.js configuration
│   ├── package.json          # Frontend dependencies
│   └── .env.local            # Frontend environment variables
└── .github/                  # GitHub configuration
    ├── ISSUE_TEMPLATE/       # Issue templates
    └── workflows/            # GitHub Actions (future)
```

---

## **🔧 Development Workflow**

### **Branch Protection Rules**
This repository uses branch protection rules. Always work on feature branches:

```bash
# Create a new feature branch
git checkout -b feature/your-feature-name

# Make changes and commit
git add .
git commit -m "Your commit message"

# Push the branch
git push origin feature/your-feature-name

# Create a Pull Request on GitHub
# Merge the PR after review
```

### **Available Scripts**

#### **Backend (store-flow/)**
```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run start        # Start production server
npm run db:migrate   # Run database migrations
npm run seed         # Seed database with sample data
npm run test:unit    # Run unit tests
```

#### **Frontend (store-flow-storefront/)**
```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run start        # Start production server
npm run lint         # Run ESLint
npm run analyze      # Analyze bundle size
```

---

## **🌐 Environment URLs**

| Service | URL | Description |
|---------|-----|-------------|
| **Storefront** | http://localhost:8000 | Next.js storefront |
| **Backend API** | http://localhost:9000 | Medusa backend API |
| **Admin Panel** | http://localhost:7001 | Medusa admin interface |
| **Supabase** | https://supabase.com | Database and storage |

---

## **🗄️ Database Setup**

### **Supabase Configuration**

1. **Create Supabase Project**
   - Go to [supabase.com](https://supabase.com)
   - Create a new project
   - Note down your project URL and API keys

2. **Get Database Connection String**
   - Go to Settings → Database
   - Copy the connection string
   - Update `DATABASE_URL` in your `.env` file

3. **Enable Extensions**
   - Go to Database → Extensions
   - Enable `pgcrypto` extension (required for Medusa)

### **Run Migrations**
```bash
cd store-flow
npm run db:migrate
```

---

## **🔐 Environment Variables Reference**

### **Backend (.env)**
| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | Supabase PostgreSQL connection string | `postgresql://postgres:password@db.ref.supabase.co:5432/postgres` |
| `REDIS_URL` | Redis connection string (optional) | `redis://localhost:6379` |
| `STORE_CORS` | CORS origins for storefront | `http://localhost:8000,http://localhost:3000` |
| `ADMIN_CORS` | CORS origins for admin | `http://localhost:7001,http://localhost:7000` |
| `JWT_SECRET` | JWT signing secret | `supersecret` |
| `COOKIE_SECRET` | Cookie signing secret | `supersecret` |

### **Frontend (.env.local)**
| Variable | Description | Example |
|----------|-------------|---------|
| `NEXT_PUBLIC_MEDUSA_BACKEND_URL` | Medusa backend URL | `http://localhost:9000` |
| `NEXT_PUBLIC_MEDUSA_ADMIN_URL` | Medusa admin URL | `http://localhost:7001` |
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase project URL | `https://ref.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anonymous key | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` |

---

## **🚨 Troubleshooting**

### **Common Issues**

#### **1. Database Connection Error**
```
Error: connect ECONNREFUSED
```
**Solution:**
- Check your `DATABASE_URL` in `.env`
- Ensure Supabase project is active
- Verify network connectivity

#### **2. Port Already in Use**
```
Error: listen EADDRINUSE :::9000
```
**Solution:**
- Kill the process using the port: `npx kill-port 9000`
- Or change the port in your configuration

#### **3. Migration Errors**
```
Error: function gen_random_bytes(integer) does not exist
```
**Solution:**
- Enable `pgcrypto` extension in Supabase
- Go to Database → Extensions → Enable pgcrypto

#### **4. CORS Errors**
```
Access to fetch at 'http://localhost:9000' from origin 'http://localhost:8000' has been blocked by CORS policy
```
**Solution:**
- Check `STORE_CORS` and `ADMIN_CORS` in your `.env`
- Ensure URLs match exactly

### **Reset Everything**
If you need to start fresh:

```bash
# Stop all servers (Ctrl+C)

# Reset database (if needed)
cd store-flow
npm run db:migrate

# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

cd ../store-flow-storefront
rm -rf node_modules package-lock.json
npm install

# Start servers again
cd ../store-flow
npm run dev
```

---

## **📚 Additional Resources**

- **Medusa Documentation**: [docs.medusajs.com](https://docs.medusajs.com/)
- **Next.js Documentation**: [nextjs.org/docs](https://nextjs.org/docs)
- **Supabase Documentation**: [supabase.com/docs](https://supabase.com/docs)
- **Project Roadmap**: [ROADMAP_TRACKER.md](./ROADMAP_TRACKER.md)

---

## **🤝 Getting Help**

If you encounter issues:

1. **Check this guide** first
2. **Search existing issues** on GitHub
3. **Create a new issue** using the bug report template
4. **Check the logs** for error messages

---

## **🎯 Next Steps**

After completing the setup:

1. **Read the project roadmap**: [ROADMAP_TRACKER.md](./ROADMAP_TRACKER.md)
2. **Start with Sprint 0**: Foundation & Setup
3. **Follow the daily tasks** in the roadmap tracker
4. **Join the development journey**! 🚀

---

**Happy coding!** 🎉

*Last updated: [Current Date]*
*Version: 1.0.0*
