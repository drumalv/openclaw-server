#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  setup-tailscale-serve-service.sh — Instala servicio permanente
#
#  Este script instala un servicio systemd que mantiene el
#  port-forward local activo, necesario para Tailscale Serve.
#
#  Ejecutar como root en el servidor:
#    sudo bash compose/k8s/setup-tailscale-serve-service.sh
# ============================================================

SERVICE_FILE="openclaw-localhost-forward.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_FILE"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔧 Instalando servicio de port-forward local para Tailscale Serve..."

# Verificar que Tailscale Serve está configurado
if ! tailscale serve status &> /dev/null; then
    echo "⚠️  Advertencia: Tailscale Serve no parece estar configurado."
    echo "   Ejecuta primero: sudo bash compose/k8s/setup-tailscale-serve.sh"
    read -p "¿Continuar de todos modos? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy]([Ee][Ss])?$ ]]; then
        exit 1
    fi
fi

# Copiar el archivo de servicio
echo "  → Copiando servicio a $SERVICE_PATH"
cp "$SCRIPT_DIR/openclaw-localhost-forward.service" "$SERVICE_PATH"

# Recargar systemd
echo "  → Recargando systemd..."
systemctl daemon-reload

# Habilitar el servicio
echo "  → Habilitando servicio..."
systemctl enable $SERVICE_FILE

# Iniciar el servicio
echo "  → Iniciando servicio..."
systemctl start $SERVICE_FILE

echo ""
echo "✅ Servicio instalado y activo"
echo ""
echo "📊 Estado del servicio:"
systemctl status $SERVICE_FILE --no-pager | head -n 10
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📖 Dashboard accesible vía Tailscale Serve (HTTPS):"
echo ""
TAILSCALE_DOMAIN=$(tailscale status --json 2>/dev/null | grep -o '"DNSName":"[^"]*"' | cut -d'"' -f4 | head -n1 | sed 's/\.$//' || echo "<tailscale-domain>")
echo "   https://$TAILSCALE_DOMAIN"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Comandos útiles:"
echo "   sudo systemctl status openclaw-localhost-forward  # Ver estado"
echo "   sudo systemctl restart openclaw-localhost-forward # Reiniciar"
echo "   sudo journalctl -u openclaw-localhost-forward -f  # Ver logs"
echo "   tailscale serve status                            # Ver Tailscale Serve"
