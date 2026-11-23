# Exercise the actual script with only download and user PATH writes isolated.
$ErrorActionPreference = 'Stop'
$tmp = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid())
$prev = $env:LOCALAPPDATA
$oldPath = [Environment]::GetEnvironmentVariable('Path','User')
$oldArch = $env:PROCESSOR_ARCHITECTURE
$oldWow = $env:PROCESSOR_ARCHITEW6432
[void][IO.Directory]::CreateDirectory($tmp)
try {
    $env:LOCALAPPDATA = $tmp
    $binary = Join-Path $env:SystemRoot 'System32\where.exe'
    $hash = (Get-FileHash $binary).Hash.ToLowerInvariant()
    # Derive the expected target independently of the installer, and make
    # process architecture variables misleading (as with emulated hosts).
    $platform = switch ((Get-CimInstance Win32_Processor | Select-Object -First 1).Architecture) {
        9 { 'windows-amd64' } 12 { 'windows-arm64' } default { throw 'Unsupported test machine' }
    }
    $env:PROCESSOR_ARCHITECTURE = 'x86'
    $env:PROCESSOR_ARCHITEW6432 = if ($platform -eq 'windows-arm64') { 'AMD64' } else { 'ARM64' }
    $env:CORTIVAR_FIXTURE_CATALOG = "launcher-$platform`t$hash`thttps://fixture/launcher"
    $requests = New-Object 'System.Collections.Generic.List[string]'
    $channelVersion = 'v1.10.0'
    function Invoke-RestMethod([string]$Uri) {
        $requests.Add($Uri)
        if ($Uri.EndsWith('/install.ps1')) { return Get-Content -LiteralPath $installer -Raw }
        if ($Uri.EndsWith('/files.tsv') -and $probeEntry) { throw 'Reached install catalog' }
        if ($Uri.EndsWith('/stable')) { return $channelVersion }
        if ($Uri -cnotmatch '/versions/(v1\.10\.0|v1\.9\.9|v2\.0\.0-rc\.1)/files\.tsv$') { throw 'No such release catalog' }
        return $env:CORTIVAR_FIXTURE_CATALOG
    }
    function Invoke-WebRequest([switch]$UseBasicParsing,[string]$Uri,[string]$OutFile) { Copy-Item $binary $OutFile }
    $installer = Join-Path $PSScriptRoot '..\install.ps1'
    $origin = 'https://raw.githubusercontent.com/Cortivar/platform-docs/main'
    function Assert-Requests([string[]]$Expected) {
        if (($requests -join ',') -cne ($Expected -join ',')) { throw "Unexpected version resolution: $requests" }
        $requests.Clear()
    }
    # Run the same pipeline as a user. Stop at the catalog so we can test a
    # different stable pointer without downloading a host package.
    $root = Split-Path $installer
    $probeEntry = $true
    $entries = @(Get-Item "$root/get.ps1") + @(Get-ChildItem "$root/versions/*/get.ps1")
    foreach ($entry in $entries) {
        $reached = $false
        try { Get-Content -LiteralPath $entry.FullName -Raw | iex } catch { $reached = $_ -like '*Reached install catalog*' }
        if (!$reached) { throw "Could not run $($entry.FullName)" }
        if ($entry.Directory.Name -like 'v*') {
            $tag = $entry.Directory.Name
            Assert-Requests @("https://raw.githubusercontent.com/Cortivar/platform-docs/$tag/install.ps1","$origin/versions/$tag/files.tsv")
        } else {
            Assert-Requests @("$origin/install.ps1","$origin/channels/stable","$origin/versions/$channelVersion/files.tsv")
        }
    }
    $probeEntry = $false
    # The terminal-only entry must succeed with a launcher-only catalog.
    Get-Content "$root/desk.ps1" -Raw | iex
    Assert-Requests @("$origin/install.ps1","$origin/channels/stable","$origin/versions/v1.10.0/files.tsv")
    & $installer -Role launcher
    Assert-Requests @("$origin/channels/stable","$origin/versions/v1.10.0/files.tsv")
    & $installer -Role launcher -Version latest
    Assert-Requests @("$origin/channels/stable","$origin/versions/v1.10.0/files.tsv")
    & $installer -Role launcher -Version '1.9.9'
    Assert-Requests @("$origin/versions/v1.9.9/files.tsv")
    & $installer -Role launcher -Version 'v2.0.0-rc.1'
    Assert-Requests @("$origin/versions/v2.0.0-rc.1/files.tsv")
    $channelVersion = 'v2.0.0-rc.1'
    $rejected = $false
    try { & $installer -Role launcher } catch { $rejected = $_ -like '*Invalid stable release pointer*' }
    if (!$rejected) { throw 'Selected prerelease from stable channel' }
    Assert-Requests @("$origin/channels/stable")
    $channelVersion = 'v1.10.0'
    $rejected = $false
    try { & $installer -Role launcher -Version 'v9.9.9' } catch { $rejected = $_ -like '*No such release catalog*' }
    if (!$rejected) { throw 'Unknown pin was accepted' }
    Assert-Requests @("$origin/versions/v9.9.9/files.tsv")
    $exe = Join-Path $tmp 'Cortivar\bin\cortivar.exe'
    if ((Get-FileHash $exe).Hash -ne $hash) { throw 'wrong payload' }
    $env:CORTIVAR_FIXTURE_CATALOG = $env:CORTIVAR_FIXTURE_CATALOG.Replace($hash,('0' * 64))
    $rejected = $false
    try { & $installer -Role launcher } catch { $rejected = $_ -like '*Checksum failed*' }
    if (!$rejected -or (Get-FileHash $exe).Hash -ne $hash) { throw 'failed rollback of bad download' }
    [IO.File]::WriteAllText($exe,'unrelated')
    $rejected = $false
    try { & $installer -Role launcher } catch { $rejected = $_ -like '*Unmanaged*' }
    if (!$rejected -or [IO.File]::ReadAllText($exe) -ne 'unrelated') { throw 'replaced unmanaged launcher' }
} finally {
    $env:PROCESSOR_ARCHITECTURE = $oldArch
    $env:PROCESSOR_ARCHITEW6432 = $oldWow
    $env:LOCALAPPDATA = $prev
    Remove-Item Env:CORTIVAR_FIXTURE_CATALOG -ErrorAction SilentlyContinue
    [Environment]::SetEnvironmentVariable('Path',$oldPath,'User')
    Remove-Item -LiteralPath $tmp -Recurse -Force
}
