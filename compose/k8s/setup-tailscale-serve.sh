#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  setup-tailscale-serve.sh — Configura Tailscale Serve con HTTPS
#
#  Tailscale Serve expone servicios locales con HTTPS automático,
#  evitando el problema de "control ui requires HTTPS or localhost".
#
#  Ejecutar como root en el servidor:
#    sudo bash compose/k8s/setup-tailscale-serve.sh
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔒 Configurando Tailscale Serve (HTTPS automático)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verificar que Tailscale está instalado y conectado
if ! command -v tailscale &> /dev/null; then
    echo "❌ Error: Tailscale no está instalado."
    echo "   Ejecuta primero: sudo bash security/setup-tailscale.sh"
    exit 1
fi

if ! tailscale status &> /dev/null; then
    echo "❌ Error: Tailscale no está conectado."
    echo "   Ejecuta: sudo tailscale up"
    exit 1
fi

# Obtener el hostname de Tailscale
TAILSCALE_HOSTNAME=$(tailscale status --json | grep -o '"HostName":"[^"]*"' | cut -d'"' -f4 | head -n1)
TAILSCALE_DOMAIN=$(tailscale status --json | grep -o '"DNSName":"[^"]*"' | cut -d'"' -f4 | head -n1 | sed 's/\.$//')

echo "📋 Información de Tailscale:"
echo "   Hostname: $TAILSCALE_HOSTNAME"
echo "   Dominio: $TAILSCALE_DOMAIN"
echo ""

# Verificar que el servicio K8s está activo
echo "🔍 Verificando servicio openclaw en K8s..."
if ! kubectl get svc openclaw -n openclaw &> /dev/null; then
    echo "❌ Error: Servicio 'openclaw' no encontrado en namespace 'openclaw'"
    echo "   Asegúrate de que OpenClaw está desplegado en K8s."
    exit 1
fi
echo -e "${GREEN}✓ Servicio encontrado${NC}"
echo ""

# Configurar Tailscale Serve para hacer proxy a localhost:18789
echo "🌐 Configurando Tailscale Serve..."
echo "   Esto creará un proxy HTTPS desde $TAILSCALE_DOMAIN a localhost:18789"
echo ""

# Primero crear un port-forward local en localhost (en background)
echo "  → Creando port-forward local a localhost:18789..."
kubectl port-forward svc/openclaw 18789:18789 -n openclaw --address=127.0.0.1 &>/dev/null &
PORT_FORWARD_PID=$!
sleep 2

# Verificar que el port-forward está activo
if ! lsof -i :18789 &> /dev/null; then
    echo "❌ Error: No se pudo crear port-forward en localhost:18789"
    exit 1
fi

echo -e "${GREEN}✓ Port-forward activo${NC}"
echo ""

# Configurar Tailscale Serve
echo "  → Configurando Tailscale Serve en puerto 443 (HTTPS)..."
tailscale serve https / http://localhost:18789

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Tailscale Serve configurado correctamente${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📖 Acceso al dashboard:"
echo ""
echo "   URL: https://$TAILSCALE_DOMAIN"
echo ""
echo "   Este enlace funciona desde cualquier dispositivo con"
echo "   Tailscale instalado e iniciado con la misma cuenta."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  IMPORTANTE:"
echo ""
echo "   El port-forward local (PID: $PORT_FORWARD_PID) está corriendo en background."
echo "   Para que Tailscale Serve funcione, este proceso debe estar siempre activo."
echo ""
echo "   Se recomienda instalar el servicio systemd permanente:"
echo "   sudo bash compose/k8s/setup-tailscale-serve-service.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Comandos útiles:"
echo "   tailscale serve status          # Ver configuración actual"
echo "   tailscale serve reset           # Resetear configuración"
echo "   tailscale funnel status         # Ver si funnel está activo"
