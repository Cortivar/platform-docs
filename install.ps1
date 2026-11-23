param([string]$Version, [ValidateSet('host','launcher')][string]$Role = 'host')
$ErrorActionPreference = 'Stop'
$docs = 'https://raw.githubusercontent.com/Cortivar/platform-docs/main'
$arch = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
$target = switch ($arch) { 'AMD64' { 'windows-amd64' } 'ARM64' { 'windows-arm64' } default { throw 'Unsupported Windows architecture.' } }
if (!$Version) { $Version = ([string](Invoke-RestMethod "$docs/channels/stable")).Trim() }
if ($Version -eq 'unpublished') { throw 'No tested full-platform release has been published yet.' }
if ($Version -cnotmatch '^v[0-9][0-9A-Za-z.-]*$') { throw 'Invalid release version.' }
$catalog = ([string](Invoke-RestMethod "$docs/versions/$Version/files.tsv")).Trim() -split '\r?\n'
function Get-VerifiedAsset($name,$dest) {
    $rows = @($catalog | ForEach-Object { if (($_ -split '\s+')[0] -ceq $name) { $_ } })
    if ($rows.Count -ne 1) { throw "No unique release asset: $name" }
    $fields = $rows[0] -split '\s+'
    if ($fields.Count -ne 3 -or $fields[1] -cnotmatch '^[0-9a-f]{64}$' -or ([uri]$fields[2]).Scheme -ne 'https') { throw 'Invalid release catalog.' }
    Invoke-WebRequest -UseBasicParsing -Uri $fields[2] -OutFile $dest
    if ((Get-FileHash $dest -Algorithm SHA256).Hash -ne $fields[1]) { throw "Checksum failed: $name" }
}
$bin = Join-Path $env:LOCALAPPDATA 'Cortivar\bin'
$exe = Join-Path $bin 'cortivar.exe'
$marker = Join-Path $bin 'launcher.sha256'
[void][IO.Directory]::CreateDirectory($bin)
if ((Test-Path -LiteralPath $exe) -and (!(Test-Path -LiteralPath $marker) -or (Get-FileHash $exe).Hash -ne ([IO.File]::ReadAllText($marker)).Trim())) { throw "Unmanaged $exe left unchanged." }
$stage = Join-Path $bin ('.install-' + [guid]::NewGuid())
[void][IO.Directory]::CreateDirectory($stage)
try {
    $launcher = Join-Path $stage 'cortivar.exe'
    Get-VerifiedAsset "launcher-$target" $launcher
    $digest = (Get-FileHash $launcher).Hash
    $package = Join-Path $stage 'host.zip'
    if ($Role -eq 'host') { Get-VerifiedAsset "host-$target" $package }
    if ([IO.File]::Exists($exe)) { [IO.File]::Replace($launcher,$exe,(Join-Path $stage 'previous.exe')) } else { [IO.File]::Move($launcher,$exe) }
    [IO.File]::WriteAllText($marker,$digest)
    $old = [Environment]::GetEnvironmentVariable('Path','User')
    if (($old -split ';') -notcontains $bin) { [Environment]::SetEnvironmentVariable('Path',("$old;$bin").Trim(';'),'User') }
    if ($Role -eq 'host') { & $exe install meltemia $package; if ($LASTEXITCODE -ne 0) { throw 'Knowledge install failed.' } }
    Write-Output "Installed $Version. Run: & '$exe'"
} finally { Remove-Item -LiteralPath $stage -Recurse -Force }
