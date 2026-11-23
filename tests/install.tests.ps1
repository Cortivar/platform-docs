# Exercise the actual script with only download and user PATH writes isolated.
$ErrorActionPreference = 'Stop'
$tmp = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid())
$prev = $env:LOCALAPPDATA
$oldPath = [Environment]::GetEnvironmentVariable('Path','User')
[void][IO.Directory]::CreateDirectory($tmp)
try {
    $env:LOCALAPPDATA = $tmp
    $binary = Join-Path $env:SystemRoot 'System32\where.exe'
    $hash = (Get-FileHash $binary).Hash.ToLowerInvariant()
    $platform = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'windows-arm64' } else { 'windows-amd64' }
    $script:catalog = "launcher-$platform`t$hash`thttps://fixture/launcher"
    function Invoke-RestMethod([string]$Uri) { if ($Uri.EndsWith('/stable')) { 'v0.1.0' } else { $script:catalog } }
    function Invoke-WebRequest([switch]$UseBasicParsing,[string]$Uri,[string]$OutFile) { Copy-Item $binary $OutFile }
    $installer = Join-Path $PSScriptRoot '..\install.ps1'
    & $installer -Role launcher
    & $installer -Role launcher
    $exe = Join-Path $tmp 'Cortivar\bin\cortivar.exe'
    if ((Get-FileHash $exe).Hash -ne $hash) { throw 'wrong payload' }
    $script:catalog = $script:catalog.Replace($hash,('0' * 64))
    $rejected = $false
    try { & $installer -Role launcher } catch { $rejected = $_ -like '*Checksum failed*' }
    if (!$rejected -or (Get-FileHash $exe).Hash -ne $hash) { throw 'failed rollback of bad download' }
    [IO.File]::WriteAllText($exe,'unrelated')
    $rejected = $false
    try { & $installer -Role launcher } catch { $rejected = $_ -like '*Unmanaged*' }
    if (!$rejected -or [IO.File]::ReadAllText($exe) -ne 'unrelated') { throw 'replaced unmanaged launcher' }
} finally {
    $env:LOCALAPPDATA = $prev
    [Environment]::SetEnvironmentVariable('Path',$oldPath,'User')
    Remove-Item -LiteralPath $tmp -Recurse -Force
}
