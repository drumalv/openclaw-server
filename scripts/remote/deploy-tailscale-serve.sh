#!/usr/bin/env bash
# ============================================================
# deploy-tailscale-serve.sh — Desplegar Tailscale Serve HTTPS en el servidor
#
# Variables de entorno requeridas:
#   OPENCLAW_SERVER_IP   - IP del servidor remoto
#   OPENCLAW_SSH_KEY     - Ruta a la clave SSH privada
#
# Variables opcionales:
#   OPENCLAW_SERVER_USER - Usuario SSH (default: ubuntu)
#
# Uso:
#   export OPENCLAW_SERVER_IP="141.253.197.178"
#   export OPENCLAW_SSH_KEY="$HOME/.ssh/id_rsa"
#   bash deploy-tailscale-serve.sh
# ============================================================

SERVER_USER="${OPENCLAW_SERVER_USER:-ubuntu}"
SERVER_IP="${OPENCLAW_SERVER_IP:-}"
SSH_KEY="${OPENCLAW_SSH_KEY:-}"

# Validación
if [[ -z "$SERVER_IP" ]] || [[ -z "$SSH_KEY" ]]; then
    echo "❌ Error: Debes configurar OPENCLAW_SERVER_IP y OPENCLAW_SSH_KEY"
    echo "Ejemplo:"
    echo "  export OPENCLAW_SERVER_IP=\"141.253.197.178\""
    echo "  export OPENCLAW_SSH_KEY=\"\$HOME/.ssh/id_rsa\""
    exit 1
fi

echo "📦 Sincronizando archivos con el servidor..."
scp -i "$SSH_KEY" \
  scripts/services/tailscale-serve/install.sh \
  scripts/services/tailscale-serve/install-service.sh \
  scripts/services/tailscale-serve/openclaw-localhost-forward.service \
  ${SERVER_USER}@${SERVER_IP}:~/openclaw-server/scripts/services/tailscale-serve/

echo ""
echo "🚀 Configurando Tailscale Serve en el servidor..."
echo ""

ssh -i "$SSH_KEY" ${SERVER_USER}@${SERVER_IP} <<'EOF'
cd openclaw-server

echo "Paso 1: Configurar Tailscale Serve"
sudo bash scripts/services/tailscale-serve/install.sh

echo ""
echo "Paso 2: Instalar servicio permanente"
sudo bash scripts/services/tailscale-serve/install-service.sh

echo ""
echo "✅ Configuración completada"
echo ""
echo "📋 Tu dashboard está disponible en:"
TAILSCALE_DOMAIN=$(tailscale status --json 2>/dev/null | grep -o '"DNSName":"[^"]*"' | cut -d'"' -f4 | head -n1 | sed 's/\.$//' || echo "tu-dominio-tailscale")
echo "   https://$TAILSCALE_DOMAIN"
EOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Tailscale Serve HTTPS configurado"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
