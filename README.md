# Cortivar Docs

Cortivar is a set of local developer tools. **Knowledge** keeps repository
guidance, **Workflows** runs repeatable jobs, and the **Requirements preview**
builds a brief from sample records. Start with **Tool Desk**, the terminal UI
included with Cortivar. **Console** is the browser interface for your host.

[Install](#install) · [Open Tool Desk](#open-tool-desk) · [Choose a version](#choose-a-version) · [Platform packages](docs/packages.md) · [CLI and MCP](docs/operations.md) · [Release downloads](https://github.com/Cortivar/platform-docs/releases)

## Install

Use your normal user account. By default you get the **latest stable release**
and the full host package. The installer detects your OS and CPU; an Apple
Silicon Mac does not download the Intel, Windows or Linux builds.

**macOS or Linux** — in a terminal:

```sh
curl -fsSL https://cortivar.com/get.sh | sh
```

**Windows** — in PowerShell:

```powershell
irm https://cortivar.com/get.ps1 | iex
```

The short URLs point to the installer scripts in this repository. In PowerShell,
`irm` downloads the script and `iex` runs it.

**Expected:** the installer prints the version and the full launcher path.
There’s no Go, Rust or Python toolchain to install. **Linux x64 hosts** need
Node 24 and a working local Docker daemon; check the
[requirements for your target](docs/packages.md#which-files-do-i-get).
Only here to join an existing shared workspace in a browser? Open the HTTPS
address from its owner and sign in with your human workspace credential.

## Open Tool Desk

After installation, run this in an interactive terminal:

```text
cortivar tui
```

`cortivar` opens the same screen. Use ↑/↓ or `j`/`k` to move, Enter to select,
and `q` to quit. `cortivar --plain` opens a numbered menu instead. If the
command isn't on your PATH yet, use the launcher path printed by the installer.
You can open the TUI before creating a workspace or starting any service.

In v0.0.1, **Meltemia** is an older name still printed by the installer and
workspace menu. With the full Cortivar install, the workspace package is
already present: choose **Create or join a workspace** when you're ready.
For jobs, open **Manage Cortivar host service → Workflows and recent runs**
or use `cortivar jobs list`. With the full install, try the offline brief
from your shell with `cortivar requirements preview`.

## Choose a version

To install **v0.0.1**, copy the line for your shell:

**macOS / Linux**

```sh
curl -fsSL https://cortivar.com/get.sh | sh -s -- --version v0.0.1
```

**Windows PowerShell**

```powershell
irm https://cortivar.com/v0.0.1/get.ps1 | iex
```

For another version, replace `v0.0.1` with its exact tag from
[Releases](https://github.com/Cortivar/platform-docs/releases). This also works
for published prereleases (for example, `v0.1.0-rc.1`).
Use the full `v` tag in the PowerShell URL.
An exact pin bypasses [`channels/stable`](channels/stable); if that catalog
doesn’t exist, the installer stops rather than choosing another build.
If `stable` reads `unpublished`, there is no default release yet.

### Launcher only

To open the TUI without installing the workspace package, use one of these
instead of the full install, then run `cortivar tui`:

```sh
curl -fsSL https://cortivar.com/get.sh | sh -s -- --role launcher
```

```powershell
irm https://cortivar.com/desk.ps1 | iex
```

Both select latest stable. To pin the launcher on macOS/Linux, append
`--version v0.0.1`. On Windows, save [install.ps1](https://raw.githubusercontent.com/Cortivar/platform-docs/main/install.ps1)
and run `.\install.ps1 -Role launcher -Version v0.0.1` from that directory.

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
