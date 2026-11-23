param([ValidateNotNullOrEmpty()][string]$Version = 'latest', [ValidateSet('host','launcher')][string]$Role = 'host')
$ErrorActionPreference = 'Stop'
$docs = 'https://raw.githubusercontent.com/Cortivar/platform-docs/main'
# An emulated x64 process on Windows ARM64 may report AMD64 in its environment.
# Select by the OS's native machine, not that of the PowerShell/Setup process.
if (-not ('Cortivar.Install.NativeMachine' -as [type])) {
    Add-Type -Namespace Cortivar.Install -Name NativeMachine -MemberDefinition @'
        [System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError=true)]
        private static extern bool IsWow64Process2(System.IntPtr process, out ushort processMachine, out ushort nativeMachine);
        public static ushort Get() {
            ushort process, native;
            if (!IsWow64Process2(new System.IntPtr(-1), out process, out native))
                throw new System.ComponentModel.Win32Exception(System.Runtime.InteropServices.Marshal.GetLastWin32Error());
            return native;
        }
'@
}
$target = switch ([Cortivar.Install.NativeMachine]::Get()) {
    0x8664 { 'windows-amd64' }
    0xAA64 { 'windows-arm64' }
    default { throw "Unsupported native Windows machine: $_" }
}
if ($Version -ceq 'latest') {
    $Version = ([string](Invoke-RestMethod "$docs/channels/stable")).Trim()
    if ($Version -ceq 'unpublished') { throw 'No stable release has been published yet. To install a published prerelease, specify its exact version.' }
    if (!$Version.StartsWith('v') -or $Version.Contains('-')) { throw 'Invalid stable release pointer.' }
} elseif ($Version -cmatch '^[0-9]') { $Version = "v$Version" }
if ($Version -cnotmatch '\Av(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[a-z0-9]+([.-][a-z0-9]+)*)?\z') { throw 'Expected latest or an exact release version.' }
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
    if ([IO.File]::Exists($exe)) {
        if ((Get-FileHash $exe).Hash -ne $digest) {
            try { [IO.File]::Replace($launcher,$exe,(Join-Path $stage 'previous.exe')) }
            catch { throw 'Could not replace the launcher. Close Tool Desk and the console, stop the host service, then retry.' }
        }
    } else { [IO.File]::Move($launcher,$exe) }
    [IO.File]::WriteAllText($marker,$digest)
    $old = [Environment]::GetEnvironmentVariable('Path','User')
    if (($old -split ';') -notcontains $bin) { [Environment]::SetEnvironmentVariable('Path',("$old;$bin").Trim(';'),'User') }
    if ($Role -eq 'host') { & $exe install meltemia $package; if ($LASTEXITCODE -ne 0) { throw 'Knowledge install failed.' } }
    Write-Output "Installed $Version. Run: & '$exe'"
} finally { Remove-Item -LiteralPath $stage -Recurse -Force }
