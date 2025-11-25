# 🎯 Demo Quick Reference Card
**Print this or keep on second monitor during demo**

---

## ⏱️ Timeline
```
0-2min   : Introduction
2-5min   : "Before" (Traditional)
5-10min  : "After" (PrimusSaaS)
10-15min : Live Demo
15-18min : Advanced Features
18-20min : Q&A
```

---

## 🔑 Key URLs
- Frontend: `http://localhost:4200`
- Backend: `http://localhost:5001`
- Diagnostics: `http://localhost:5001/primus/diagnostics`
- Metrics: `http://localhost:5001/primus/logging/metrics`
- Swagger: `http://localhost:5001/swagger`

---

## 🚀 Start Commands

### Backend:
```powershell
cd C:\Users\aakib\PrimusSaaS.TestApp\PrimusSaaS.TestApp
dotnet run
```

### Frontend:
```powershell
cd C:\Users\aakib\PrimusSaaS.TestApp\PrimusSaaS.TestApp\primus-frontend
npm start
```

---

## 🧪 Quick Tests

### Generate Token:
```powershell
$body = @{
    userId = "test-user-123"
    email = "john.doe@example.com"
    name = "John Doe"
    roles = @("User", "Admin")
    tenantId = "tenant-acme-corp"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:5001/api/token/generate" -Method POST -ContentType "application/json" -Body $body
$token = $response.token
```

### Test Protected Endpoint:
```powershell
Invoke-RestMethod -Uri "http://localhost:5001/api/secure/protected" -Headers @{ "Authorization" = "Bearer $token" }
```

### Test PII Masking:
```powershell
$piiData = @{
    email = "john.doe@example.com"
    ssn = "123-45-6789"
    creditCard = "4532-1234-5678-9010"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5001/api/loggingtest/test-pii-masking" -Method POST -ContentType "application/json" -Body $piiData
```

### View Logs:
```powershell
Get-Content logs\primus-app.log -Tail 10
```

---

## 💡 Key Talking Points

### Identity Validator:
- ✅ Multi-issuer in 20 lines (vs 200+)
- ✅ Automatic JWKS for Azure AD
- ✅ `GetPrimusUser()` - 1 line vs 50
- ✅ Built-in diagnostics endpoint

### Logging:
- ✅ PII masking (GDPR ready)
- ✅ File rotation + gzip
- ✅ Async buffering
- ✅ Built-in metrics

---

## 🎭 Demo Scenarios

### Email/Password Login:
1. Go to `http://localhost:4200`
2. Email: `admin@claimportal.com`
3. Password: `password`
4. Show dashboard + user details

### Azure AD Login:
1. Click "Azure AD" tab
2. Click "Sign in with Microsoft"
3. Complete popup auth
4. Show same seamless experience

### Feature Toggle:
1. Comment PII config (lines 42-49)
2. Restart backend
3. Test PII endpoint
4. Show unmasked data
5. Uncomment to restore

---

## 📊 Comparison Table

| Feature | Traditional | PrimusSaaS |
|---------|-------------|------------|
| Setup Time | 2-3 hours | 15 min |
| Lines of Code | 200+ | 30 |
| Multi-Issuer | Manual | Built-in |
| PII Masking | Custom | Built-in |
| Diagnostics | Custom | Built-in |

---

## 🎯 "Wow" Moments

1. **Multi-Issuer:** Show 2 issuers in one config
2. **GetPrimusUser():** 1 line vs 50 lines
3. **PII Masking:** Automatic data protection
4. **Diagnostics:** Zero-code health endpoint
5. **File Rotation:** Automatic gzip compression

---

## 🔧 Troubleshooting

### Backend not starting:
```powershell
Test-NetConnection localhost -Port 5001
```

### Frontend not starting:
```powershell
Test-NetConnection localhost -Port 4200
```

### Clear everything:
```powershell
# Stop servers (Ctrl+C)
Remove-Item logs\*.log -Force
# Restart servers
```

---

## 📝 Files to Show

1. `Program.cs` (lines 65-118) - Identity config
2. `Program.cs` (lines 14-60) - Logging config
3. `SecureController.cs` - GetPrimusUser()
4. `LoggingV2TestController.cs` - Logging examples
5. `logs/primus-app.log` - Masked PII

---

## 🎤 Opening Line
> "Imagine cutting your authentication code from 200 lines to 20 lines, while ADDING more features. That's what we've built."

---

## 🎤 Closing Line
> "In 15 minutes, you can have enterprise-grade authentication and logging. No boilerplate, no headaches, just results. Questions?"

---

## ✅ Pre-Demo Checklist
- [ ] Backend running
- [ ] Frontend running
- [ ] Logs cleared
- [ ] Browser cache cleared
- [ ] Font size increased (16-18pt)
- [ ] Browser zoom 125-150%
- [ ] Notifications silenced
- [ ] Demo script visible
- [ ] Commands cheat sheet open
- [ ] Water nearby

---

## 🆘 Emergency Backup
If live demo fails:
1. Use screenshots from `DEMO_FLOW_VISUAL.md`
2. Use Postman with saved responses
3. Show code and explain
4. Focus on value proposition

---

## 📞 Support
- Demo Script: `DEMO_SCRIPT.md`
- Commands: `DEMO_COMMANDS.md`
- Code Guide: `CODE_INTEGRATION_GUIDE.md`
- Visual Flow: `DEMO_FLOW_VISUAL.md`

---

**YOU GOT THIS! 🚀**

---

**Prepared By**: Aakib Khan  
**Last Updated**: November 25, 2025
