#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  deploy-security.sh — Despliega todas las medidas de seguridad
#
#  Ejecuta los scripts de hardening en el orden recomendado:
#  1. Tailscale (primero para tener VPN antes de bloquear puertos)
#  2. UFW Firewall
#  3. Fail2Ban
#  4. SSH Hardening (último por ser el más crítico)
#  5. Auto-Update (cron diario)
#  6. Port-Forward Permanente (opcional)
#
#  Uso:
#    sudo bash security/deploy-security.sh
# ============================================================

SECURITY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔒 OpenClaw Security Hardening — Master Deployment Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verificar que se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Este script debe ejecutarse como root (sudo)${NC}"
   exit 1
fi

# Función para pausar y pedir confirmación
confirm() {
    local message="$1"
    echo ""
    echo -e "${YELLOW}⚠️  $message${NC}"
    read -p "Continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy]([Ee][Ss])?$ ]]; then
        echo -e "${RED}Abortado por el usuario${NC}"
        exit 1
    fi
}

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" &> /dev/null
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Pre-verificaciones"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Verificar conexión a internet
if ! ping -c 1 8.8.8.8 &> /dev/null; then
    echo -e "${RED}❌ No hay conexión a internet${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Conexión a internet OK${NC}"

# Verificar claves SSH autorizadas
SSH_KEY_FOUND=false
for user_home in /root /home/*; do
    if [[ -f "$user_home/.ssh/authorized_keys" ]]; then
        SSH_KEY_FOUND=true
        echo -e "${GREEN}✓ Clave SSH encontrada en $user_home/.ssh/authorized_keys${NC}"
        break
    fi
done

if [[ "$SSH_KEY_FOUND" = false ]]; then
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ ADVERTENCIA CRÍTICA${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}No se encontró ninguna clave SSH autorizada.${NC}"
    echo ""
    echo "El script de SSH hardening deshabilitará la autenticación por contraseña."
    echo "Si continúas SIN una clave SSH configurada, PERDERÁS el acceso al servidor."
    echo ""
    echo "Configura tu clave primero con:"
    echo "  ssh-copy-id usuario@servidor"
    echo ""
    confirm "Are you SURE you want to continue without SSH key?"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Paso 1/5: Tailscale VPN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command_exists tailscale && tailscale status &> /dev/null; then
    echo -e "${GREEN}✓ Tailscale ya está instalado y conectado${NC}"
    tailscale ip -4
else
    confirm "Instalar y configurar Tailscale VPN"
    bash "$SECURITY_DIR/setup-tailscale.sh"
    
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  ACCIÓN REQUERIDA${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Tailscale necesita que autorices este dispositivo:"
    echo "1. Copia el enlace que apareció arriba"
    echo "2. Ábrelo en tu navegador e inicia sesión"
    echo "3. Instala Tailscale en tu PC/móvil: https://tailscale.com/download"
    echo ""
    read -p "Presiona ENTER cuando hayas completado la autorización..."
    
    # Verificar que Tailscale está conectado
    if ! tailscale status &> /dev/null; then
        echo -e "${RED}❌ Tailscale no está conectado. Abortando.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Tailscale conectado correctamente${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔥 Paso 2/5: UFW Firewall"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command_exists ufw && ufw status | grep -q "Status: active"; then
    echo -e "${GREEN}✓ UFW ya está activo${NC}"
    ufw status verbose
else
    confirm "Configurar firewall UFW (bloqueará todos los puertos excepto SSH, Tailscale y K3s)"
    bash "$SECURITY_DIR/setup-firewall.sh"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🛡️  Paso 3/5: Fail2Ban"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if systemctl is-active --quiet fail2ban; then
    echo -e "${GREEN}✓ Fail2Ban ya está activo${NC}"
    fail2ban-client status sshd
else
    confirm "Instalar Fail2Ban (baneará IPs tras 3 intentos fallidos de SSH)"
    bash "$SECURITY_DIR/setup-fail2ban.sh"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔑 Paso 4/5: SSH Hardening"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verificar configuración actual
CURRENT_PASSWORD_AUTH=$(sshd -T 2>/dev/null | grep "^passwordauthentication" | awk '{print $2}')

if [[ "$CURRENT_PASSWORD_AUTH" == "no" ]]; then
    echo -e "${GREEN}✓ SSH hardening ya está configurado${NC}"
    sshd -T | grep -E "passwordauthentication|pubkeyauthentication|permitrootlogin"
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}⚠️  PASO CRÍTICO - Lee con atención${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Este paso deshabilitará la autenticación SSH por contraseña."
    echo "Solo podrás conectar con tu clave SSH privada."
    echo ""
    echo "ANTES de continuar:"
    echo "  1. Abre una SEGUNDA terminal"
    echo "  2. Prueba conectar por SSH con tu clave"
    echo "  3. Si funciona, vuelve aquí y continúa"
    echo "  4. Si NO funciona, cancela (Ctrl+C) y configura tu clave primero"
    echo ""
    echo "Si tuvieras un problema, puedes acceder vía Tailscale SSH como backup."
    echo ""
    confirm "He verificado que puedo conectar por SSH con mi clave y quiero continuar"
    bash "$SECURITY_DIR/setup-ssh.sh"
    
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  VERIFICA AHORA${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "En tu SEGUNDA terminal, cierra la sesión SSH e intenta reconectar."
    echo "Debe funcionar SOLO con tu clave, sin pedir contraseña."
    echo ""
    read -p "Presiona ENTER cuando hayas verificado que el SSH funciona..."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 Paso 5/5: Auto-Update Diario"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

AUTO_UPDATE_SCRIPT="$SECURITY_DIR/../services/auto-update/install.sh"
if [[ -x /etc/cron.daily/openclaw-update ]]; then
    echo -e "${GREEN}✓ Cron de auto-update ya está instalado${NC}"
else
    confirm "Instalar tarea cron para actualización diaria de OpenClaw"
    cp "$AUTO_UPDATE_SCRIPT" /etc/cron.daily/openclaw-update
    chmod +x /etc/cron.daily/openclaw-update
    echo -e "${GREEN}✓ Auto-update instalado en /etc/cron.daily/openclaw-update${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Paso 6/6: Port-Forward Permanente (Opcional)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if systemctl is-active --quiet openclaw-portforward; then
    echo -e "${GREEN}✓ Servicio de port-forward ya está activo${NC}"
else
    echo "Este servicio mantiene el dashboard accesible automáticamente"
    echo "en http://$(tailscale ip -4 2>/dev/null || echo '<TAILSCALE-IP>'):18789"
    echo ""
    confirm "Instalar servicio de port-forward permanente (recomendado)"
    bash "$SECURITY_DIR/../services/portforward/install.sh" || echo "⚠️  Port-forward manual: kubectl port-forward svc/openclaw 18789:18789 -n openclaw --address=\$(tailscale ip -4)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ HARDENING COMPLETADO${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Resumen de seguridad:"
echo ""

# UFW
echo "🔥 Firewall UFW:"
ufw status verbose | head -n 10
echo ""

# SSH
echo "🔑 SSH Configuration:"
sshd -T 2>/dev/null | grep -E "passwordauthentication|pubkeyauthentication|permitrootlogin"
echo ""

# Fail2Ban
echo "🛡️  Fail2Ban:"
if systemctl is-active --quiet fail2ban; then
    fail2ban-client status sshd | head -n 5
else
    echo "  No instalado"
fi
echo ""

# Tailscale
echo "🌐 Tailscale:"
if command_exists tailscale; then
    echo "  IP privada: $(tailscale ip -4 2>/dev/null || echo 'No conectado')"
else
    echo "  No instalado"
fi
echo ""

# Auto-update
echo "🔄 Auto-update:"
if [[ -x /etc/cron.daily/openclaw-update ]]; then
    echo "  ✓ Instalado (se ejecuta diariamente ~4AM)"
else
    echo "  No instalado"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📖 Próximos pasos:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Instalar Tailscale en tu PC/móvil:"
echo "   https://tailscale.com/download"
echo ""
echo "2. Acceder al dashboard de OpenClaw:"
echo ""
if systemctl is-active --quiet openclaw-portforward 2>/dev/null; then
    echo "   El dashboard ya está accesible en:"
    echo "   http://\$(tailscale ip -4):18789"
else
    echo "   Opción A (recomendada): Port-forward permanente"
    echo "   sudo bash compose/k8s/setup-portforward.sh"
    echo ""
    echo "   Opción B: Port-forward manual"
    echo "   sudo kubectl port-forward svc/openclaw 18789:18789 \\"
    echo "     -n openclaw --address=\$(tailscale ip -4)"
fi
echo ""
echo "3. Si necesitas generar un token de acceso:"
echo ""
echo "   sudo kubectl exec deployment/openclaw -n openclaw -- openclaw auth token"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

