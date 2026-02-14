#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  download-security-rules.sh — Descarga reglas de seguridad
#  de la comunidad para proteger contra prompt injection.
#
#  Ejecutar desde la raíz del proyecto:
#    bash security/download-security-rules.sh
# ============================================================

OPENCLAW_CONFIG_DIR="/opt/openclaw/config"
RULES_DIR="${OPENCLAW_CONFIG_DIR}/rules"

echo "📥 Descargando reglas de seguridad de la comunidad..."

# Crear directorio de reglas si no existe
sudo mkdir -p "$RULES_DIR"

# Descargar reglas de seguridad desde el repositorio oficial/comunidad
# Nota: Actualiza esta URL si el repositorio cambia
RULES_URL="https://raw.githubusercontent.com/nichochar/openclaw/main/docs/security-rules.md"

if curl -fsSL "$RULES_URL" -o /tmp/openclaw-security-rules.md 2>/dev/null; then
  sudo cp /tmp/openclaw-security-rules.md "$RULES_DIR/community-security-rules.md"
  echo "✅ Reglas descargadas en: $RULES_DIR/community-security-rules.md"
else
  echo "⚠️  No se pudo descargar desde el repositorio oficial."
  echo "   Esto es normal si el repositorio no tiene un archivo de reglas estándar."
  echo ""
  echo "   Alternativa: usa las reglas locales en security/system-prompt-security.md"
  echo "   y pégalas manualmente en el System Prompt del agente."
fi

echo ""
echo "📖 Para aplicar las reglas:"
echo "   1. Abre el panel web de OpenClaw"
echo "   2. Ve a Configuración > Agent Settings > System Prompt"
echo "   3. Pega las reglas de security/system-prompt-security.md"
