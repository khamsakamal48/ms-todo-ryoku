#!/usr/bin/env bash
# Ryoku places a plugin on one host at a time, so the bar glyph and the desktop
# tile are two plugins with the same logic and view. plugins/ms-todo is the
# source of truth; this copies the shared files into plugins/ms-todo-desk.
# Run it after editing any of them (CI-style check: --check).
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="$root/plugins/ms-todo" dst="$root/plugins/ms-todo-desk"
shared=(service/Main.qml content/TaskView.qml content/TaskRow.qml content/Style.qml
	content/Glass.qml content/Icon.qml content/RoundIcon.qml content/Pill.qml
	content/Chip.qml content/Composer.qml)
status=0
for f in "${shared[@]}"; do
	if [ "${1:-}" = "--check" ]; then
		cmp -s "$src/$f" "$dst/$f" || { echo "out of sync: $f"; status=1; }
	else
		cp "$src/$f" "$dst/$f"
	fi
done
[ "${1:-}" = "--check" ] && { [ $status = 0 ] && echo "shared files in sync"; exit $status; }
echo "synced ${#shared[@]} files into plugins/ms-todo-desk"
