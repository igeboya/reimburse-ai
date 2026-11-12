# Push repo ke GitHub. Jalankan:  .\push.ps1 igeboya
param([Parameter(Mandatory=$true)][string]$User)
$repo = "reimburse-ai"
git remote remove origin 2>$null
git remote add origin "https://github.com/$User/$repo.git"
git branch -M main
git push -u origin main
Write-Host ""
Write-Host "Selesai. Buka https://github.com/$User/$repo" -ForegroundColor Green
Write-Host "Jangan lupa: About -> gear -> pastikan License terbaca MIT dan Topics: n8n, paypal, ai, hackathon" -ForegroundColor Yellow
