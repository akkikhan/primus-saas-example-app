# PrimusSaaS Packages v1.3.0 & v1.2.1 - Comprehensive Test Suite
# This script tests the updated packages and generates a detailed report

$baseUrl = "http://localhost:5002"
$results = @()

function Add-TestResult {
    param($TestName, $Status, $Details, $Response = $null)
    $results += [PSCustomObject]@{
        Test = $TestName
        Status = $Status
        Details = $Details
        Response = $Response
        Timestamp = Get-Date -Format "HH:mm:ss"
    }
}

Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PrimusSaaS Packages - Comprehensive Test" -ForegroundColor Cyan
Write-Host "Identity.Validator: 1.3.0" -ForegroundColor Cyan
Write-Host "Logging: 1.2.1 (API changed - tested separately)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`n"

# Test 1: NEW Diagnostics Endpoint (v1.3.0 feature)
Write-Host "TEST 1: Diagnostics Endpoint (NEW in v1.3.0)" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/primus/diagnostics" -Method GET
    Write-Host "✓ SUCCESS" -ForegroundColor Green
    Write-Host "Diagnostics data retrieved:" -ForegroundColor Gray
    $response | ConvertTo-Json -Depth 5
    Add-TestResult "Diagnostics Endpoint" "PASS" "Successfully retrieved diagnostics" $response
} catch {
    Write-Host "✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Add-TestResult "Diagnostics Endpoint" "FAIL" $_.Exception.Message
}

Write-Host "`n"

# Test 2: Public Endpoint (baseline)
Write-Host "TEST 2: Public Endpoint (No Auth)" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/Secure/public" -Method GET
    Write-Host "✓ SUCCESS" -ForegroundColor Green
    $response | ConvertTo-Json
    Add-TestResult "Public Endpoint" "PASS" "Public endpoint accessible" $response
} catch {
    Write-Host "✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Add-TestResult "Public Endpoint" "FAIL" $_.Exception.Message
}

Write-Host "`n"

# Test 3: Protected Endpoint Without Token (should fail with 401)
Write-Host "TEST 3: Protected Endpoint (No Token - Should Return 401)" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/Secure/protected" -Method GET -ErrorAction Stop
    Write-Host "✗ UNEXPECTED SUCCESS - Should have returned 401" -ForegroundColor Red
    Add-TestResult "Protected Without Token" "FAIL" "Expected 401, got success"
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "✓ CORRECT - 401 Unauthorized as expected" -ForegroundColor Green
        Add-TestResult "Protected Without Token" "PASS" "Correctly returned 401"
    } else {
        Write-Host "✗ FAILED WITH WRONG STATUS: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
        Add-TestResult "Protected Without Token" "FAIL" "Wrong status: $($_.Exception.Response.StatusCode)"
    }
}

Write-Host "`n"

# Test 4: Get Local Auth Token
Write-Host "TEST 4: Get LocalAuth Token" -ForegroundColor Yellow
$token = $null
try {
    $tokenBody = @{
        email = "test@example.com"
        password = "Password123!"
    } | ConvertTo-Json

    $tokenResponse = Invoke-RestMethod -Uri "$baseUrl/api/Token/local" -Method POST -ContentType "application/json" -Body $tokenBody
    $token = $tokenResponse.token
    Write-Host "✓ SUCCESS - Token retrieved" -ForegroundColor Green
    Write-Host "Token (first 50 chars): $($token.Substring(0, [Math]::Min(50, $token.Length)))..." -ForegroundColor Gray
    Add-TestResult "Get LocalAuth Token" "PASS" "Token generated successfully" $tokenResponse
} catch {
    Write-Host "✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Add-TestResult "Get LocalAuth Token" "FAIL" $_.Exception.Message
}

Write-Host "`n"

