#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  setup-fail2ban.sh — Instala y configura Fail2Ban
#
#  Ejecutar como root en el HOST:
#    sudo bash security/setup-fail2ban.sh
#
#  Banea IPs tras 3 intentos fallidos de SSH (ban de 1 hora)
# ============================================================

echo "🛡️  Configurando Fail2Ban..."

# Instalar Fail2Ban
if ! command -v fail2ban-client &>/dev/null; then
  echo "  → Instalando Fail2Ban..."
  apt-get update -qq && apt-get install -y -qq fail2ban
fi

# Crear configuración local (no editar el archivo principal)
JAIL_LOCAL="/etc/fail2ban/jail.local"

cat > "$JAIL_LOCAL" << 'EOF'
[DEFAULT]
# Ban por 1 hora
bantime  = 3600
# Ventana de detección: 10 minutos
findtime = 600
# Máximo de intentos antes del ban
maxretry = 3
# Acción: banear IP con iptables
banaction = iptables-multiport

[sshd]
enabled  = true
port     = ssh
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 3
EOF

echo "  → Configuración escrita en $JAIL_LOCAL"

# Habilitar y arrancar el servicio
systemctl enable fail2ban
systemctl restart fail2ban

echo ""
echo "✅ Fail2Ban configurado:"
echo "   • Ban tras 3 intentos fallidos"
echo "   • Duración del ban: 1 hora"
echo ""
echo "📊 Estado actual:"
fail2ban-client status sshd
