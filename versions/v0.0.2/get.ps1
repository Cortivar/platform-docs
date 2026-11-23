# Use this release's installer and catalog, independent of the stable channel.
& ([scriptblock]::Create((Invoke-RestMethod 'https://raw.githubusercontent.com/Cortivar/platform-docs/v0.0.2/install.ps1' -ErrorAction Stop))) -Version 'v0.0.2'
