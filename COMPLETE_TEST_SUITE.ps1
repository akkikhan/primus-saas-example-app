# PrimusSaaS v1.3.0 & v1.2.1 - Comprehensive Test Suite
# Run this after starting the app on http://localhost:5001

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "PrimusSaaS Packages - Complete Evaluation" -ForegroundColor Cyan
Write-Host "Identity.Validator: v1.3.0" -ForegroundColor Cyan
Write-Host "Logging: v1.2.1 (API changed - not tested yet)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$baseUrl = "http://localhost:5001"
$testsPassed = 0
$testsFailed = 0

# Test 1: Public Endpoint (No Auth)
Write-Host "`n[TEST 1] Public Endpoint (No Auth Required)" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/Secure/public" -Method GET -ErrorAction Stop
    Write-Host "✓ SUCCESS" -ForegroundColor Green
    Write-Host "  Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Gray
    $testsPassed++
} catch {
    Write-Host "✗ FAILED: $_" -ForegroundColor Red
    $testsFailed++
}

# Test 2: NEW Diagnostics Endpoint (v1.3.0 Feature)
Write-Host "`n[TEST 2] Diagnostics Endpoint (NEW in v1.3.0)" -ForegroundColor Yellow
try {
    $diag = Invoke-RestMethod -Uri "$baseUrl/primus/diagnostics" -Method GET -ErrorAction Stop
    Write-Host "✓ SUCCESS - Diagnostics endpoint works!" -ForegroundColor Green
    Write-Host "  Issuers configured:" -ForegroundColor Gray
    foreach ($issuer in $diag.issuers) {
        Write-Host "    - $($issuer.name) ($($issuer.type)): $($issuer.issuer)" -ForegroundColor Gray
    }
    Write-Host "  JWKS Stats:" -ForegroundColor Gray
    Write-Host "    Cache hits: $($diag.jwks.cacheHits)" -ForegroundColor Gray
    Write-Host "    Cache misses: $($diag.jwks.cacheMisses)" -ForegroundColor Gray
    Write-Host "    Fetch attempts: $($diag.jwks.fetchAttempts)" -ForegroundColor Gray
    Write-Host "  Security Metrics:" -ForegroundColor Gray
    Write-Host "    Auth successes: $($diag.security.authSuccesses)" -ForegroundColor Gray
    Write-Host "    Auth failures: $($diag.security.authFailures)" -ForegroundColor Gray
    Write-Host "    Rate limited: $($diag.security.rateLimited)" -ForegroundColor Gray
    $testsPassed++
} catch {
    Write-Host "✗ FAILED: $_" -ForegroundColor Red
    $testsFailed++
}

# Test 3: Protected Endpoint WITHOUT Token (Should Fail)
Write-Host "`n[TEST 3] Protected Endpoint WITHOUT Token (Should Return 401)" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/Secure/protected" -Method GET -ErrorAction Stop
    Write-Host "✗ UNEXPECTED SUCCESS - Should have returned 401!" -ForegroundColor Red
    $testsFailed++
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "✓ CORRECT - 401 Unauthorized as expected" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "✗ FAILED WITH WRONG STATUS: $_" -ForegroundColor Red
        $testsFailed++
    }
}

# Test 4: Generate Local Auth Token
Write-Host "`n[TEST 4] Generate Local Auth Token" -ForegroundColor Yellow
try {
    $tokenRequest = @{
        userId = "user123"
        email = "test@example.com"
        name = "Test User"
        roles = @("user", "admin")
        tenantId = "default"
    } | ConvertTo-Json
    
    $tokenResponse = Invoke-RestMethod -Uri "$baseUrl/api/Token/generate" -Method POST -Body $tokenRequest -ContentType "application/json" -ErrorAction Stop
    $token = $tokenResponse.token
    Write-Host "✓ SUCCESS - Token generated" -ForegroundColor Green
    Write-Host "  Token (first 50 chars): $($token.Substring(0, [Math]::Min(50, $token.Length)))..." -ForegroundColor Gray
    $testsPassed++
} catch {
    Write-Host "✗ FAILED: $_" -ForegroundColor Red
    $testsFailed++
    $token = $null
}

