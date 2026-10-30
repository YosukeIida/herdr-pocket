#!/bin/sh
# Installs herdr-notify on a box over SSH: the same files the app's
# Settings → Notifications → "Set up on <box>" writes.
#
#   scripts/install-notifier.sh <ssh host> <AuthKey_XXXXXXXXXX.p8> <team id> <bundle id>
#
# Puts the APNs key, apns.json and the script in ~/.config/herdr-ios (mode 700,
# key 600), installs a systemd user service `herdr-notify`, and starts it.
set -eu

if [ $# -ne 4 ]; then
  echo "usage: $0 <ssh host> <AuthKey_XXXXXXXXXX.p8> <team id> <bundle id>" >&2
  exit 2
fi
host="$1"; key="$2"; team="$3"; bundle="$4"
keyid="$(basename "$key" | sed -n 's/^AuthKey_\([A-Z0-9]\{10\}\)\.p8$/\1/p')"
[ -n "$keyid" ] || { echo "can't read the key id from $(basename "$key") (want AuthKey_XXXXXXXXXX.p8)" >&2; exit 1; }
here="$(cd "$(dirname "$0")/.." && pwd)"

echo "→ key and config"
ssh "$host" 'd=$HOME/.config/herdr-ios; mkdir -p "$d/devices" && chmod 700 "$d" && umask 077 && cat > "$d/AuthKey.p8" && chmod 600 "$d/AuthKey.p8"' < "$key"
printf '{\n  "bundle_id": "%s",\n  "key_id": "%s",\n  "key_path": "~/.config/herdr-ios/AuthKey.p8",\n  "team_id": "%s"\n}\n' "$bundle" "$keyid" "$team" \
  | ssh "$host" 'umask 077; cat > "$HOME/.config/herdr-ios/apns.json"'

echo "→ script"
ssh "$host" 'cat > "$HOME/.config/herdr-ios/herdr-notify.py" && chmod 755 "$HOME/.config/herdr-ios/herdr-notify.py"' < "$here/App/Resources/Notify/herdr-notify.py"

echo "→ service"
ssh "$host" 'mkdir -p "$HOME/.config/systemd/user" && cat > "$HOME/.config/systemd/user/herdr-notify.service"' <<'EOF'
[Unit]
Description=Herdr for iOS push notifications
After=network-online.target

[Service]
ExecStart=/usr/bin/env python3 %h/.config/herdr-ios/herdr-notify.py
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF
ssh "$host" 'systemctl --user daemon-reload && systemctl --user enable herdr-notify >/dev/null 2>&1; systemctl --user restart herdr-notify; sleep 2; systemctl --user is-active herdr-notify && journalctl --user -u herdr-notify -n 3 --no-pager -o cat'
echo "done. Open Herdr on the phone (connected) and allow notifications; then Settings → Notifications → Send a test."
