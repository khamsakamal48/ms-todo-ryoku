# Microsoft To Do for Ryoku

Your Microsoft To Do tasks on the [Ryoku](https://ryoku.sh) desktop: a frosted-glass
tile on the wallpaper and an optional bar glyph with a panel. Tick a task and it
is completed in Microsoft To Do on every device.

- **ms-todo-desk**: desktop tile. Translucency, blur, light/dark glass, accent, font.
- **ms-todo**: bar glyph with a count (open / due / high importance) and a panel.
- **mstodo**: a small Python command (standard library only) that signs in and talks
  to Microsoft Graph. Both plugins use it, so you sign in once.

> **Ryoku only.** These are Ryoku shell plugins: they use Ryoku's plugin host
> (`pluginApi`, the manifest, `ryoku plugin add`) and `Ryoku.PluginKit`. They
> won't load in other Quickshell configs as-is. `mstodo` itself works anywhere.

## Install

```bash
git clone <this repo> && cd ms-todo-ryoku
./install.sh
```

The installer checks prerequisites, installs `mstodo` to `~/.local/bin`, asks for
your app registration's **client ID** and **tenant ID**, and installs the tile
(and, if you want it, the bar glyph). Then click **Sign in** on the tile.

Non-interactive: `./install.sh --client-id <id> --tenant <id> --desktop --yes`.

## Register the app (once, about two minutes)

Microsoft only lets registered apps sign in, so you need your own (free) Entra
app registration. It holds no secret: it's a public client that signs in
**as you** and can only touch **your** tasks.

1. Open <https://entra.microsoft.com> › **App registrations** › **New registration**.
2. Name it (e.g. "To Do for Ryoku"). Pick the account type:
   - work/school account in your organisation only → *Single tenant*
   - personal Microsoft account (outlook.com) → *Personal Microsoft accounts only*
3. **Register**. From the Overview page copy the **Application (client) ID** and
   the **Directory (tenant) ID**.
4. **Authentication** › *Advanced settings* › **Allow public client flows: Yes** › Save.
   (Without this, sign-in fails with `AADSTS7000218`.)
5. **API permissions** › Add › Microsoft Graph › *Delegated* › `Tasks.ReadWrite`
   (`User.Read` is there by default). Users can consent themselves; no admin
   consent is needed in most tenants.

Tenant value: your Directory (tenant) ID for a single-tenant app, `consumers`
for personal accounts, `common` for an app that allows both.

You can change the IDs later in **Ryoku Settings › Add-ons › Microsoft To Do ›
Account** (settings there override `mstodo`'s config file), or with
`mstodo setup --client-id … --tenant …`.

## Settings

Right-click the tile, or Ryoku Settings › Add-ons:

| Setting | Tile | Bar |
| --- | --- | --- |
| Appearance: light glass / dark glass / follow theme | ✓ | ✓ |
| Accent: blue, theme, green, orange, purple, pink | ✓ | ✓ |
| Font: Inter, Google Sans Flex, theme | ✓ | ✓ |
| Translucency (0 = solid, 100 = clear) and Blur sliders | ✓ | |
| Tile width, max list height | ✓ | |
| Badge counts: open / due / high / none | | ✓ |
| Lists to show, hide empty lists, show completed, refresh interval | ✓ | ✓ |
| Client ID / tenant ID, mstodo path | ✓ | ✓ |

Ryoku's own **Opacity** in the tile menu fades the whole tile, text included.
**Translucency** only changes the glass behind the text.

Outlook's *Flagged Emails* list is skipped unless you name it in *Lists to show*.

## Privacy and files

- `~/.config/mstodo/config.json`: client and tenant IDs
- `~/.local/state/mstodo/token.json`: refresh token (mode 0600)
- `~/.cache/mstodo/tasks.json`: the last good task list, shown when offline
- Network: `login.microsoftonline.com`, `graph.microsoft.com` only.
- The tile reads your wallpaper path (`$XDG_STATE_HOME/ryoku-wallpaper`) to
  draw the glass. Nothing is sent anywhere else.

Sign out with the ⇥ button on the tile (click twice), or `mstodo logout`.

## Develop

`plugins/ms-todo` is the source of truth for the shared files; after editing,
run `scripts/sync-shared.sh` (and `--check` before committing). Then
`ryoku plugin validate plugins/<id>`. To reinstall:
`ryoku plugin remove <id> && ryoku plugin add plugins/<id> --yes`. Note that
**remove** clears the plugin's settings and placement.

## License

MIT
