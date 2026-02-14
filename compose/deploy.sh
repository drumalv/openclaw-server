#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  deploy.sh — Despliega OpenClaw en K3s (single-node)
#
#  Uso:
#    1. Instala K3s:            curl -sfL https://get.k3s.io | sh -
#    2. Construye la imagen:    docker build -t openclaw:latest .
#    3. Importa a K3s:          docker save openclaw:latest | sudo k3s ctr images import -
#    4. Edita k8s/secret.yaml con tus tokens reales
#    5. Ejecuta:                sudo bash deploy.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
K8S_DIR="$SCRIPT_DIR/k8s"

echo "🚀 Desplegando OpenClaw en Kubernetes..."

echo "1/4  Creando namespace..."
kubectl apply -f "$K8S_DIR/namespace.yaml"

echo "2/4  Creando volúmenes persistentes..."
kubectl apply -f "$K8S_DIR/pv.yaml"

echo "3/4  Desplegando pods..."
kubectl apply -f "$K8S_DIR/deployment.yaml"

echo "4/4  Exponiendo el servicio..."
kubectl apply -f "$K8S_DIR/service.yaml"

echo ""
echo "✅ ¡Desplegado! Comprueba el estado:"
echo "   sudo kubectl get pods -n openclaw"
echo "   sudo kubectl logs -f deployment/openclaw -n openclaw"
echo ""
echo "🌐 Dashboard accesible en: http://<TU-IP>:30789"
