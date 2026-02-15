#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  deploy-security-remote.sh — Ejecuta el hardening en el servidor remoto
#
#  Este script se ejecuta desde tu máquina LOCAL y:
#  1. Copia los scripts de seguridad al servidor
#  2. Ejecuta el hardening en el servidor vía SSH
#  3. Muestra el resultado
#
#  Uso desde tu máquina local:
#    bash security/deploy-security-remote.sh
# ============================================================

# Configuración del servidor
SERVER_USER="ubuntu"
SERVER_IP="141.253.197.178"
SSH_KEY="$HOME/ssh_drumalv_server/ssh-key-2026-02-14.key"
REMOTE_DIR="/home/ubuntu/openclaw-server"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔒 OpenClaw Remote Security Hardening"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Servidor: ${SERVER_USER}@${SERVER_IP}"
echo "SSH Key: ${SSH_KEY}"
echo ""

# Verificar que la clave SSH existe
if [[ ! -f "$SSH_KEY" ]]; then
    echo -e "${RED}❌ No se encontró la clave SSH en: $SSH_KEY${NC}"
    echo ""
    echo "Edita este script y ajusta la variable SSH_KEY con la ruta correcta."
    exit 1
fi

# Verificar conexión al servidor
echo "🔍 Verificando conexión al servidor..."
if ! ssh -i "$SSH_KEY" -o ConnectTimeout=5 "${SERVER_USER}@${SERVER_IP}" "echo '✓ Conexión OK'" 2>/dev/null; then
    echo -e "${RED}❌ No se pudo conectar al servidor${NC}"
    echo ""
    echo "Verifica que:"
    echo "  1. El servidor está encendido"
    echo "  2. La IP es correcta: $SERVER_IP"
    echo "  3. La clave SSH es correcta: $SSH_KEY"
    exit 1
fi

echo -e "${GREEN}✓ Conexión establecida${NC}"
echo ""

# Confirmar ejecución
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}⚠️  ADVERTENCIA${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Este script ejecutará el hardening de seguridad en el servidor:"
echo ""
echo "  • UFW Firewall (bloqueará puertos)"
echo "  • SSH Hardening (deshabilitará contraseñas)"
echo "  • Fail2Ban (protección contra fuerza bruta)"
echo "  • Tailscale VPN (acceso privado)"
echo "  • Auto-updates (actualización diaria)"
echo ""
read -p "Continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy]([Ee][Ss])?$ ]]; then
    echo -e "${RED}Abortado por el usuario${NC}"
    exit 1
fi

echo ""
echo "📦 Sincronizando archivos con el servidor..."

# Crear directorio en el servidor si no existe
ssh -i "$SSH_KEY" "${SERVER_USER}@${SERVER_IP}" "mkdir -p ${REMOTE_DIR}/security"

# Copiar scripts de seguridad al servidor
echo "  → Copiando scripts de seguridad..."
scp -i "$SSH_KEY" security/*.sh "${SERVER_USER}@${SERVER_IP}:${REMOTE_DIR}/security/" 2>/dev/null

# Dar permisos de ejecución
ssh -i "$SSH_KEY" "${SERVER_USER}@${SERVER_IP}" "chmod +x ${REMOTE_DIR}/security/*.sh"

echo -e "${GREEN}✓ Archivos sincronizados${NC}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Ejecutando hardening en el servidor..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "La sesión SSH se abrirá en modo interactivo."
echo "Sigue las instrucciones del script en el servidor."
echo ""
read -p "Presiona ENTER para conectar..."

# Ejecutar el script de hardening en el servidor (sesión interactiva)
ssh -i "$SSH_KEY" -t "${SERVER_USER}@${SERVER_IP}" "cd ${REMOTE_DIR} && sudo bash security/deploy-security.sh"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Hardening completado${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📖 Próximos pasos:"
echo ""
echo "1. Instala Tailscale en tu PC:"
echo "   https://tailscale.com/download"
echo ""
echo "2. Inicia sesión con la misma cuenta Tailscale que usaste en el servidor"
echo ""
echo "3. Obtén la IP de Tailscale del servidor:"
echo "   ssh -i $SSH_KEY ${SERVER_USER}@${SERVER_IP} 'tailscale ip -4'"
echo ""
echo "4. Accede al dashboard de OpenClaw:"
echo "   ssh -i $SSH_KEY ${SERVER_USER}@${SERVER_IP} \\"
echo "     'sudo kubectl port-forward svc/openclaw 18789:18789 -n openclaw --address=\$(tailscale ip -4)'"
echo ""
echo "   Luego abre: http://<TAILSCALE-IP>:18789"
echo ""
