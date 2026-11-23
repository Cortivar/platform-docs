# Cortivar Docs

Run a local Knowledge workspace for your team’s repository notes and a worker
for repeatable jobs. **Tool Desk** is the terminal menu. **Console** is the
local browser UI. Start here to install both on one machine.

[Install](#install) · [Choose a version](#choose-a-version) · [Platform packages](docs/packages.md) · [CLI and MCP](docs/operations.md) · [Release downloads](https://github.com/Cortivar/platform-docs/releases)

## Install

Use your normal user account. By default you get the **latest stable release**
and the full host package. The installer detects your OS and CPU; an Apple
Silicon Mac does not download the Intel, Windows or Linux builds.

**macOS or Linux** — in a terminal:

```sh
curl -fsSL https://raw.githubusercontent.com/Cortivar/platform-docs/main/install.sh -o install-cortivar.sh &&
  sh install-cortivar.sh
```

**Windows** — in PowerShell:

```powershell
$installer = Join-Path $env:TEMP 'install-cortivar.ps1'
Invoke-WebRequest -UseBasicParsing https://raw.githubusercontent.com/Cortivar/platform-docs/main/install.ps1 -OutFile $installer -ErrorAction Stop
& $installer
```

**Expected:** the installer prints the version and the full launcher path.
There’s no Go, Rust or Python toolchain to install. **Linux x64 hosts** need
Node 24 and a working local Docker daemon; check the
[requirements for your target](docs/packages.md#which-files-do-i-get).
Only here to join an existing shared workspace in a browser? Open the HTTPS
address from its owner and sign in with your human workspace credential.

## Choose a version

For a pinned install, download the same script shown above, then **replace
the invocation** with the command you want. In PowerShell, `$installer` is
the downloaded file path set above.

| Select | macOS / Linux | Windows PowerShell |
| --- | --- | --- |
| Latest stable | `sh install-cortivar.sh` | `& $installer` |
| Exact version (example) | `sh install-cortivar.sh --version v0.0.1` | `& $installer -Version v0.0.1` |
| Exact prerelease (example) | `sh install-cortivar.sh --version v0.1.0-rc.1` | `& $installer -Version v0.1.0-rc.1` |
| Launcher only | `sh install-cortivar.sh --role launcher` | `& $installer -Role launcher` |

Take the exact tag from [published releases](https://github.com/Cortivar/platform-docs/releases).
`0.0.1` and `v0.0.1` select the same catalog. You can combine role and version.
An exact pin bypasses [`channels/stable`](channels/stable); if that catalog
doesn’t exist, the installer stops rather than choosing another build.
If `stable` reads `unpublished`, there is no default release yet.

## Start using the host

1. Run `cortivar`. On macOS, Windows and Linux ARM64, choose **Create or join
   a workspace → Host on this machine**. First setup creates your private
   database and credentials, enables the user service and prints a browser link.
2. **Linux x64:** choose **Host a workspace here**. To hand that workspace
   to the worker, stop the independent workspace from its menu, then run
   `cortivar service knowledge on`, `cortivar service enable`, and `cortivar console`.
3. Open the private link. **Services** shows the worker and workspace status.
   In **Knowledge**, sign in with the `human-token` file identified during setup.
   The console link does not grant Knowledge access.

You can close the console and keep working. Run `cortivar console` for a fresh
link. If you installed just the launcher, install the host role before these steps.

## What next?

- [Run a smoke-test job and read its log](docs/operations.md#run-your-first-job).
- [Connect a coding agent over MCP](docs/operations.md#connect-an-agent).
- [Check service status or troubleshoot an install](docs/operations.md#troubleshooting).
- [See what gets downloaded and how version selection works](docs/packages.md).

## Releases

This public repository holds docs, installers and version catalogs. Binaries
are attached to [GitHub Releases](https://github.com/Cortivar/platform-docs/releases),
not committed to Git. Look at the [stable pointer](channels/stable) for the
default version, not the newest commit or source tag.
