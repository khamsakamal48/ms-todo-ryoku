#!/usr/bin/env bash
# Regenerate assets/preview-widget.png (+ -dark) for both plugins from the real
# TaskView with dummy tasks. Needs qt6-declarative (the `qml` tool), Inter and
# Material Symbols Rounded. Renders in a short-lived window, then quits.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$here/../.."
out="$(mktemp -d)"
QML_IMPORT_PATH="$here/stub" "${QML:-qml6}" "$here/Preview.qml" -- "$out"
for p in ms-todo ms-todo-desk; do
	mkdir -p "$root/plugins/$p/assets"
	cp "$out"/preview-widget*.png "$root/plugins/$p/assets/"
done
rm -rf "$out"
echo "wrote plugins/*/assets/preview-widget{,-dark}.png"
