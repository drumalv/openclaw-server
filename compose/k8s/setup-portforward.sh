#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  setup-portforward.sh — Instala servicio systemd para port-forward
#
#  Este script instala un servicio systemd que mantiene el
#  port-forward de OpenClaw activo permanentemente en la IP
#  de Tailscale, permitiendo acceso al dashboard sin tener
#  que ejecutar kubectl port-forward manualmente.
#
#  Ejecutar como root en el servidor:
#    sudo bash compose/k8s/setup-portforward.sh
# ============================================================

SERVICE_FILE="openclaw-portforward.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_FILE"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🌐 Instalando servicio de port-forward permanente..."

# Verificar que Tailscale está instalado
if ! command -v tailscale &> /dev/null; then
    echo "❌ Error: Tailscale no está instalado."
    echo "   Ejecuta primero: sudo bash security/setup-tailscale.sh"
    exit 1
fi

# Verificar que K3s está instalado
if ! command -v k3s &> /dev/null; then
    echo "❌ Error: K3s no está instalado."
    exit 1
fi

# Crear directorio para el script wrapper
echo "  → Creando directorio /opt/openclaw"
mkdir -p /opt/openclaw

# Copiar el script wrapper
echo "  → Instalando script wrapper en /opt/openclaw/portforward-wrapper.sh"
cp "$SCRIPT_DIR/portforward-wrapper.sh" /opt/openclaw/portforward-wrapper.sh
chmod +x /opt/openclaw/portforward-wrapper.sh

# Copiar el archivo de servicio
echo "  → Copiando servicio a $SERVICE_PATH"
cp "$SCRIPT_DIR/$SERVICE_FILE" "$SERVICE_PATH"

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
echo "📖 El dashboard de OpenClaw ahora está accesible en:"
echo ""
echo "   http://$(tailscale ip -4):18789"
echo ""
echo "Accede desde tu PC con Tailscale instalado e iniciado"
echo "con la misma cuenta Tailscale del servidor."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Comandos útiles:"
echo "   sudo systemctl status openclaw-portforward  # Ver estado"
echo "   sudo systemctl restart openclaw-portforward # Reiniciar"
echo "   sudo systemctl stop openclaw-portforward    # Detener"
echo "   sudo journalctl -u openclaw-portforward -f  # Ver logs"
