$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$serveRoot = Join-Path $root "outputs"
if (-not (Test-Path -LiteralPath (Join-Path $serveRoot "password-workspace.html"))) {
  $serveRoot = $root
}
$port = 8017
$python = "C:/Users/admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe"

if (-not (Test-Path -LiteralPath $python)) {
  Write-Host "Codex bundled Python was not found: $python"
  Write-Host "From the outputs directory, run: python -m http.server 8017 --bind 127.0.0.1"
  Read-Host "Press Enter to exit"
  exit 1
}

$listener = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue |
  Where-Object { $_.State -eq "Listen" } |
  Select-Object -First 1

if (-not $listener) {
  Start-Process -FilePath $python -ArgumentList @("-m", "http.server", "$port", "--bind", "127.0.0.1") -WorkingDirectory $serveRoot -WindowStyle Hidden
  Start-Sleep -Milliseconds 800
}

$url = if ($serveRoot -eq $root) { "http://127.0.0.1:$port/" } else { "http://127.0.0.1:$port/password-workspace.html" }
Start-Process $url
Write-Host "Password workspace started: $url"
