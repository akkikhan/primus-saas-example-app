# PrimusSaaS Packages Test Script
# This script tests both PrimusSaaS.Identity.Validator v1.2.2 and PrimusSaaS.Logging v1.1.0

$baseUrl = "http://localhost:5001"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "PrimusSaaS Packages Test Application" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: Public endpoint (no auth required)
Write-Host "TEST 1: Public Endpoint (No Authentication)" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/secure/public" -Method Get
    Write-Host "✓ Success:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 5)
} catch {
    Write-Host "✗ Failed: $_" -ForegroundColor Red
}

# Test 2: Generate JWT Token
Write-Host "`nTEST 2: Generate JWT Token" -ForegroundColor Yellow
$tokenRequest = @{
    userId = "test-user-123"
    email = "john.doe@example.com"
    name = "John Doe"
    roles = @("User", "Admin")
    tenantId = "tenant-acme-corp"
} | ConvertTo-Json

try {
    $tokenResponse = Invoke-RestMethod -Uri "$baseUrl/api/token/generate" -Method Post -Body $tokenRequest -ContentType "application/json"
    $token = $tokenResponse.token
    Write-Host "✓ Token Generated Successfully:" -ForegroundColor Green
    Write-Host "Token: $($token.Substring(0,50))..." -ForegroundColor Gray
    Write-Host "Expires At: $($tokenResponse.expiresAt)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Failed: $_" -ForegroundColor Red
    exit
}

# Test 3: Protected endpoint WITHOUT token (should fail)
Write-Host "`nTEST 3: Protected Endpoint WITHOUT Token (Should Fail)" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/secure/protected" -Method Get
    Write-Host "✗ Unexpected Success (should have failed)" -ForegroundColor Red
} catch {
    Write-Host "✓ Expected Failure - Unauthorized" -ForegroundColor Green
}

# Test 4: Protected endpoint WITH valid token
Write-Host "`nTEST 4: Protected Endpoint WITH Valid Token" -ForegroundColor Yellow
$headers = @{
    "Authorization" = "Bearer $token"
}
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/secure/protected" -Method Get -Headers $headers
    Write-Host "✓ Success - Authenticated:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 5)
} catch {
    Write-Host "✗ Failed: $_" -ForegroundColor Red
}

# Test 5: Admin endpoint with Admin role
Write-Host "`nTEST 5: Admin Endpoint WITH Admin Role" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/secure/admin" -Method Get -Headers $headers
    Write-Host "✓ Success - Admin Access:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 5)
} catch {
    Write-Host "✗ Failed: $_" -ForegroundColor Red
}

# Test 6: User details endpoint
Write-Host "`nTEST 6: User Details Endpoint" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/secure/user-details" -Method Get -Headers $headers
    Write-Host "✓ Success - User Details Retrieved:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 5)
} catch {
    Write-Host "✗ Failed: $_" -ForegroundColor Red
}

# Test 7: Logging - All log levels
Write-Host "`nTEST 7: Test All Log Levels" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/loggingtest/test-all-levels" -Method Get
    Write-Host "✓ Success:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json)
    Write-Host "Check console output for log messages" -ForegroundColor Gray
} catch {
    Write-Host "✗ Failed: $_" -ForegroundColor Red
}

# Test 8: Structured logging
Write-Host "`nTEST 8: Structured Logging" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/loggingtest/test-structured-logging" -Method Get
    Write-Host "✓ Success:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 5)
} catch {
    Write-Host "✗ Failed: $_" -ForegroundColor Red
}

# Test 9: PII Masking
Write-Host "`nTEST 9: PII Masking Test" -ForegroundColor Yellow
$piiData = @{
    email = "sensitive.user@example.com"
    password = "SuperSecret123!"
    ssn = "123-45-6789"
    apiKey = "sk_live_1234567890abcdef"
    creditCard = "4532-1234-5678-9010"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/loggingtest/test-pii-masking" -Method Post -Body $piiData -ContentType "application/json"
    Write-Host "✓ Success:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json)
    Write-Host "Check console/log file - sensitive data should be masked" -ForegroundColor Gray
} catch {
    Write-Host "✗ Failed: $_" -ForegroundColor Red
}

# Test 10: Correlation ID
Write-Host "`nTEST 10: Correlation ID Tracking" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/loggingtest/test-correlation-id" -Method Get
    Write-Host "✓ Success:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json)
} catch {
    Write-Host "✗ Failed: $_" -ForegroundColor Red
}

# Test 11: Exception logging
Write-Host "`nTEST 11: Exception Logging" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/loggingtest/test-exception" -Method Get
    Write-Host "✓ Success - Exception Logged:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json)
} catch {
    Write-Host "✗ Failed: $_" -ForegroundColor Red
}

# Test 12: Performance timing
Write-Host "`nTEST 12: Performance Timing" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/loggingtest/test-performance-timing" -Method Get
    Write-Host "✓ Success:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 5)
} catch {
    Write-Host "✗ Failed: $_" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "All Tests Completed!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nCheck the console output and logs/app.log for detailed logging information" -ForegroundColor Yellow
