FROM node:22-bookworm-slim

# Paquetes mínimos: git (para npm deps vía git), certificados, tini (PID 1)
RUN apt-get update && apt-get install -y --no-install-recommends \
  git ca-certificates tini \
  python3 python3-pip python3-venv \
  && rm -rf /var/lib/apt/lists/*

# Instala OpenClaw global (método recomendado en docs: npm install -g openclaw@latest)
RUN npm install -g openclaw@latest

# Dar permisos al usuario node para instalar skills globales
RUN chown -R node:node /usr/local/lib/node_modules /usr/local/bin

# Usuario no-root (ya existe en la imagen oficial node)
USER node
WORKDIR /home/node

# Persistencia típica (la harás con un volumen en docker-compose):
# /home/node/.openclaw  (config/state)

ENTRYPOINT ["/usr/bin/tini","--"]

# Arranca Gateway en foreground (Telegram funciona con long-polling, no requiere puertos públicos)
CMD ["openclaw","gateway","--port","18789","--verbose"]