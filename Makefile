.PHONY: help deploy deploy-k8s setup-security install-portforward install-tailscale-serve install-auto-update clean

# Comandos principales
help:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  OpenClaw Server - Comandos Disponibles"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "📦 Deployment:"
	@echo "  make deploy              - Despliega OpenClaw en K8s (alias de deploy-k8s)"
	@echo "  make deploy-k8s          - Despliega OpenClaw en K8s"
	@echo "  make build-image         - Construye la imagen Docker"
	@echo ""
	@echo "🔒 Seguridad:"
	@echo "  make setup-security      - Configura seguridad del servidor (UFW, SSH, Fail2Ban, Tailscale)"
	@echo ""
	@echo "🛠️  Servicios:"
	@echo "  make install-portforward      - Instala servicio systemd de port-forward permanente"
	@echo "  make install-tailscale-serve  - Instala Tailscale Serve con HTTPS"
	@echo "  make install-auto-update      - Instala cron de auto-actualización"
	@echo ""
	@echo "📋 Utilidades:"
	@echo "  make status              - Ver estado de pods K8s"
	@echo "  make logs                - Ver logs de OpenClaw"
	@echo "  make shell               - Entrar al contenedor OpenClaw"
	@echo "  make clean               - Eliminar despliegue completo"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Deployment
deploy: deploy-k8s

deploy-k8s:
	@echo "🚀 Desplegando OpenClaw en K8s..."
	@sudo bash scripts/deploy/deploy-k8s.sh

build-image:
	@echo "🔨 Construyendo imagen Docker..."
	@docker build -t openclaw:latest docker/
	@echo "  → Importando en K3s..."
	@docker save openclaw:latest | sudo k3s ctr images import -

# Seguridad
setup-security:
	@echo "🔒 Configurando seguridad del servidor..."
	@sudo bash scripts/security/deploy-all.sh

# Servicios
install-portforward:
	@echo "🌐 Instalando servicio de port-forward..."
	@sudo bash scripts/services/portforward/install.sh

install-tailscale-serve:
	@echo "🔐 Instalando Tailscale Serve (HTTPS)..."
	@sudo bash scripts/services/tailscale-serve/install.sh
	@sudo bash scripts/services/tailscale-serve/install-service.sh

install-auto-update:
	@echo "🔄 Instalando auto-update diario..."
	@sudo cp scripts/services/auto-update/install.sh /etc/cron.daily/openclaw-update
	@sudo chmod +x /etc/cron.daily/openclaw-update

# Utilidades
status:
	@echo "📊 Estado de pods:"
	@sudo kubectl get pods -n openclaw

logs:
	@echo "📜 Logs de OpenClaw (Ctrl+C para salir):"
	@sudo kubectl logs -f deployment/openclaw -n openclaw

shell:
	@echo "🐚 Abriendo shell en OpenClaw..."
	@sudo kubectl exec -it deployment/openclaw -n openclaw -- bash

restart:
	@echo "🔄 Reiniciando deployment..."
	@sudo kubectl rollout restart deployment/openclaw -n openclaw

clean:
	@echo "🧹 Eliminando namespace openclaw..."
	@sudo kubectl delete namespace openclaw
	@echo "✅ Limpieza completada"
