#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  setup-tailscale.sh — Instala Tailscale para acceso VPN seguro
#
#  Ejecutar como root en el HOST:
#    sudo bash security/setup-tailscale.sh
#
#  Después de ejecutar, instala Tailscale en tu PC/móvil
#  para acceder al dashboard de OpenClaw sin abrir puertos.
# ============================================================

echo "🌐 Instalando Tailscale..."

# Instalar Tailscale
if ! command -v tailscale &>/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
else
  echo "  → Tailscale ya está instalado."
fi

# Iniciar Tailscale
echo ""
echo "  → Iniciando Tailscale..."
tailscale up

echo ""
echo "✅ Tailscale instalado y conectado."
echo ""
echo "📋 Tu IP de Tailscale:"
tailscale ip -4
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📖 Pasos siguientes:"
echo ""
echo "1. Instala Tailscale en tu ordenador/móvil:"
echo "   → https://tailscale.com/download"
echo ""
echo "2. Para acceder al dashboard de OpenClaw, usa port-forward:"
echo "   sudo kubectl port-forward svc/openclaw 18789:18789 \\"
echo "     -n openclaw --address=\$(tailscale ip -4)"
echo ""
echo "3. Abre en tu navegador:"
echo "   http://<TU-IP-TAILSCALE>:18789"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Para acceso permanente, crea un servicio systemd con"
echo "   el port-forward. Ver README.md para instrucciones."