# Test 5: Protected Endpoint WITH Token
if ($token) {
    Write-Host "TEST 5: Protected Endpoint WITH Token" -ForegroundColor Yellow
    try {
        $headers = @{
            "Authorization" = "Bearer $token"
        }
        $response = Invoke-RestMethod -Uri "$baseUrl/api/Secure/protected" -Method GET -Headers $headers
        Write-Host "✓ SUCCESS" -ForegroundColor Green
        $response | ConvertTo-Json -Depth 5
        Add-TestResult "Protected With Token" "PASS" "Successfully accessed protected endpoint" $response
    } catch {
        Write-Host "✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
        Add-TestResult "Protected With Token" "FAIL" $_.Exception.Message
    }
} else {
    Write-Host "SKIPPED: No token available" -ForegroundColor Yellow
    Add-TestResult "Protected With Token" "SKIP" "No token from previous test"
}

Write-Host "`n"

# Test 6: User Details Endpoint
if ($token) {
    Write-Host "TEST 6: User Details Endpoint" -ForegroundColor Yellow
    try {
        $headers = @{
            "Authorization" = "Bearer $token"
        }
        $response = Invoke-RestMethod -Uri "$baseUrl/api/Secure/user-details" -Method GET -Headers $headers
        Write-Host "✓ SUCCESS" -ForegroundColor Green
        $response | ConvertTo-Json -Depth 5
        Add-TestResult "User Details" "PASS" "Successfully retrieved user details" $response
    } catch {
        Write-Host "✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Error details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        Add-TestResult "User Details" "FAIL" "$($_.Exception.Message) - $($_.ErrorDetails.Message)"
    }
} else {
    Write-Host "SKIPPED: No token available" -ForegroundColor Yellow
    Add-TestResult "User Details" "SKIP" "No token from previous test"
}

Write-Host "`n"

# Test 7: JWKS Discovery Test (checking if JWKS URL works)
Write-Host "TEST 7: JWKS Discovery (Testing Fixed JWKS URL Construction)" -ForegroundColor Yellow
try {
    # Try to access JWKS endpoint directly
    $jwksUrl = "https://login.microsoftonline.com/cbd15a9b-cd52-4ccc-916a-00e2edb13043/discovery/v2.0/keys"
    $jwks = Invoke-RestMethod -Uri $jwksUrl -Method GET
    Write-Host "✓ SUCCESS - JWKS endpoint accessible" -ForegroundColor Green
    Write-Host "Number of keys: $($jwks.keys.Count)" -ForegroundColor Gray
    Add-TestResult "JWKS Discovery" "PASS" "JWKS endpoint accessible, $($jwks.keys.Count) keys found" $jwks
} catch {
    Write-Host "✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Add-TestResult "JWKS Discovery" "FAIL" $_.Exception.Message
}

Write-Host "`n"

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$passed = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
$skipped = ($results | Where-Object { $_.Status -eq "SKIP" }).Count
$total = $results.Count

Write-Host "`nTotal Tests: $total" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
Write-Host "Skipped: $skipped" -ForegroundColor Yellow

Write-Host "`n========================================`n" -ForegroundColor Cyan

# Generate report
$reportPath = "TEST_RESULTS_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$report = @"
PrimusSaaS Packages Test Results
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
========================================

Packages Tested:
- PrimusSaaS.Identity.Validator 1.3.0
- PrimusSaaS.Logging 1.2.1 (API changed - tested separately)

Test Results:
========================================

"@

foreach ($result in $results) {
    $report += @"
Test: $($result.Test)
Status: $($result.Status)
Time: $($result.Timestamp)
Details: $($result.Details)
$(if ($result.Response) { "Response: $($result.Response | ConvertTo-Json -Depth 3 -Compress)" })

----------------------------------------

"@
}

$report += @"

Summary:
========================================
Total: $total
Passed: $passed
Failed: $failed
Skipped: $skipped

Pass Rate: $([math]::Round(($passed / ($total - $skipped)) * 100, 2))%
"@

$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "Test report saved to: $reportPath" -ForegroundColor Green

# Display results table
Write-Host "`nDetailed Results:" -ForegroundColor Cyan
$results | Format-Table -Property Test, Status, Timestamp, Details -AutoSize
