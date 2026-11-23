# Run the stable installer in its own scope when piped to Invoke-Expression.
& ([scriptblock]::Create((Invoke-RestMethod 'https://raw.githubusercontent.com/Cortivar/platform-docs/main/install.ps1' -ErrorAction Stop)))
