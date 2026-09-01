#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../client"

# A phone on the same Wi-Fi cannot reach the server on `localhost` — that name
# means "this device", which from the phone is the phone. So the app has to be
# pointed at *this* machine's LAN address instead, which is what the
# API_BASE_URL override in `ApiClient.defaultBaseUrl` exists for.
#
# Auto-detected rather than hardcoded because a dev machine's address changes
# with DHCP, and a stale IP fails as a connection timeout on the phone with
# nothing on the server side to show why.
if [[ -z "${API_BASE_URL:-}" ]]; then
  for iface in en0 en1 en5; do
    if lan_ip=$(ipconfig getifaddr "$iface" 2>/dev/null) && [[ -n $lan_ip ]]; then
      API_BASE_URL="http://${lan_ip}:${PORT:-3000}"
      break
    fi
  done
fi

# Still empty means no LAN interface was up. Fall through to the built-in
# default (localhost, or 10.0.2.2 on Android) rather than guessing: that is
# correct for a desktop or emulator target, which is likely what is running.
if [[ -z "${API_BASE_URL:-}" ]]; then
  echo "start-client: no LAN address found, using the app's built-in default" >&2
  exec flutter run "$@"
fi

echo "start-client: API_BASE_URL=$API_BASE_URL"
exec flutter run --dart-define=API_BASE_URL="$API_BASE_URL" "$@"
