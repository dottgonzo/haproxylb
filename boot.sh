#!/bin/sh
set -e

CONFIG_PATH="${HAPROXY_CONFIG_PATH:-/tmp/haproxy.cfg}"

if [ -z "$BACKENDS" ]; then
  echo "ERROR: BACKENDS environment variable is required" >&2
  exit 1
fi

if [ -z "$SERVICES" ]; then
  echo "ERROR: SERVICES environment variable is required" >&2
  exit 1
fi

# Convert comma-separated lists to newline-separated
backends_list=$(echo "$BACKENDS" | tr ',' '\n')
services_list=$(echo "$SERVICES" | tr ',' '\n')

TIMEOUT_CONNECT="${TIMEOUT_CONNECT:-10000}"
TIMEOUT_CLIENT="${TIMEOUT_CLIENT:-900000}"
TIMEOUT_SERVER="${TIMEOUT_SERVER:-900000}"

# Write global and defaults sections
cat > "$CONFIG_PATH" << EOF
global
  tune.ssl.default-dh-param 2048

defaults
  log global
  mode http
  timeout connect ${TIMEOUT_CONNECT}
  timeout client ${TIMEOUT_CLIENT}
  timeout server ${TIMEOUT_SERVER}

EOF

# Generate frontend sections
echo "$services_list" | while IFS= read -r service; do
  port=$(echo "$service" | cut -d: -f1)
  mode=$(echo "$service" | cut -d: -f3)

  echo "frontend ${port}_front" >> "$CONFIG_PATH"
  echo "  bind *:${port}" >> "$CONFIG_PATH"
  [ "$mode" = "tcp" ] && echo "  option tcplog" >> "$CONFIG_PATH"
  echo "  mode ${mode}" >> "$CONFIG_PATH"
  echo "  use_backend ${port}_back" >> "$CONFIG_PATH"
  echo "" >> "$CONFIG_PATH"
done

# Generate backend sections
echo "$services_list" | while IFS= read -r service; do
  port=$(echo "$service" | cut -d: -f1)
  target_port=$(echo "$service" | cut -d: -f2)
  mode=$(echo "$service" | cut -d: -f3)
  options=$(echo "$service" | cut -d: -f4-)

  has_proxy_protocol=false
  case "$options" in
    *proxy_protocol*) has_proxy_protocol=true ;;
  esac

  echo "backend ${port}_back" >> "$CONFIG_PATH"
  echo "  balance roundrobin" >> "$CONFIG_PATH"
  echo "  mode ${mode}" >> "$CONFIG_PATH"
  [ "$mode" = "tcp" ] && echo "  option tcp-check" >> "$CONFIG_PATH"

  echo "$backends_list" | while IFS= read -r backend; do
    server_name=$(echo "$backend" | tr '.' '_')
    send_proxy=""
    if [ "$mode" != "tcp" ] && [ "$has_proxy_protocol" = "true" ]; then
      send_proxy=" send-proxy-v2"
    fi
    echo "  server ${server_name} ${backend}:${target_port}${send_proxy} check" >> "$CONFIG_PATH"
  done

  echo "" >> "$CONFIG_PATH"
done

echo "--- Generated HAProxy configuration ---"
cat "$CONFIG_PATH"
echo "--- Starting HAProxy ---"

exec haproxy -f "$CONFIG_PATH"
