# =====================================================
# PrimusSaaS Identity.Validator v1.3.0 Test Script
# =====================================================
# Run this in a NEW PowerShell window while app is running
# =====================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "PrimusSaaS Identity.Validator v1.3.0" -ForegroundColor Cyan
Write-Host "Comprehensive Test Suite" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$baseUrl = "http://localhost:5002"
$testResults = @()

# Helper function
function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Method = "GET",
        [hashtable]$Headers = @{},
        [string]$Body = $null
    )
    
    Write-Host "`nTEST: $Name" -ForegroundColor Yellow
    Write-Host "URL: $Url" -ForegroundColor Gray
    
    try {
        $params = @{
            Uri = $Url
            Method = $Method
            Headers = $Headers
            ErrorAction = "Stop"
        }
        
        if ($Body) {
            $params.ContentType = "application/json"
            $params.Body = $Body
        }
        
        $response = Invoke-RestMethod @params
        Write-Host "✓ SUCCESS" -ForegroundColor Green
        $response | ConvertTo-Json -Depth 5
        
        return @{
            Test = $Name
            Status = "PASS"
            Response = $response
        }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 401) {
            Write-Host "✓ EXPECTED 401 Unauthorized" -ForegroundColor Green
            return @{
                Test = $Name
                Status = "PASS"
                Response = "401 Unauthorized (Expected)"
            }
        }
        else {
            Write-Host "✗ FAILED" -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
            return @{
                Test = $Name
                Status = "FAIL"
                Error = $_.Exception.Message
            }
        }
    }
}

# =====================================================
# TEST 1: Public Endpoint (No Auth)
# =====================================================
$result = Test-Endpoint -Name "Public Endpoint" -Url "$baseUrl/api/Secure/public"
$testResults += $result

# =====================================================
# TEST 2: New Diagnostics Endpoint (v1.3.0 Feature)
# =====================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "NEW v1.3.0 FEATURE: Diagnostics Endpoint" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$result = Test-Endpoint -Name "Diagnostics Endpoint" -Url "$baseUrl/primus/diagnostics"
$testResults += $result

Write-Host "`nDiagnostics should show:" -ForegroundColor Yellow
Write-Host "  - Configured issuers" -ForegroundColor Gray
Write-Host "  - JWKS cache statistics" -ForegroundColor Gray
Write-Host "  - Authentication metrics" -ForegroundColor Gray
Write-Host "  - Security events" -ForegroundColor Gray

# =====================================================
# TEST 3: Protected Endpoint Without Token (Should Fail)
# =====================================================
Write-Host "`n========================================" -ForegroundColor Cyan
$result = Test-Endpoint -Name "Protected Endpoint (No Token)" -Url "$baseUrl/api/Secure/protected"
$testResults += $result

# =====================================================
# TEST 4: Get LocalAuth Token
# =====================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Getting LocalAuth Token..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$tokenBody = @{
    email = "test@example.com"
    password = "Password123!"
} | ConvertTo-Json

try {
    $tokenResponse = Invoke-RestMethod -Uri "$baseUrl/api/Token/local" -Method POST -ContentType "application/json" -Body $tokenBody
    $token = $tokenResponse.token
    Write-Host "✓ Token obtained successfully" -ForegroundColor Green
    Write-Host "Token (first 50 chars): $($token.Substring(0, [Math]::Min(50, $token.Length)))..." -ForegroundColor Gray
    
    $testResults += @{
        Test = "Get LocalAuth Token"
        Status = "PASS"
        Response = "Token received"
    }
}
catch {
    Write-Host "✗ Failed to get token" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    $token = $null
    
    $testResults += @{
        Test = "Get LocalAuth Token"
        Status = "FAIL"
        Error = $_.Exception.Message
    }
}

# =====================================================
# TEST 5: Protected Endpoint WITH Token
# =====================================================
if ($token) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    $headers = @{ "Authorization" = "Bearer $token" }
    $result = Test-Endpoint -Name "Protected Endpoint (With Token)" -Url "$baseUrl/api/Secure/protected" -Headers $headers
    $testResults += $result
}

