#!/usr/bin/env bash
# ============================================================
# update-portforward.sh — Actualizar servicio de port-forward en el servidor
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
#   bash update-portforward.sh
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

echo "Sincronizando archivos actualizados..."
scp -i "$SSH_KEY" \
  scripts/services/portforward/openclaw-portforward.service \
  scripts/services/portforward/install.sh \
  scripts/services/portforward/wrapper.sh \
  ${SERVER_USER}@${SERVER_IP}:~/openclaw-server/scripts/services/portforward/

echo "Reinstalando servicio..."
ssh -i "$SSH_KEY" ${SERVER_USER}@${SERVER_IP} \
  'cd openclaw-server && sudo bash scripts/services/portforward/install.sh'

echo "✅ Servicio actualizado"
