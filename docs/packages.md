# Platform packages and version selection

[Docs](../README.md) / Package reference

## Which files do I get?

One release covers all six targets. Pick **your shell**, not an archive, in
the [quickstart](../README.md#install). Each full install downloads the
matching launcher plus the files listed below.

| Computer | Target | Host file(s) | Local requirements |
| --- | --- | --- | --- |
| Mac, Apple Silicon | `darwin-arm64` | `cortivar-host-darwin-arm64.zip` | User login session; LaunchAgent, bundled PostgreSQL |
| Mac, Intel | `darwin-amd64` | `cortivar-host-darwin-amd64.zip` | Same as Apple Silicon |
| Windows x64 | `windows-amd64` | `cortivar-host-windows-amd64.zip` | Interactive user session; Task Scheduler, bundled PostgreSQL |
| Windows 11 ARM64 | `windows-arm64` | `cortivar-host-windows-arm64.zip` | Same, with Windows x64 emulation for the bundled database |
| Linux ARM64 | `linux-arm64` | `cortivar-host-linux-arm64.zip` | systemd user manager; bundled PostgreSQL |
| Linux x64 | `linux-amd64` | `install-tui.sh` and `cortivar-host-linux-amd64.gz` | systemd user manager, Node 24, access to a local Docker daemon and the pinned database image |

Launcher assets are named `cortivar-TARGET.gz` on Unix and `cortivar-TARGET.exe`
on Windows. For example, a full Windows x64 install downloads **two files**:
`cortivar-windows-amd64.exe` and `cortivar-host-windows-amd64.zip`. GitHub shows
the complete release inventory; that isn't a list of things you need to install.
With the launcher-only role, the installer skips the host package. Linux x64
still receives the launcher’s separate worker executable.

## What does “latest” mean?

Both installers default to `latest`. They read `channels/stable` **once**, then
use `versions/TAG/files.tsv` for the whole install. Each catalog row is a role
and target, a SHA-256 digest, and a version-specific HTTPS asset URL. The installer
checks the downloaded bytes against that digest before installing them.

To reproduce a setup, specify the exact tag (examples in the [version picker](../README.md#choose-a-version)).
A prerelease is installed only by its exact version. If stable is `v1.10.0`,
a subsequently published `v1.9.10` or `v2.0.0-rc.1` does not change the
default. Existing machines do not auto-update.

## How a build becomes installable

1. An ordinary source commit builds and tests. It doesn't publish a download.
2. A new release tag on a reviewed commit triggers packaging and native
   install/service checks on all six targets.
3. After those checks pass, the pipeline publishes the allowlisted binaries
   as Release assets, verifies sizes and hashes, and commits the version catalog
   here. Only a newer final version advances `stable`.

For the versioning conventions, see [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
The channel-versus-pin pattern is also used by [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-kubectl-binary-with-curl-on-linux)
and the [.NET install scripts](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-install-script#options).
