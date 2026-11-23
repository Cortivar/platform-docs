# Install only the latest stable Tool Desk; leave workspace packages out.
& ([scriptblock]::Create((Invoke-RestMethod 'https://raw.githubusercontent.com/Cortivar/platform-docs/main/install.ps1' -ErrorAction Stop))) -Role launcher