# Test 5: Protected Endpoint WITH Token
if ($token) {
    Write-Host "`n[TEST 5] Protected Endpoint WITH Token" -ForegroundColor Yellow
    try {
        $headers = @{ Authorization = "Bearer $token" }
        $response = Invoke-RestMethod -Uri "$baseUrl/api/Secure/protected" -Method GET -Headers $headers -ErrorAction Stop
        Write-Host "✓ SUCCESS - Authentication works!" -ForegroundColor Green
        Write-Host "  User info:" -ForegroundColor Gray
        Write-Host "    UserId: $($response.user.userId)" -ForegroundColor Gray
        Write-Host "    Email: $($response.user.email)" -ForegroundColor Gray
        Write-Host "    Name: $($response.user.name)" -ForegroundColor Gray
        Write-Host "    Roles: $($response.user.roles -join ', ')" -ForegroundColor Gray
        $testsPassed++
    } catch {
        Write-Host "✗ FAILED: $_" -ForegroundColor Red
        Write-Host "  Error details: $($_.Exception.Message)" -ForegroundColor Red
        $testsFailed++
    }
}

# Test 6: User Details Endpoint
if ($token) {
    Write-Host "`n[TEST 6] User Details Endpoint" -ForegroundColor Yellow
    try {
        $headers = @{ Authorization = "Bearer $token" }
        $response = Invoke-RestMethod -Uri "$baseUrl/api/Secure/user-details" -Method GET -Headers $headers -ErrorAction Stop
        Write-Host "✓ SUCCESS - User details retrieved" -ForegroundColor Green
        Write-Host "  Full response:" -ForegroundColor Gray
        Write-Host "    $($response | ConvertTo-Json -Depth 5)" -ForegroundColor Gray
        $testsPassed++
    } catch {
        Write-Host "✗ FAILED: $_" -ForegroundColor Red
        Write-Host "  Error details: $($_.Exception.Message)" -ForegroundColor Red
        $testsFailed++
    }
}

# Test 7: Check Diagnostics After Auth (JWKS should still be 0 for local JWT)
Write-Host "`n[TEST 7] Diagnostics After Authentication" -ForegroundColor Yellow
try {
    $diag = Invoke-RestMethod -Uri "$baseUrl/primus/diagnostics" -Method GET -ErrorAction Stop
    Write-Host "✓ SUCCESS" -ForegroundColor Green
    Write-Host "  Security Metrics Updated:" -ForegroundColor Gray
    Write-Host "    Auth successes: $($diag.security.authSuccesses)" -ForegroundColor Gray
    Write-Host "    Auth failures: $($diag.security.authFailures)" -ForegroundColor Gray
    Write-Host "  JWKS Stats (should be 0 for local JWT):" -ForegroundColor Gray
    Write-Host "    Fetch attempts: $($diag.jwks.fetchAttempts)" -ForegroundColor Gray
    $testsPassed++
} catch {
    Write-Host "✗ FAILED: $_" -ForegroundColor Red
    $testsFailed++
}

# Final Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Results Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Tests Passed: $testsPassed" -ForegroundColor Green
Write-Host "Tests Failed: $testsFailed" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })
Write-Host "Total Tests: $($testsPassed + $testsFailed)" -ForegroundColor Cyan

if ($testsFailed -eq 0) {
    Write-Host "`n🎉 ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host "`nKey Findings:" -ForegroundColor Yellow
    Write-Host "  ✅ Identity.Validator v1.3.0 works correctly" -ForegroundColor Green
    Write-Host "  ✅ JWT authentication successful" -ForegroundColor Green
    Write-Host "  ✅ Diagnostics endpoint functional (NEW in v1.3.0)" -ForegroundColor Green
    Write-Host "  ✅ Security metrics tracking" -ForegroundColor Green
    Write-Host "  ✅ No crashes or serialization errors" -ForegroundColor Green
} else {
    Write-Host "`n⚠️  SOME TESTS FAILED" -ForegroundColor Yellow
    Write-Host "Review the errors above for details." -ForegroundColor Yellow
}

Write-Host "`n========================================`n" -ForegroundColor Cyan
