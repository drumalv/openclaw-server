#!/usr/bin/env bash
# Actualizar servicio de port-forward en el servidor

echo "Sincronizando archivos actualizados..."
scp -i ~/ssh_drumalv_server/ssh-key-2026-02-14.key \
  compose/k8s/openclaw-portforward.service \
  compose/k8s/setup-portforward.sh \
  compose/k8s/portforward-wrapper.sh \
  ubuntu@141.253.197.178:~/openclaw-server/compose/k8s/

echo "Reinstalando servicio..."
ssh -i ~/ssh_drumalv_server/ssh-key-2026-02-14.key ubuntu@141.253.197.178 \
  'cd openclaw-server && sudo bash compose/k8s/setup-portforward.sh'

echo "✅ Servicio actualizado"
