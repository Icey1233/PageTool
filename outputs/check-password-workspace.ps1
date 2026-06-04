$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$html = Join-Path $root "password-workspace.html"
$launcher = Join-Path $root "start-password-workspace.ps1"
$cmdLauncher = Join-Path $root "start-password-workspace.cmd"
$readme = Join-Path $root "README-password-workspace.md"
$decisions = Join-Path $root "DECISIONS-password-workspace.md"
$node = "C:/Users/admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe"

$required = @($html, $launcher, $cmdLauncher, $readme, $decisions)
foreach ($file in $required) {
  if (-not (Test-Path -LiteralPath $file)) {
    throw "Missing file: $file"
  }
}

$parseErrors = $null
[System.Management.Automation.PSParser]::Tokenize((Get-Content -LiteralPath $launcher -Raw), [ref]$parseErrors) | Out-Null
if ($parseErrors) {
  throw "PowerShell launcher syntax error: $($parseErrors[0].Message)"
}

if ((Get-Content -LiteralPath $cmdLauncher -Raw) -notmatch "start-password-workspace\.ps1") {
  throw "CMD launcher does not call the PowerShell launcher."
}

if (-not (Test-Path -LiteralPath $node)) {
  throw "Node.js not found: $node"
}

$jsCheck = @'
const fs = require("fs");
const html = fs.readFileSync(process.argv[2], "utf8");
const match = html.match(/<script>([\s\S]*)<\/script>/);
if (!match) throw new Error("missing inline script");
new Function(match[1]);
console.log("HTML script syntax ok");
'@
$tmpJs = Join-Path ([System.IO.Path]::GetTempPath()) "password-workspace-check.js"
Set-Content -LiteralPath $tmpJs -Value $jsCheck -Encoding ASCII
& $node $tmpJs $html
if ($LASTEXITCODE -ne 0) {
  throw "HTML script syntax check failed."
}

try {
  $response = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:8017/password-workspace.html" -TimeoutSec 3
  Write-Host "HTTP check ok: $($response.StatusCode)"
} catch {
  Write-Host "HTTP check skipped or failed. The local service may not be running. Run start-password-workspace.cmd and try again."
}

Write-Host "Password workspace self-check complete."
