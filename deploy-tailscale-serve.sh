#!/usr/bin/env bash
# Desplegar Tailscale Serve HTTPS en el servidor

echo "📦 Sincronizando archivos con el servidor..."
scp -i ~/ssh_drumalv_server/ssh-key-2026-02-14.key \
  compose/k8s/setup-tailscale-serve.sh \
  compose/k8s/setup-tailscale-serve-service.sh \
  compose/k8s/openclaw-localhost-forward.service \
  ubuntu@141.253.197.178:~/openclaw-server/compose/k8s/

echo ""
echo "🚀 Configurando Tailscale Serve en el servidor..."
echo ""

ssh -i ~/ssh_drumalv_server/ssh-key-2026-02-14.key ubuntu@141.253.197.178 << 'EOF'
cd openclaw-server

echo "Paso 1: Configurar Tailscale Serve"
sudo bash compose/k8s/setup-tailscale-serve.sh

echo ""
echo "Paso 2: Instalar servicio permanente"
sudo bash compose/k8s/setup-tailscale-serve-service.sh

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
