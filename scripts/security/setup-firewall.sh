#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  setup-firewall.sh — Configura UFW según tutorial OpenClaw
#
#  Ejecutar como root en el HOST (no dentro de K8s):
#    sudo bash security/setup-firewall.sh
# ============================================================

echo "🔥 Configurando firewall (UFW)..."

# Instalar UFW si no está presente
if ! command -v ufw &>/dev/null; then
  echo "  → Instalando UFW..."
  apt-get update -qq && apt-get install -y -qq ufw
fi

# Política por defecto: denegar todo entrante, permitir saliente
echo "  → Aplicando política: deny incoming, allow outgoing"
ufw default deny incoming
ufw default allow outgoing

# Permitir SSH (CRÍTICO: no bloquearte del servidor)
echo "  → Permitiendo SSH (puerto 22)"
ufw allow 22/tcp comment 'SSH'

# Permitir Tailscale (puerto WireGuard)
echo "  → Permitiendo Tailscale (puerto 41641/UDP)"
ufw allow 41641/udp comment 'Tailscale WireGuard'

# Permitir K3s API server (solo si se necesita acceso remoto con kubectl)
# IMPORTANTE: Solo descomentar si necesitas ejecutar kubectl desde otro equipo.
# Para uso local en el servidor, NO es necesario abrir este puerto.
# echo "  → Permitiendo K3s API (puerto 6443)"
# ufw allow 6443/tcp comment 'K3s API Server'


# NO se abre el puerto 30789 ni 18789 — el dashboard se accede SOLO vía Tailscale

# Activar el firewall
echo "  → Activando UFW..."
echo "y" | ufw enable

echo ""
echo "✅ Firewall configurado. Estado actual:"
ufw status verbose
echo ""
echo "⚠️  El dashboard de OpenClaw NO está expuesto públicamente."
echo "   Accede vía Tailscale: http://<TAILSCALE-IP>:18789"
