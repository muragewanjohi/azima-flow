-- Storage Policies for Azima.Store SaaS Platform
-- Run this script in your azima-store-saas project after creating the buckets

-- =============================================
-- TENANT-ASSETS BUCKET POLICIES
-- =============================================

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

-- =============================================
-- PUBLIC-ASSETS BUCKET POLICIES
-- =============================================

-- Anyone can view public assets
CREATE POLICY "Public assets are viewable by everyone" ON storage.objects
    FOR SELECT USING (bucket_id = 'public-assets');

-- Authenticated users can upload public assets
CREATE POLICY "Authenticated users can upload public assets" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'public-assets' AND
        auth.role() = 'authenticated'
    );

-- Authenticated users can update public assets
CREATE POLICY "Authenticated users can update public assets" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'public-assets' AND
        auth.role() = 'authenticated'
    );

-- Authenticated users can delete public assets
CREATE POLICY "Authenticated users can delete public assets" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'public-assets' AND
        auth.role() = 'authenticated'
    );

-- =============================================
-- BACKUPS BUCKET POLICIES
-- =============================================

-- Service role can manage backups
CREATE POLICY "Service role can manage backups" ON storage.objects
    FOR ALL USING (
        bucket_id = 'backups' AND
        auth.role() = 'service_role'
    );

-- =============================================
-- HELPER FUNCTIONS
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
    IF NOT EXISTS(
        SELECT 1 FROM tenant_users tu
        WHERE tu.user_id = user_id
        AND tu.tenant_id = tenant_id
    ) THEN
        RETURN FALSE;
    END IF;
    
    -- Check if file path is within tenant's folder
    IF NOT file_path LIKE 'tenant-' || tenant_id::text || '/%' THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
