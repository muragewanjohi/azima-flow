# Storage Bucket Setup Guide for Azima.Store

## Overview
This guide will help you set up the necessary storage buckets in your Supabase `azima-store-saas` project for the multi-tenant SaaS platform.

## Step 1: Navigate to Storage

1. **Go to your Supabase Dashboard**
2. **Select the `azima-store-saas` project** (not `back-end`)
3. **Click on "Storage"** in the left sidebar
4. **Click "New bucket"** to create your first bucket

## Step 2: Create Required Buckets

### Bucket 1: `tenant-assets` (Private)
- **Name**: `tenant-assets`
- **Public**: ❌ **No** (Private bucket)
- **File size limit**: 50MB
- **Allowed MIME types**: 
  - `image/*` (for product images, logos, etc.)
  - `application/json` (for theme configurations)
  - `text/css` (for custom CSS)
  - `application/javascript` (for custom JS)
  - `application/zip` (for theme packages)

### Bucket 2: `public-assets` (Public)
- **Name**: `public-assets`
- **Public**: ✅ **Yes** (Public bucket)
- **File size limit**: 10MB
- **Allowed MIME types**:
  - `image/*` (for public logos, favicons, etc.)
  - `application/json` (for public configurations)

### Bucket 3: `backups` (Private)
- **Name**: `backups`
- **Public**: ❌ **No** (Private bucket)
- **File size limit**: 100MB
- **Allowed MIME types**:
  - `application/zip` (for database backups)
  - `application/json` (for data exports)
  - `text/csv` (for CSV exports)

## Step 3: Configure Bucket Settings

### For `tenant-assets`:
1. **Click on the bucket name** after creation
2. **Go to "Settings"** tab
3. **Set file size limit**: 50MB
4. **Add allowed MIME types**: `image/*,application/json,text/css,application/javascript,application/zip`
5. **Save settings**

### For `public-assets`:
1. **Click on the bucket name** after creation
2. **Go to "Settings" tab**
3. **Set file size limit**: 10MB
4. **Add allowed MIME types**: `image/*,application/json`
5. **Save settings**

### For `backups`:
1. **Click on the bucket name** after creation
2. **Go to "Settings" tab**
3. **Set file size limit**: 100MB
4. **Add allowed MIME types**: `application/zip,application/json,text/csv`
5. **Save settings**

## Step 4: Set Up Storage Policies

### Navigate to Policies
1. **Go to "Storage"** in your Supabase dashboard
2. **Click on "Policies"** tab
3. **You should see your three buckets listed**

### Create Policies for `tenant-assets`

#### Policy 1: Users can upload to their tenant folder
```sql
CREATE POLICY "Users can upload to their tenant assets" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'tenant-assets' AND
        (storage.foldername(name))[1] = 'tenant-' || (
            SELECT t.id::text
            FROM tenants t
            JOIN tenant_users tu ON t.id = tu.tenant_id
            WHERE tu.user_id = auth.uid()
            LIMIT 1
        )
    );
```

#### Policy 2: Users can view files in their tenant folder
```sql
CREATE POLICY "Users can view their tenant assets" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'tenant-assets' AND
        (storage.foldername(name))[1] = 'tenant-' || (
            SELECT t.id::text
            FROM tenants t
            JOIN tenant_users tu ON t.id = tu.tenant_id
            WHERE tu.user_id = auth.uid()
            LIMIT 1
        )
    );
```

#### Policy 3: Users can update files in their tenant folder
```sql
CREATE POLICY "Users can update their tenant assets" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'tenant-assets' AND
        (storage.foldername(name))[1] = 'tenant-' || (
            SELECT t.id::text
            FROM tenants t
            JOIN tenant_users tu ON t.id = tu.tenant_id
            WHERE tu.user_id = auth.uid()
            LIMIT 1
        )
    );
```

#### Policy 4: Users can delete files in their tenant folder
```sql
CREATE POLICY "Users can delete their tenant assets" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'tenant-assets' AND
        (storage.foldername(name))[1] = 'tenant-' || (
            SELECT t.id::text
            FROM tenants t
            JOIN tenant_users tu ON t.id = tu.tenant_id
            WHERE tu.user_id = auth.uid()
            LIMIT 1
        )
    );
```

### Create Policies for `public-assets`

#### Policy 1: Anyone can view public assets
```sql
CREATE POLICY "Public assets are viewable by everyone" ON storage.objects
    FOR SELECT USING (bucket_id = 'public-assets');
```

#### Policy 2: Authenticated users can upload public assets
```sql
CREATE POLICY "Authenticated users can upload public assets" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'public-assets' AND
        auth.role() = 'authenticated'
    );
```

#### Policy 3: Authenticated users can update public assets
```sql
CREATE POLICY "Authenticated users can update public assets" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'public-assets' AND
        auth.role() = 'authenticated'
    );
```

#### Policy 4: Authenticated users can delete public assets
```sql
CREATE POLICY "Authenticated users can delete public assets" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'public-assets' AND
        auth.role() = 'authenticated'
    );
```

### Create Policies for `backups`

#### Policy 1: Service role can manage backups
```sql
CREATE POLICY "Service role can manage backups" ON storage.objects
    FOR ALL USING (
        bucket_id = 'backups' AND
        auth.role() = 'service_role'
    );
```

## Step 5: Test Storage Setup

### Test 1: Create a Test File
1. **Go to Storage** in your Supabase dashboard
2. **Click on `tenant-assets` bucket**
3. **Try uploading a test file** (you might need to create a test tenant first)
4. **Verify the file appears in the bucket**

### Test 2: Check Permissions
1. **Try accessing files from different contexts**
2. **Verify tenant isolation is working**
3. **Check that public assets are accessible**

## Step 6: Folder Structure

### Recommended folder structure:

```
tenant-assets/
├── tenant-{tenant-id}/
│   ├── themes/
│   │   ├── current/
│   │   │   ├── sections/
│   │   │   ├── blocks/
│   │   │   └── assets/
│   │   └── drafts/
│   │       ├── sections/
│   │       ├── blocks/
│   │       └── assets/
│   ├── uploads/
│   │   ├── products/
│   │   ├── categories/
│   │   └── general/
│   └── exports/
│       ├── orders/
│       ├── products/
│       └── customers/

public-assets/
├── logos/
├── favicons/
├── templates/
└── shared/

backups/
├── database/
├── assets/
└── exports/
```

## Step 7: Environment Variables

Add these to your environment variables:

```env
# Supabase Storage
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Storage Bucket Names
TENANT_ASSETS_BUCKET=tenant-assets
PUBLIC_ASSETS_BUCKET=public-assets
BACKUPS_BUCKET=backups
```

## Troubleshooting

### Common Issues:

1. **"Policy creation failed"**: Make sure you're in the correct project (`azima-store-saas`)
2. **"File upload failed"**: Check MIME type restrictions and file size limits
3. **"Access denied"**: Verify RLS policies are correctly applied
4. **"Bucket not found"**: Ensure bucket names match exactly

### Getting Help:

- Check Supabase Storage documentation
- Verify bucket settings in the dashboard
- Test with simple file uploads first
- Check error logs in Supabase dashboard

## Next Steps

Once storage is set up:
1. **Test file uploads** from your application
2. **Verify tenant isolation** is working
3. **Set up CDN** for public assets (optional)
4. **Configure automatic cleanup** for old files
5. **Monitor storage usage** and costs
