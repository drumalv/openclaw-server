# OpenClaw Server

Server de despliegue para [OpenClaw](https://github.com/nichochar/openclaw) — un agente de IA accesible vía Telegram y dashboard web.

## Arquitectura

```
┌─────────────────────────────────────┐
│          Máquina Cloud (K3s)        │
│                                     │
│  ┌───────────────────────────────┐  │
│  │     Pod: openclaw             │  │
│  │     Puerto: 18789             │  │
│  │                               │  │
│  │  Volúmenes:                   │  │
│  │   📁 config   → ~/.openclaw  │  │
│  │                               │  │
│  └───────────────────────────────┘  │
│                                     │
│  Service NodePort → :30789          │
└─────────────────────────────────────┘
```

## Estructura del proyecto

```
openclaw-server/
├── Dockerfile              # Imagen base con OpenClaw
├── docker-compose.yml      # Alternativa para despliegue con Docker Compose
├── deploy.sh               # Script de despliegue automático en K3s
├── k8s/
│   ├── namespace.yaml      # Namespace: openclaw
│   ├── pv.yaml             # PersistentVolumes (config + workspace)
│   ├── deployment.yaml     # Deployment del pod
│   └── service.yaml        # NodePort en puerto 30789
```

## Requisitos

- **Máquina cloud** con Linux (Ubuntu/Debian recomendado)
- **Docker** (para construir la imagen)
- **K3s** (Kubernetes ligero, se instala con un solo comando)

## Despliegue en Kubernetes (K3s)

### 1. Instalar K3s y Docker

```bash
# K3s
curl -sfL https://get.k3s.io | sh -

# Docker
curl -fsSL https://get.docker.com | sh
```

### 2. Clonar, construir e importar la imagen

```bash
git clone <tu-repo> openclaw-server && cd openclaw-server
docker build -t openclaw:latest .
docker save openclaw:latest | sudo k3s ctr images import -
```

### 3. Desplegar

```bash
sudo bash deploy.sh
```

### 4. Verificar

```bash
sudo kubectl get pods -n openclaw
sudo kubectl logs -f deployment/openclaw -n openclaw
```

### 5. Configurar OpenClaw

Entra al contenedor para ejecutar el asistente de configuración:

```bash
sudo kubectl exec -it deployment/openclaw -n openclaw -- openclaw onboard
```

Esto te guiará para conectar el proveedor de IA (Google Gemini) y las integraciones (Telegram).

### 6. Vincular Telegram

1. Abre tu bot en Telegram y envíale `/start`.
2. El bot te dará un **Pairing Code**.
3. Apruébalo desde dentro del contenedor:

```bash
sudo kubectl exec -it deployment/openclaw -n openclaw -- openclaw pairing approve telegram <CODIGO>
```

### 7. Acceder al Dashboard

Abre `http://<IP-DE-TU-MAQUINA>:30789` en el navegador.

Si aparece "Pairing required", aprueba el dispositivo:

```bash
sudo kubectl exec deployment/openclaw -n openclaw -- openclaw devices list
sudo kubectl exec deployment/openclaw -n openclaw -- openclaw devices approve <ID>
```

## Despliegue alternativo con Docker Compose

Si prefieres usar Docker Compose sin Kubernetes:

```bash
docker compose up -d
docker compose logs -f
```

## Volúmenes persistentes

| Volumen | Ruta en el host (K3s) | Ruta en el contenedor | Propósito |
|---------|----------------------|----------------------|-----------|
| config | `/opt/openclaw/config` | `/home/node/.openclaw` | Configuración, estado y memoria del agente |
| workspace | `/opt/openclaw/workspace` | `/home/node/openclaw/workspace` | Espacio de trabajo del agente |

> **Nota:** Los datos persisten aunque el pod se reinicie o se destruya gracias a la política `Retain` de los PersistentVolumes.

## Comandos útiles

```bash
# Ver estado del pod
sudo kubectl get pods -n openclaw

# Ver logs en tiempo real
sudo kubectl logs -f deployment/openclaw -n openclaw

# Entrar al contenedor
sudo kubectl exec -it deployment/openclaw -n openclaw -- bash

# Reiniciar el despliegue
sudo kubectl rollout restart deployment/openclaw -n openclaw

# Eliminar todo
sudo kubectl delete namespace openclaw
```
