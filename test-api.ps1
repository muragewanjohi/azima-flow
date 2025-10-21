# Test Tenant Provisioning API - PowerShell Version
# Usage: .\test-api.ps1

Write-Host "🧪 Testing Tenant Provisioning API" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Create Nairobi Electronics tenant
Write-Host "Test 1: Creating Nairobi Electronics tenant..." -ForegroundColor Yellow

$body = @{
    tenantName = "London Shop"
    slug = "london-shop"
    currencyCode = "gbp"
    countryCode = "gb"
    adminEmail = "admin@londonshop.co.uk"
    adminPassword = "secure123456"
    adminFirstName = "James"
    adminLastName = "Smith"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:9000/tenants" `
        -Method Post `
        -ContentType "application/json" `
        -Body $body

    Write-Host ""
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 10
    Write-Host ""
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host "Login details:" -ForegroundColor Yellow
    Write-Host "URL: http://localhost:9000/app"
    Write-Host "Email: admin@londonshop.co.uk"
    Write-Host "Password: secure123456"
} catch {
    Write-Host ""
    Write-Host "❌ ERROR!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure Medusa is running: npm run dev" -ForegroundColor Yellow
}

