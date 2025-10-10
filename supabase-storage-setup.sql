-- Supabase Storage Setup for Azima.Store
-- This script creates storage buckets and policies for tenant assets

-- =============================================
-- STORAGE BUCKETS CREATION
-- =============================================

-- Note: Storage buckets are typically created through Supabase Dashboard
-- or using the Supabase Management API. This script documents the setup.

-- 1. Go to Storage in Supabase Dashboard
-- 2. Create the following buckets:

-- Bucket for tenant assets (themes, images, etc.)
-- Name: tenant-assets
-- Public: false (private bucket)
-- File size limit: 50MB
-- Allowed MIME types: image/*, application/json, text/css, application/javascript

-- Bucket for public assets (logos, favicons, etc.)
-- Name: public-assets
-- Public: true (public bucket)
-- File size limit: 10MB
-- Allowed MIME types: image/*, application/json

-- Bucket for backups and exports
-- Name: backups
-- Public: false (private bucket)
-- File size limit: 100MB
-- Allowed MIME types: application/zip, application/json, text/csv

-- =============================================
-- STORAGE POLICIES
-- =============================================

-- Note: These policies would be applied in Supabase Dashboard > Storage > Policies

-- Policy for tenant-assets bucket
-- Users can upload files to their tenant's folder
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

-- Users can view files in their tenant's folder
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

-- Users can update files in their tenant's folder
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

-- Users can delete files in their tenant's folder
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

-- Policy for public-assets bucket
-- Anyone can view public assets
CREATE POLICY "Public assets are viewable by everyone" ON storage.objects
    FOR SELECT USING (bucket_id = 'public-assets');

-- Only authenticated users can upload public assets
CREATE POLICY "Authenticated users can upload public assets" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'public-assets' AND
        auth.role() = 'authenticated'
    );

-- Only authenticated users can update public assets
CREATE POLICY "Authenticated users can update public assets" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'public-assets' AND
        auth.role() = 'authenticated'
    );

-- Only authenticated users can delete public assets
CREATE POLICY "Authenticated users can delete public assets" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'public-assets' AND
        auth.role() = 'authenticated'
    );

-- Policy for backups bucket
-- Only service role can access backups
CREATE POLICY "Service role can manage backups" ON storage.objects
    FOR ALL USING (
        bucket_id = 'backups' AND
        auth.role() = 'service_role'
    );

-- =============================================
-- STORAGE HELPER FUNCTIONS
-- =============================================

-- Function to get tenant asset URL
CREATE OR REPLACE FUNCTION get_tenant_asset_url(
    tenant_id UUID,
    file_path TEXT
)
RETURNS TEXT AS $$
BEGIN
    RETURN storage.url('tenant-assets', 'tenant-' || tenant_id::text || '/' || file_path);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get public asset URL
CREATE OR REPLACE FUNCTION get_public_asset_url(file_path TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN storage.url('public-assets', file_path);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can access tenant asset
CREATE OR REPLACE FUNCTION can_access_tenant_asset(
    user_id UUID,
    tenant_id UUID,
    file_path TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if user has access to tenant
    IF NOT user_has_tenant_access(user_id, tenant_id) THEN
        RETURN FALSE;
    END IF;
    
    -- Check if file path is within tenant's folder
    IF NOT file_path LIKE 'tenant-' || tenant_id::text || '/%' THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- STORAGE FOLDER STRUCTURE
-- =============================================

/*
Recommended folder structure for tenant assets:

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
*/

-- =============================================
-- STORAGE USAGE TRACKING
-- =============================================

-- Function to track storage usage
CREATE OR REPLACE FUNCTION track_storage_usage()
RETURNS TRIGGER AS $$
DECLARE
    tenant_uuid UUID;
    file_size BIGINT;
    feature_key TEXT;
BEGIN
    -- Extract tenant ID from file path
    IF NEW.bucket_id = 'tenant-assets' THEN
        tenant_uuid := (regexp_split_to_array(NEW.name, '/'))[1]::UUID;
        tenant_uuid := replace(tenant_uuid::text, 'tenant-', '')::UUID;
        
        -- Get file size
        file_size := COALESCE(NEW.metadata->>'size', '0')::BIGINT;
        
        -- Track storage usage
        INSERT INTO usage_counters (tenant_id, feature_key, count, period_start, period_end)
        VALUES (
            tenant_uuid,
            'storage_bytes',
            file_size,
            date_trunc('month', NOW()),
            date_trunc('month', NOW()) + interval '1 month' - interval '1 day'
        )
        ON CONFLICT (tenant_id, feature_key, period_start)
        DO UPDATE SET count = usage_counters.count + file_size;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to track storage usage
CREATE TRIGGER track_storage_usage_trigger
    AFTER INSERT ON storage.objects
    FOR EACH ROW EXECUTE FUNCTION track_storage_usage();

-- =============================================
-- STORAGE CLEANUP FUNCTIONS
-- =============================================

-- Function to cleanup old tenant assets
CREATE OR REPLACE FUNCTION cleanup_tenant_assets(tenant_id UUID, days_old INTEGER DEFAULT 30)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER := 0;
BEGIN
    -- Delete old files from tenant's folder
    DELETE FROM storage.objects
    WHERE bucket_id = 'tenant-assets'
    AND name LIKE 'tenant-' || tenant_id::text || '/%'
    AND created_at < NOW() - (days_old || ' days')::INTERVAL;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- STORAGE SETUP NOTES
-- =============================================

/*
To complete the storage setup:

1. Create buckets in Supabase Dashboard:
   - tenant-assets (private)
   - public-assets (public)
   - backups (private)

2. Apply storage policies in Supabase Dashboard > Storage > Policies

3. Set up CDN configuration for public assets

4. Configure file size limits and MIME type restrictions

5. Set up automatic cleanup jobs for old files

6. Monitor storage usage and costs

7. Environment variables needed:
   - SUPABASE_URL
   - SUPABASE_ANON_KEY
   - SUPABASE_SERVICE_ROLE_KEY

8. Client-side setup:
   - Install @supabase/storage-js
   - Set up file upload components
   - Implement progress tracking
   - Handle file validation
*/
