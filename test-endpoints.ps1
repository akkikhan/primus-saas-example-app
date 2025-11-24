# Test script for PrimusSaaS packages evaluation
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PrimusSaaS Packages - Fresh Test" -ForegroundColor Cyan
Write-Host "Identity.Validator: 1.3.0" -ForegroundColor Cyan
Write-Host "Logging: 1.2.1" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: Public endpoint (no auth required)
Write-Host "TEST 1: Public Endpoint (No Auth)" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:5002/api/Secure/public" -Method GET
    Write-Host "✓ SUCCESS" -ForegroundColor Green
    $response | ConvertTo-Json
} catch {
    Write-Host "✗ FAILED: $_" -ForegroundColor Red
}

Write-Host "`n"

# Test 2: Protected endpoint without token (should fail)
Write-Host "TEST 2: Protected Endpoint (No Token - Should Fail)" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:5002/api/Secure/protected" -Method GET -ErrorAction Stop
    Write-Host "✗ UNEXPECTED SUCCESS - Should have returned 401" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "✓ CORRECT - 401 Unauthorized as expected" -ForegroundColor Green
    } else {
        Write-Host "✗ FAILED WITH WRONG STATUS: $_" -ForegroundColor Red
    }
}

Write-Host "`n"

# Test 3: Get a local auth token
Write-Host "TEST 3: Get LocalAuth Token" -ForegroundColor Yellow
try {
    $tokenResponse = Invoke-RestMethod -Uri "http://localhost:5002/api/Token/local" -Method POST -ContentType "application/json" -Body '{"email":"test@example.com","password":"Password123!"}'
    Write-Host "✓ SUCCESS - Token retrieved" -ForegroundColor Green
    $token = $tokenResponse.token
    Write-Host "Token (first 50 chars): $($token.Substring(0, [Math]::Min(50, $token.Length)))..."
} catch {
    Write-Host "✗ FAILED: $_" -ForegroundColor Red
    $token = $null
}

Write-Host "`n"

# Test 4: Access protected endpoint with token
if ($token) {
    Write-Host "TEST 4: Protected Endpoint WITH Token" -ForegroundColor Yellow
    try {
        $headers = @{
            "Authorization" = "Bearer $token"
        }
        $response = Invoke-RestMethod -Uri "http://localhost:5002/api/Secure/protected" -Method GET -Headers $headers
        Write-Host "✓ SUCCESS" -ForegroundColor Green
        $response | ConvertTo-Json -Depth 5
    } catch {
        Write-Host "✗ FAILED: $_" -ForegroundColor Red
    }
}

Write-Host "`n"

# Test 5: Get user details
if ($token) {
    Write-Host "TEST 5: Get User Details" -ForegroundColor Yellow
    try {
        $headers = @{
            "Authorization" = "Bearer $token"
        }
        $response = Invoke-RestMethod -Uri "http://localhost:5002/api/Secure/user-details" -Method GET -Headers $headers
        Write-Host "✓ SUCCESS" -ForegroundColor Green
        $response | ConvertTo-Json -Depth 5
    } catch {
        Write-Host "✗ FAILED: $_" -ForegroundColor Red
        Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Suite Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
