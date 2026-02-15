#!/usr/bin/env bash
set -euo pipefail

# Script wrapper para el servicio systemd de port-forward
# Obtiene la IP de Tailscale dinámicamente y ejecuta port-forward

TAILSCALE_IP=$(tailscale ip -4)

if [[ -z "$TAILSCALE_IP" ]]; then
    echo "Error: No se pudo obtener la IP de Tailscale"
    exit 1
fi

echo "Iniciando port-forward en $TAILSCALE_IP:18789"
exec /usr/local/bin/k3s kubectl port-forward svc/openclaw 18789:18789 \
  -n openclaw --address="$TAILSCALE_IP"
