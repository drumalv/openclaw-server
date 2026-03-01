FROM node:22-bookworm-slim

# Paquetes del sistema (organizados por categoría)
RUN apt-get update && apt-get install -y --no-install-recommends \
  # Core
  git ca-certificates tini \
  # Python runtime
  python3 python3-pip python3-venv \
  # Dependencias nativas (para canvas, etc.)
  libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev build-essential \
  # Herramientas de red
  curl wget netcat-openbsd iputils-ping dnsutils \
  # Monitoreo y debugging
  procps htop lsof strace \
  # Editores
  vim nano \
  # Compresión
  unzip zip tar gzip bzip2 xz-utils \
  # Desarrollo
  jq \
  # Texto
  less tree \
  # Media y Remotion
  chromium ffmpeg \
  && rm -rf /var/lib/apt/lists/*

# Instala yq (YAML processor) desde GitHub
RUN curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
  -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# Instala OpenClaw global (método recomendado en docs: npm install -g openclaw@latest)
RUN npm install -g openclaw@latest

# Dar permisos al usuario node para instalar skills globales y tener acceso al workspace
RUN chown -R node:node /usr/local/lib/node_modules /usr/local/bin /home/node

# Configuración de variables de entorno para Remotion/Puppeteer
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
  PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
  REMOTION_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium

# Usuario no-root (ya existe en la imagen oficial node)
USER node
WORKDIR /home/node

# Crear directorio "nutrition" en workspace para evitar error en el heartbeat del agente
RUN mkdir -p /home/node/openclaw/workspace/nutrition

# Persistencia típica (la harás con un volumen en docker-compose):
# /home/node/.openclaw  (config/state)

ENTRYPOINT ["/usr/bin/tini","--"]

# Arranca Gateway en foreground (Telegram funciona con long-polling, no requiere puertos públicos)
CMD ["openclaw","gateway","--port","18789","--verbose"]