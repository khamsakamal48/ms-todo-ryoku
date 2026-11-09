# Microsoft To Do, desktop tile (Ryoku plugin)

Your Microsoft To Do tasks as a tile on the wallpaper. Every list is shown;
tick a task to complete it in Microsoft To Do (on every device),
click a ticked task to reopen it. The twin plugin `ms-todo` puts the same view
on the bar; both share one sign-in.


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
2. `ryoku plugin add . --yes`, enable it on the desktop (Ryoku Settings > Add-ons), click **Sign in**, enter
   the code on the Microsoft page.

## Settings (right-click the tile, or Ryoku Settings > Add-ons)
Appearance (light / dark glass / theme), accent, font, translucency and blur
sliders, lists to show, hide empty lists, show completed, tile width, max list
height, refresh interval, client ID, tenant ID, mstodo path. Text fields
(lists, IDs, path) are edited in Ryoku Settings > Add-ons; the tile menu has
no keyboard.
