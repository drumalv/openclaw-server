#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  auto-update.sh — Actualiza OpenClaw diariamente
#
#  Reconstruye la imagen Docker con la última versión de OpenClaw
#  y la importa en K3s. Reinicia el deployment automáticamente.
#
#  Instalar como cron diario:
#    sudo cp security/auto-update.sh /etc/cron.daily/openclaw-update
#    sudo chmod +x /etc/cron.daily/openclaw-update
#
#  O añadir al crontab manualmente:
#    sudo crontab -e
#    0 4 * * * /ruta/a/openclaw-server/security/auto-update.sh >> /var/log/openclaw-update.log 2>&1
# ============================================================

LOG_PREFIX="[openclaw-update $(date '+%Y-%m-%d %H:%M:%S')]"

echo "$LOG_PREFIX Iniciando actualización de OpenClaw..."

# Ruta al Dockerfile (ajustar si es diferente)
DOCKERFILE_DIR="$(cd "$(dirname "$0")/../openclaw-server" && pwd)"

if [ ! -f "$DOCKERFILE_DIR/Dockerfile" ]; then
  # Buscar en compose/ como alternativa
  DOCKERFILE_DIR="$(cd "$(dirname "$0")/../compose" && pwd)"
fi

# Paso 1: Reconstruir la imagen con --no-cache para obtener última versión
echo "$LOG_PREFIX Reconstruyendo imagen Docker..."
docker build --no-cache -t openclaw:latest "$DOCKERFILE_DIR"

# Paso 2: Importar en K3s
echo "$LOG_PREFIX Importando imagen en K3s..."
docker save openclaw:latest | k3s ctr images import -

# Paso 3: Reiniciar el deployment para usar la nueva imagen
echo "$LOG_PREFIX Reiniciando deployment..."
kubectl rollout restart deployment/openclaw -n openclaw

# Paso 4: Esperar a que el rollout termine
echo "$LOG_PREFIX Esperando rollout..."
kubectl rollout status deployment/openclaw -n openclaw --timeout=120s

echo "$LOG_PREFIX ✅ Actualización completada."
