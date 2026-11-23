# Cortivar platform installation

This repository contains the user guide and per-user installers. Product source
is maintained separately. No compiled binaries are committed here.
For each published version the installer uses a reviewed download catalog
in `versions/` and verifies each downloaded file's SHA-256. The actual files
are **release assets**, not source files or expiring CI downloads.

### Install a local Tool Desk and Knowledge host

On macOS or Linux, download and run the bootstrap:

```sh
curl -fsSL https://raw.githubusercontent.com/Cortivar/platform-docs/main/install.sh -o install-cortivar.sh
sh install-cortivar.sh
```

On Windows, in PowerShell:

```powershell
$installer = Join-Path $env:TEMP 'install-cortivar.ps1'
Invoke-WebRequest -UseBasicParsing https://raw.githubusercontent.com/Cortivar/platform-docs/main/install.ps1 -OutFile $installer
& $installer
```

The default installs the host package, then prints the next terminal command.
Use `--role launcher` / `-Role launcher` for Tool Desk alone. Select an explicit
version with `--version vX.Y.Z` / `-Version vX.Y.Z`. Otherwise the installer
uses `channels/stable`. If that channel is `unpublished`, there is no tested
public full-platform version available yet.

1. Run `cortivar`. Choose the workspace action, then **Host on this machine**
   (Linux x86-64: **Host a workspace here**). The first run creates a new local
   database and distinct human and agent credentials.
2. On macOS, Windows and Linux ARM64, this enables the per-user background
   worker and prints a private browser link. On Linux x86-64, stop the newly
   created independent workspace in its menu, then run `cortivar service
   knowledge on`, `cortivar service enable` and `cortivar console`.
3. Open the private link. **Services** manages the worker and its jobs.
   **Knowledge** requires the workspace's separate human credential.
   To reopen the GUI later, run `cortivar console`. Closing the GUI does
   not stop the worker. `cortivar service stop` stops it; `service disable`
   also turns off launch at user login.

| Platform | Local host requirements |
| --- | --- |
| macOS Intel and Apple Silicon | User login session. PostgreSQL and app runtimes are included. |
| Windows x64 and Windows 11 ARM64 | Interactive user session with Task Scheduler; ARM64 uses Windows x64 emulation for bundled PostgreSQL. |
| Linux ARM64 | systemd user manager; PostgreSQL is included. |
| Linux x86-64 | systemd user manager, Node.js 24, and permission to use a local Docker daemon. Docker pulls the pinned database image if absent. |

No Python, Go or Rust toolchain is required for installation. A user login
service is not a system-wide pre-login server. The desktop host GUI is
loopback-only. To use an existing shared workspace instead, obtain its HTTPS
URL and credentials from its owner.

### Releases

Use only a released catalog. The release files are listed under **Releases**,
not in this Git repository's file tree. Retain the matching catalog when
keeping a version for rollback. Do not check in workspace data, keys, session
links, credentials, binary archives or CI logs.
