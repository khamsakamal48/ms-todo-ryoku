# Microsoft To Do (Ryoku plugin)

Your Microsoft To Do tasks on the Ryoku bar. The glyph shows a count; click it
for every list, tick a task to complete it in Microsoft To Do (on every device),
click a ticked task to reopen it. A twin plugin, `ms-todo-desk`, shows the same
view as a tile on the wallpaper; both share one sign-in.

The bar glyph needs a bar style that hosts plugins (QS Bar). The desktop tile
works with any bar style.

## What it runs
Only the `mstodo` command (default `~/.local/bin/mstodo`, settable), with fixed
argv: `status`, `tasks [--lists …] [--completed]`, `login`, `logout`,
`done LIST TASK [--undo]`. Also `xdg-open` (sign-in page / To Do web) and
`wl-copy` (copy the sign-in code), only on a click.

## What it reads and writes
The plugin itself writes nothing. `mstodo` keeps its own files:
- `~/.config/mstodo/config.json`: Entra app client id and tenant
- `~/.local/state/mstodo/token.json`: refresh token, mode 0600
- `~/.cache/mstodo/tasks.json`: last good task list, shown when offline

## Network
`mstodo` talks to `login.microsoftonline.com` (device-code sign-in) and
`graph.microsoft.com` (delegated `Tasks.ReadWrite`, `User.Read`). The panel's
open button goes to `to-do.office.com`.

## Setup
1. Install `mstodo` (see `../../mstodo/`, or run `../../install.sh`), then
   `mstodo setup --client-id <Entra app id> --tenant <tenant id>`.
   The Entra app must allow public client flows.
   Or leave mstodo unconfigured and paste the IDs in the plugin settings (Account).
2. `ryoku plugin add . --bar --yes`, open the panel, click **Sign in**, enter
   the code on the Microsoft page.

## Settings (QS Bar Settings > Community)
Lists to show, hide empty lists, show completed, badge counts
(open / due / high / none), appearance, accent, font, refresh interval, client ID, tenant ID, mstodo path.
