#!/bin/sh
# Pairs a phone with this box for herdr-pocket, on top of herdr-core's own remote path
# (`ssh box herdr-core connect`): it makes an SSH key for the phone, authorizes it in
# ~/.ssh/authorized_keys for `herdr-core connect` only, and shows a QR code holding the key,
# this box's address and its host key. Scan it in the app (or paste the code). Nothing listens
# on the network and nothing keeps running.
#
#   scripts/pair.sh [host] [name]
#
# host: the address the phone uses (default: this box's Tailscale IPv4, else its hostname).
# name: a label for the key in authorized_keys (default: herdr-pocket-<date>).
# Unpair a phone by deleting its line from ~/.ssh/authorized_keys.
set -eu

host="${1:-$(tailscale ip -4 2>/dev/null | head -n 1 || true)}"
[ -n "$host" ] || host="$(hostname)"
name="${2:-herdr-pocket-$(date +%Y%m%d-%H%M%S)}"
user="$(id -un)"
port=22

core="$(command -v herdr-core || true)"
[ -n "$core" ] || core="$HOME/.local/bin/herdr-core"
[ -x "$core" ] || { echo "herdr-core is not installed here" >&2; exit 1; }
case "$core" in *[!A-Za-z0-9/._-]*) echo "can't use herdr-core at $core (unusual characters in the path)" >&2; exit 1 ;; esac

hostkey="$(awk '{print $1" "$2}' /etc/ssh/ssh_host_ed25519_key.pub)"

if command -v qrencode >/dev/null 2>&1; then qr() { qrencode -t ansiutf8 -l M; }
elif command -v nix >/dev/null 2>&1; then qr() { nix run nixpkgs#qrencode -- -t ansiutf8 -l M; }
else echo "needs qrencode (or nix) to draw the QR code" >&2; exit 1; fi

dir="$(mktemp -d)"
trap 'rm -f "$dir/key" "$dir/key.pub"; rmdir "$dir"' EXIT
ssh-keygen -q -t ed25519 -N "" -C "$name" -f "$dir/key"

mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
# restrict: no forwarding, agent or pty; command=: the key can only start herdr-core connect.
printf 'restrict,command="%s connect" %s\n' "$core" "$(cat "$dir/key.pub")" >> "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"

json() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | awk 'BEGIN{ORS="\\n"} {print}' | sed 's/\\n$//'; }
payload="{\"v\":1,\"host\":\"$(json "$host")\",\"port\":$port,\"user\":\"$(json "$user")\",\"hostKey\":\"$(json "$hostkey")\",\"key\":\"$(json "$(cat "$dir/key")")\"}"
code="herdr-pair:$(printf '%s' "$payload" | base64 | tr -d '\n=' | tr '+/' '-_')"

if [ "${HERDR_PAIR_PRINT:-}" = 1 ]; then printf '%s\n' "$code"; exit 0; fi

printf '%s' "$code" | qr
echo "Scan this in herdr-pocket (Add machine → Scan pairing code) to reach $user@$host."
echo "Authorized as \"$name\" in ~/.ssh/authorized_keys. Anyone who photographs this code can connect;"
printf 'press Enter when the phone is paired to clear the screen. '
read -r _ || true
clear 2>/dev/null || printf '\033[2J\033[H'
