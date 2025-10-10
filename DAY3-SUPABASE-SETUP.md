# Day 3: Supabase Setup Completion Guide

## Overview
Complete the remaining Day 3 tasks for Supabase setup:
- ✅ Create Supabase project (COMPLETED)
- ✅ Set up SaaS database schema (COMPLETED)
- 🔄 Configure RLS policies (IN PROGRESS)
- 🔄 Set up authentication (IN PROGRESS)
- 🔄 Create storage buckets (IN PROGRESS)

## Step 1: Run Database Schema

1. **Open Supabase SQL Editor**
   - Go to your Supabase project dashboard
   - Navigate to SQL Editor

2. **Execute Schema Script**
   - Copy and paste the contents of `supabase-schema.sql`
   - Run the script to create all tables and indexes

3. **Verify Tables Created**
   - Check the Table Editor to confirm all tables are created
   - Verify indexes are properly set up

## Step 2: Configure RLS Policies

1. **Execute RLS Script**
   - Copy and paste the contents of `supabase-rls-policies.sql`
   - Run the script to set up Row Level Security

2. **Verify RLS is Enabled**
   - Check that RLS is enabled on all tables
   - Verify policies are created and active

## Step 3: Set Up Authentication

1. **Execute Auth Script**
   - Copy and paste the contents of `supabase-auth-setup.sql`
   - Run the script to set up authentication functions

2. **Configure Authentication Settings**
   - Go to Authentication > Settings in Supabase Dashboard
   - Enable "Enable email confirmations"
   - Set "Site URL" to `http://localhost:3000` (for development)
   - Add redirect URLs:
     - `http://localhost:3000/auth/callback`
     - `http://localhost:7001/auth/callback` (for admin)

3. **Configure Email Templates** (Optional)
   - Customize email templates in Authentication > Templates
   - Set up custom SMTP if needed

## Step 4: Create Storage Buckets

1. **Create Storage Buckets**
   - Go to Storage in Supabase Dashboard
   - Create the following buckets:
     - `tenant-assets` (Private)
     - `public-assets` (Public)
     - `backups` (Private)

2. **Configure Bucket Settings**
   - Set file size limits:
     - tenant-assets: 50MB
     - public-assets: 10MB
     - backups: 100MB
   - Set allowed MIME types as needed

3. **Apply Storage Policies**
   - Go to Storage > Policies
   - Create policies for each bucket based on the `supabase-storage-setup.sql` script

## Step 5: Test the Setup

1. **Test Database Connection**
   ```bash
   # Test connection from your local environment
   psql "your-database-url"
   ```

2. **Test Authentication**
   - Try creating a test user
   - Verify triggers are working
   - Check that user data is properly inserted

3. **Test Storage**
   - Try uploading a test file
   - Verify policies are working
   - Check file access permissions

## Step 6: Environment Variables

Create a `.env` file in your project root with:

```env
# Supabase Configuration
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Database
DATABASE_URL=your-database-url

# Redis
REDIS_URL=redis://localhost:6379

# CORS
STORE_CORS=http://localhost:8000,http://localhost:3000
ADMIN_CORS=http://localhost:7001,http://localhost:7000
AUTH_CORS=http://localhost:7001,http://localhost:7000

# JWT Secrets
JWT_SECRET=supersecret
COOKIE_SECRET=supersecret
```

## Step 7: Verify Day 3 Completion

Check that all Day 3 tasks are completed:

- [x] Create Supabase project
- [x] Set up SaaS database schema
- [x] Configure RLS policies
- [x] Set up authentication
- [x] Create storage buckets

## Next Steps

Once Day 3 is complete, you can move on to Day 4:
- Initialize Medusa project
- Configure database connection
- Set up Redis for caching/queues
- Configure basic plugins
- Test local Medusa instance

## Troubleshooting

### Common Issues

1. **RLS Policies Not Working**
   - Check that RLS is enabled on tables
   - Verify policy syntax
   - Test with different user roles

2. **Authentication Issues**
   - Check email confirmation settings
   - Verify redirect URLs
   - Check trigger functions

3. **Storage Access Issues**
   - Verify bucket policies
   - Check file path structure
   - Test with different user contexts

### Getting Help

- Check Supabase documentation
- Review error logs in Supabase Dashboard
- Test queries in SQL Editor
- Verify environment variables

## Security Notes

- Never commit `.env` files to version control
- Use strong JWT secrets in production
- Regularly rotate service role keys
- Monitor RLS policy effectiveness
- Set up proper backup strategies