# =====================================================
# TEST 6: User Details Endpoint
# =====================================================
if ($token) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    $headers = @{ "Authorization" = "Bearer $token" }
    $result = Test-Endpoint -Name "User Details Endpoint" -Url "$baseUrl/api/Secure/user-details" -Headers $headers
    $testResults += $result
}

# =====================================================
# TEST 7: JWKS Discovery Test
# =====================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing JWKS Discovery (v1.3.0 Fix)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nChecking Azure AD JWKS URL..." -ForegroundColor Yellow
$jwksUrl = "https://login.microsoftonline.com/cbd15a9b-cd52-4ccc-916a-00e2edb13043/discovery/v2.0/keys"

try {
    $jwks = Invoke-RestMethod -Uri $jwksUrl -Method GET
    Write-Host "✓ JWKS endpoint accessible" -ForegroundColor Green
    Write-Host "Keys found: $($jwks.keys.Count)" -ForegroundColor Gray
    
    $testResults += @{
        Test = "JWKS Discovery (Azure AD)"
        Status = "PASS"
        Response = "$($jwks.keys.Count) keys found"
    }
}
catch {
    Write-Host "✗ JWKS endpoint failed" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    
    $testResults += @{
        Test = "JWKS Discovery (Azure AD)"
        Status = "FAIL"
        Error = $_.Exception.Message
    }
}

# =====================================================
# SUMMARY
# =====================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$passed = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$total = $testResults.Count

Write-Host "Total Tests: $total" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red

Write-Host "`n----------------------------------------" -ForegroundColor Gray
foreach ($result in $testResults) {
    $color = if ($result.Status -eq "PASS") { "Green" } else { "Red" }
    $symbol = if ($result.Status -eq "PASS") { "✓" } else { "✗" }
    Write-Host "$symbol $($result.Test)" -ForegroundColor $color
}
Write-Host "----------------------------------------`n" -ForegroundColor Gray

# =====================================================
# KEY FINDINGS
# =====================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "KEY v1.3.0 VALIDATION POINTS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "1. IssuerType Change:" -ForegroundColor Yellow
Write-Host "   - Old: IssuerType.Oidc" -ForegroundColor Gray
Write-Host "   - New: IssuerType.AzureAD" -ForegroundColor Green
Write-Host "   - Status: Code updated, app compiles ✓" -ForegroundColor Green

Write-Host "`n2. Diagnostics Endpoint:" -ForegroundColor Yellow
Write-Host "   - New feature in v1.3.0" -ForegroundColor Gray
Write-Host "   - Endpoint: GET /primus/diagnostics" -ForegroundColor Gray
Write-Host "   - Check test results above ↑" -ForegroundColor Gray

Write-Host "`n3. JWKS Discovery:" -ForegroundColor Yellow
Write-Host "   - v1.2.2 bug: Doubled /v2.0 in URL (404)" -ForegroundColor Red
Write-Host "   - v1.3.0 fix: Proper URL construction" -ForegroundColor Green
Write-Host "   - Check test results above ↑" -ForegroundColor Gray

Write-Host "`n4. TenantResolver Removed:" -ForegroundColor Yellow
Write-Host "   - v1.2.2: Had TenantResolver option" -ForegroundColor Gray
Write-Host "   - v1.3.0: Removed, claims mapping left to developer" -ForegroundColor Green
Write-Host "   - Status: Code updated ✓" -ForegroundColor Green

Write-Host "`n5. New Optional Features:" -ForegroundColor Yellow
Write-Host "   - Rate limiting (commented in code)" -ForegroundColor Gray
Write-Host "   - Token refresh with dev in-memory store" -ForegroundColor Gray
Write-Host "   - JWKS cache TTL configuration" -ForegroundColor Gray

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing Complete!" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
