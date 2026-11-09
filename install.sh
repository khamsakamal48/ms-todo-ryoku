#!/usr/bin/env bash
# Install Microsoft To Do for Ryoku: the mstodo command and the bar and/or
# desktop plugins. Re-runnable; asks before changing anything it finds set.
#
#   ./install.sh                         interactive
#   ./install.sh --client-id ID --tenant T --desktop --bar --yes
#
# Flags: --client-id ID   Entra "Application (client) ID"
#        --tenant T       "Directory (tenant) ID", or organizations|consumers|common
#        --desktop        install the desktop tile   (default: ask)
#        --bar            install the bar glyph      (default: ask)
#        --yes            accept defaults, no prompts
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="${HOME}/.local/bin"
client_id="${MSTODO_CLIENT_ID:-}"
tenant="${MSTODO_TENANT:-}"
want_desk="" want_bar="" yes=0

while [ $# -gt 0 ]; do
	case "$1" in
	--client-id) client_id="${2:?}"; shift 2 ;;
	--tenant) tenant="${2:?}"; shift 2 ;;
	--desktop) want_desk=1; shift ;;
	--bar) want_bar=1; shift ;;
	--yes | -y) yes=1; shift ;;
	-h | --help) sed -n '2,13p' "$0"; exit 0 ;;
	*) echo "unknown option: $1" >&2; exit 2 ;;
	esac
done

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok() { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
die() { printf '  \033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }
ask() { # ask "question" default -> echoes answer
	local q="$1" d="${2:-}" a
	if [ "$yes" = 1 ]; then echo "$d"; return; fi
	read -r -p "  $q${d:+ [$d]}: " a </dev/tty
	echo "${a:-$d}"
}
yesno() { # yesno "question" default(y|n)
	local a; a="$(ask "$1 (y/n)" "$2")"
	[[ "$a" =~ ^[Yy] ]]
}

bold "Microsoft To Do for Ryoku"

# ---------------------------------------------------------------- prerequisites
command -v python3 >/dev/null || die "python3 is required"
command -v ryoku >/dev/null || die "this needs a Ryoku desktop (the 'ryoku' command was not found)"
for c in xdg-open wl-copy; do
	command -v "$c" >/dev/null || warn "$c not found: the Open page / Copy code buttons won't work"
done
fc-list : family | grep -qi '^Inter' || warn "Inter font not found; the tile falls back to the theme font (pacman -S inter-font)"
fc-list : family | grep -qi 'Material Symbols Rounded' || warn "Material Symbols Rounded not found; icons will be blank"
ok "prerequisites"

# ---------------------------------------------------------------- mstodo
mkdir -p "$bin_dir"
install -m 755 "$here/mstodo/mstodo" "$bin_dir/mstodo"
ok "installed mstodo to $bin_dir/mstodo"
case ":$PATH:" in *":$bin_dir:"*) ;; *) warn "$bin_dir is not on PATH (the plugins use the full path, so they still work)" ;; esac

# ---------------------------------------------------------------- app registration
status="$("$bin_dir/mstodo" status)"
configured=$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["configured"])' "$status")
if [ -z "$client_id" ] && [ "$configured" = "True" ] && [ "$yes" = 1 ]; then
	ok "mstodo is already configured"
else
	if [ "$configured" = "True" ] && [ -z "$client_id" ] && ! yesno "mstodo is already configured. Change the app registration?" n; then
		ok "keeping the existing app registration"
	else
		echo
		echo "  Microsoft only lets registered apps sign in. You need an Entra app registration"
		echo "  (two minutes, free; see README.md > 'Register the app'). From its Overview page:"
		[ -n "$client_id" ] || client_id="$(ask "Application (client) ID" "")"
		[ -n "$client_id" ] || die "a client ID is required"
		[[ "$client_id" =~ ^[0-9a-fA-F-]{36}$ ]] || warn "that doesn't look like a GUID; continuing anyway"
		[ -n "$tenant" ] || tenant="$(ask "Directory (tenant) ID, or organizations / consumers / common" "organizations")"
		"$bin_dir/mstodo" setup --client-id "$client_id" --tenant "$tenant" >/dev/null
		ok "saved to ~/.config/mstodo/config.json"
	fi
fi

# ---------------------------------------------------------------- plugins
installed="$(ryoku plugin list 2>/dev/null || true)"
install_plugin() { # id flags...
	local id="$1"; shift
	if grep -q "^$id " <<<"$installed"; then
		warn "$id is already installed; to update it run: ryoku plugin remove $id && ./install.sh (this resets its settings)"
		return
	fi
	ryoku plugin validate "$here/plugins/$id" >/dev/null || die "$id failed validation"
	ryoku plugin add "$here/plugins/$id" "$@" --yes 2>&1 | grep -v '^RYOSTORE-PROGRESS' | sed 's/^/    /'
	ok "installed $id"
}

[ -n "$want_desk" ] || { yesno "Install the desktop tile?" y && want_desk=1 || want_desk=0; }
[ -n "$want_bar" ] || { yesno "Install the bar glyph? (needs a bar style that shows plugins, e.g. QS Bar)" n && want_bar=1 || want_bar=0; }

if [ "$want_desk" = 1 ]; then
	install_plugin ms-todo-desk
	place="$HOME/.config/quickshell/plugins/ryoku-plugins-place"
	if [ -x "$place" ]; then
		"$place" ms-todo-desk seed && "$place" ms-todo-desk host desktopWidget && "$place" ms-todo-desk enabled true
		ok "tile enabled on the desktop (drag it anywhere; right-click it for settings)"
	else
		warn "enable the tile in Ryoku Settings > Add-ons"
	fi
fi
[ "$want_bar" = 1 ] && install_plugin ms-todo --bar

echo
bold "Next"
echo "  Click 'Sign in' on the tile (or the bar panel), then 'Open page' and paste the code."
echo "  Settings: right-click the tile, or Ryoku Settings > Add-ons > Microsoft To Do."
