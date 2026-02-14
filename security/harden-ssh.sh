#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  harden-ssh.sh — Hardening SSH según tutorial OpenClaw
#
#  Ejecutar como root en el HOST:
#    sudo bash security/harden-ssh.sh
#
#  ⚠️  ASEGÚRATE de tener tu clave pública SSH configurada
#     ANTES de ejecutar este script, o perderás acceso.
# ============================================================

SSHD_CONFIG="/etc/ssh/sshd_config"

echo "🔒 Hardening SSH..."

# Verificar que existe una clave pública autorizada
if [ ! -f "$HOME/.ssh/authorized_keys" ] && [ ! -f "/home/$(logname 2>/dev/null || echo ubuntu)/.ssh/authorized_keys" ]; then
  echo "❌ ERROR: No se encontró authorized_keys."
  echo "   Configura tu clave pública SSH antes de ejecutar este script."
  echo "   Ejemplo: ssh-copy-id usuario@servidor"
  exit 1
fi

# Backup del archivo de configuración
cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
echo "  → Backup creado en ${SSHD_CONFIG}.bak.*"

# Desactivar autenticación por contraseña
echo "  → Desactivando PasswordAuthentication"
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"

# Activar autenticación por clave pública
echo "  → Activando PubkeyAuthentication"
sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONFIG"

# Desactivar login como root (buena práctica adicional)
echo "  → Desactivando PermitRootLogin (solo con key)"
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' "$SSHD_CONFIG"

# Reiniciar servicio SSH
echo "  → Reiniciando sshd..."
systemctl restart sshd

echo ""
echo "✅ SSH hardening completado:"
echo "   • PasswordAuthentication: no"
echo "   • PubkeyAuthentication: yes"
echo "   • PermitRootLogin: prohibit-password"
echo ""
echo "⚠️  Mantén tu sesión actual abierta y prueba en otra terminal"
echo "   que puedes conectar con tu clave antes de cerrar esta sesión."
