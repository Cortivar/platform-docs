# Working with your local host

[Docs](../README.md) / Developer guide

After [installing and starting a workspace](../README.md#start-using-the-host),
run `cortivar service status`. You should see the host running and Knowledge
under host management. These examples use the full host install.

## Run your first job

Register the built-in Requirements preview. It reads local fixtures and prints
a JSON brief, so it makes a useful first job without connecting an external account.
Use an absolute executable path: the job runs in the worker, not your interactive shell.

**macOS / Linux**

```sh
cortivar jobs add brief -- "$HOME/.local/bin/cortivar" requirements preview
```

**Windows PowerShell**

```powershell
cortivar jobs add brief -- "$env:LOCALAPPDATA\Cortivar\bin\cortivar.exe" requirements preview
```

**On any target**

```text
cortivar jobs run brief
cortivar jobs list
```

Look for `succeeded` next to the run. `cortivar jobs log RUN_ID` prints its log
path (replace `RUN_ID` with the number from the list). To run it hourly, use
`cortivar jobs schedule brief 3600`; use `0` instead of `3600` to disable the
interval. To cancel a queued or running job, use `cortivar jobs cancel RUN_ID`.

## Connect an agent

1. Sign in to **Console → Knowledge** as the workspace owner. Create a
   repository record, for example `importer`, and publish a page named
   **Import schedule** explaining why nightly imports use UTC.
2. Map its folder to the repository. Grant the configured agent read access
   to **both** the repository and the page group. The mapping does not grant
   access by itself.
3. Configure the agent client to launch a **stdio MCP server**. On a bundled
   host ZIP, choose the absolute path of the installed `cortivar`
   executable with `mcp` as its one argument. On the legacy Linux x64 script host, choose the installed
   `meltemia` workspace executable with the same argument. The launcher supplies
   the local agent credential. Don't put the human sign-in token in this config.
4. Ask: “Retrieve guidance for `importer`. Why do nightly imports use UTC?
   Cite the page and version.” If retrieval is empty, recheck the mapping
   and read grants before editing the note.

## Service commands

| Command | Effect |
| --- | --- |
| `cortivar` | Open the terminal Tool Desk |
| `cortivar console` | Serve the local browser GUI and print a fresh private link |
| `cortivar service status` | Show host and Knowledge status |
| `cortivar service start` / `stop` | Start or stop the user worker now |
| `cortivar service restart` | Restart the registered worker; queued jobs and schedules persist |
| `cortivar service enable` / `disable` | Start now and at login, or stop and turn off autostart |

## Upgrade the TUI and service in place

For an existing **bundled host** (including Linux x64 on `v0.0.2`), run the
full installer under the same user account. It updates Tool Desk and the host
worker together. Your workspace, credentials, schedules and run history stay
in place. You don't need to uninstall or initialize another workspace.

Check [latest stable](../channels/stable) first. If you're already on that
version, there's nothing to upgrade. `v0.0.2` has no `cortivar update`
command; changes on the source branch become installable when released.

On **Linux or macOS with a running registered service**, let active jobs
finish, then close Tool Desk and the console. From your shell:

```sh
cortivar service stop &&
  (script=$(mktemp) || exit 1; trap 'rm -f "$script"' EXIT
   curl -fsSL https://cortivar.com/get.sh -o "$script" && sh "$script") &&
  cortivar service start &&
  cortivar service status
```

For a host you haven't started, just run the full installer. Use the default
host role, not `--role launcher`, to update the worker too. To select an exact
release instead, pass `--version vX.Y.Z` to the script. If setup fails, check
its message before starting the service again; don't remove your data.
The old [Linux x64 Docker layout](packages.md#existing-linux-x64-hosts) is
a separate case and cannot be converted by this procedure.

## Uninstall a tool or the app

Check `cortivar --help` first. **The v0.0.1 and v0.0.2 releases do not include
the uninstall command.** On a legacy Linux x64 host, keep the old workspace
intact if you still need its shared HTTPS service or data; see [Existing Linux
x64 hosts](packages.md#existing-linux-x64-hosts).

In builds that list `uninstall`, choose **Manage installed tools / uninstall
Cortivar** in Tool Desk, or run the command for the tool you want:

| Command | What happens |
| --- | --- |
| `cortivar uninstall knowledge` | Removes Knowledge; keeps its database and credentials. |
| `cortivar uninstall workflows` | Stops job execution; keeps the queue, schedules and history. |
| `cortivar uninstall requirements` | Removes the preview; other tools remain available. |
| `cortivar uninstall all --dry-run` | Lists the paths and service action without changing them. |
| `cortivar uninstall all` | Retires this account’s app and login service and prints the private recovery directory. |

`cortivar install TOOL` restores an individual tool from its local cache. Before
retiring the app, close the console and foreground workers. The recovery copy
keeps local files under their original home-relative paths. External services
and Docker volumes are not included or deleted.

## Troubleshooting

- **Command not found:** use the executable path printed at install.
  On macOS/Linux run `~/.local/bin/cortivar` or add `~/.local/bin` to `PATH`.
  On Windows reopen PowerShell, or run `& "$env:LOCALAPPDATA\Cortivar\bin\cortivar.exe"`.
- **No stable release / unknown version:** check [Releases](https://github.com/Cortivar/platform-docs/releases)
  and [`channels/stable`](../channels/stable). Use a published tag, not a branch name,
  partial version or commit. A failed checksum is an install failure; get the
  matching files from the release rather than mixing versions.
- **Knowledge asks for a token:** use the `human-token` file identified by setup.
  The console session is for service management and does not sign you in to Knowledge.
- **Switching versions:** close the console and Tool Desk, then stop the service
  before installing another host ZIP. Back up the private workspace directory
  with the database stopped. An exact version pin selects binaries; it does
  not revert database contents or grants.
