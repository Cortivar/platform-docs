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

**Default: latest stable, full host install.** The installer reads
[`channels/stable`](channels/stable) once, then uses that exact version's
catalog for every download. No installed copy updates in the background;
rerunning the installer resolves the default again. Use `--role launcher`
or `-Role launcher` for Tool Desk alone.

After downloading the script above, choose **one** invocation:

| Install | macOS / Linux | Windows PowerShell |
| --- | --- | --- |
| Latest stable | `sh install-cortivar.sh` | `& $installer` |
| Same default, explicit | `sh install-cortivar.sh --version latest` | `& $installer -Version latest` |
| Exact release | `sh install-cortivar.sh --version v1.2.0` | `& $installer -Version v1.2.0` |
| Exact prerelease | `sh install-cortivar.sh --version v1.3.0-rc.1` | `& $installer -Version v1.3.0-rc.1` |

The versions in the table are examples; choose a published version from
[Releases](https://github.com/Cortivar/platform-docs/releases). `1.2.0`
and `v1.2.0` select the same catalog. A pin bypasses the stable channel
entirely. An unknown version or checksum mismatch stops the install; it never
silently substitutes a different release. If `stable` says `unpublished`,
the default stops until a stable release exists. An explicitly pinned,
published prerelease is still installable. The pin selects **product binaries**,
not a database snapshot.

### Start using the host

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

A product commit runs builds and tests. Pushing a new version tag builds that
commit and checks the install and service workflow across all six supported
targets. Only after those checks pass are the binaries published as assets
and a `versions/TAG/files.tsv` catalog committed here. A newer final release
advances `stable`; a prerelease or an older maintenance release does not.
For example, after `v1.10.0`, publishing `v1.9.10` or `v2.0.0-rc.1` leaves
the default at `v1.10.0`. Each remains available by its exact tag.

This follows [Semantic Versioning §3 and §11](https://semver.org/spec/v2.0.0.html)
for unchanged released versions and numeric precedence. Default selection is
an installer policy: like [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-kubectl-binary-with-curl-on-linux)
and the [.NET install scripts](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-install-script#options),
we resolve a moving channel for convenience and accept an exact version for
repeatable installs.

Use only a released catalog. The release files are listed under **Releases**,
not in this Git repository's file tree. Retain the matching catalog when
keeping a version for rollback. Do not check in workspace data, keys, session
links, credentials, binary archives or CI logs.
