#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  deploy.sh — Despliega OpenClaw en K3s (single-node)
#
#  Uso:
#    1. Instala K3s:            curl -sfL https://get.k3s.io | sh -
#    2. Construye la imagen:    docker build -t openclaw:latest ./openclaw-server
#    3. Importa a K3s:          docker save openclaw:latest | sudo k3s ctr images import -
#    4. (Opcional) Hardening:   sudo bash security/setup-firewall.sh
#                               sudo bash security/harden-ssh.sh
#                               sudo bash security/setup-fail2ban.sh
#                               sudo bash security/setup-tailscale.sh
#    5. Ejecuta:                sudo bash compose/deploy.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
K8S_DIR="$SCRIPT_DIR/k8s"

# ─── Verificación de requisitos ───────────────────────────────
echo "🔍 Verificando requisitos..."

check_cmd() {
  if ! command -v "$1" &>/dev/null; then
    echo "❌ $1 no encontrado. Instálalo primero."
    echo "   $2"
    exit 1
  fi
}

check_cmd kubectl "Instala K3s: curl -sfL https://get.k3s.io | sh -"
check_cmd docker  "Instala Docker: curl -fsSL https://get.docker.com | sh"

echo "  ✓ kubectl encontrado"
echo "  ✓ docker encontrado"

# Verificar que la imagen existe
if ! docker image inspect openclaw:latest &>/dev/null; then
  echo "⚠️  Imagen 'openclaw:latest' no encontrada."
  echo "   Construyéndola automáticamente..."
  DOCKERFILE_DIR="$SCRIPT_DIR/../openclaw-server"
  if [ -f "$DOCKERFILE_DIR/Dockerfile" ]; then
    docker build -t openclaw:latest "$DOCKERFILE_DIR"
    echo "  → Importando imagen en K3s..."
    docker save openclaw:latest | k3s ctr images import -
  else
    echo "❌ No se encontró Dockerfile en $DOCKERFILE_DIR"
    exit 1
  fi
fi

# ─── Crear directorios de persistencia ────────────────────────
echo ""
echo "📁 Creando directorio de persistencia..."
mkdir -p /opt/openclaw/config
# Asegurar que el usuario node (uid 1000) pueda escribir
chown -R 1000:1000 /opt/openclaw
echo "  ✓ /opt/openclaw/config"

# ─── Despliegue en Kubernetes ─────────────────────────────────
echo ""
echo "🚀 Desplegando OpenClaw en Kubernetes..."

echo "  1/5  Creando namespace..."
kubectl apply -f "$K8S_DIR/namespace.yaml"

echo "  2/5  Creando volúmenes persistentes..."
kubectl apply -f "$K8S_DIR/pv.yaml"

echo "  3/5  Desplegando OpenClaw..."
kubectl apply -f "$K8S_DIR/deployment.yaml"

echo "  4/5  Creando servicios (ClusterIP — solo acceso interno)..."
kubectl apply -f "$K8S_DIR/service.yaml"

echo "  5/5  Desplegando Whisper (transcripción de audio)..."
kubectl apply -f "$K8S_DIR/whisper.yaml"

# ─── Esperar a que el pod esté listo ──────────────────────────
echo ""
echo "⏳ Esperando a que el pod esté listo..."
kubectl wait --for=condition=ready pod -l app=openclaw -n openclaw --timeout=120s 2>/dev/null || true

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ¡OpenClaw desplegado!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Estado del pod:"
kubectl get pods -n openclaw
echo ""
echo "📋 Comandos útiles:"
echo ""
echo "  # Ver logs en tiempo real"
echo "  sudo kubectl logs -f deployment/openclaw -n openclaw"
echo ""
echo "  # Configurar OpenClaw (primera vez)"
echo "  sudo kubectl exec -it deployment/openclaw -n openclaw -- openclaw onboard"
echo ""
echo "  # Acceso al dashboard (requiere Tailscale):"
echo "  sudo kubectl port-forward svc/openclaw 18789:18789 -n openclaw --address=\$(tailscale ip -4)"
echo "  # Luego abre: http://<TU-IP-TAILSCALE>:18789"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔒 ¿Ya configuraste la seguridad del servidor?"
echo "   sudo bash security/setup-firewall.sh"
echo "   sudo bash security/harden-ssh.sh"
echo "   sudo bash security/setup-fail2ban.sh"
echo "   sudo bash security/setup-tailscale.sh"
