#!/bin/sh
# Runs herdr-notify as a service on the box: a launchd agent on macOS, a systemd
# user service on Linux, nohup where neither is available. Used by the app's
# Settings → Notifications and by scripts/install-notifier.sh.
set -eu
d="$HOME/.config/herdr-ios"
script="$d/herdr-notify.py"
py="$(command -v python3)"

# XML text for a plist <string>.
xml() { printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }
# A quoted word in a systemd unit: backslashes and quotes escaped, % doubled.
unit() { printf "%s" "$1" | sed -e "s/\\\\/\\\\\\\\/g" -e "s/\"/\\\\\"/g" -e "s/%/%%/g"; }

if [ "$(uname)" = Darwin ]; then
  label=dev.herdr.notify
  plist="$HOME/Library/LaunchAgents/$label.plist"
  mkdir -p "$HOME/Library/LaunchAgents"
  # launchd starts jobs with PATH=/usr/bin:/bin:/usr/sbin:/sbin; keep the PATH that found hc and python3 here.
  tmp="$plist.new"
  cat > "$tmp" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key><array><string>$(xml "$py")</string><string>$(xml "$script")</string></array>
  <key>EnvironmentVariables</key><dict><key>PATH</key><string>$(xml "$PATH")</string></dict>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ThrottleInterval</key><integer>10</integer>
  <key>StandardOutPath</key><string>$(xml "$d/notify.log")</string>
  <key>StandardErrorPath</key><string>$(xml "$d/notify.log")</string>
</dict>
</plist>
EOF
  # A broken plist must not stop the running notifier.
  plutil -lint -s "$tmp"
  mv "$tmp" "$plist"
  pkill -f "$script" 2>/dev/null || true
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$plist"
elif systemctl --user show-environment >/dev/null 2>&1; then
  mkdir -p "$HOME/.config/systemd/user"
  cat > "$HOME/.config/systemd/user/herdr-notify.service" <<EOF
[Unit]
Description=Herdr for iOS push notifications
After=network-online.target

[Service]
ExecStart="$(unit "$py")" "%h/.config/herdr-ios/herdr-notify.py"
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF
  systemctl --user daemon-reload
  systemctl --user enable herdr-notify >/dev/null 2>&1 || true
  systemctl --user restart herdr-notify
else
  pkill -f "$script" 2>/dev/null || true
  nohup "$py" "$script" >"$d/notify.log" 2>&1 &
fi
