# Guía de Hardening — OpenClaw Server

Esta guía te ayudará a asegurar tu servidor OpenClaw siguiendo las mejores prácticas de seguridad.

## 🎯 Objetivo

Implementar 5 capas de seguridad en el servidor:

1. **🌐 Tailscale VPN** — acceso privado sin exponer puertos
2. **🔥 UFW Firewall** — bloquear todo tráfico no autorizado
3. **🛡️ Fail2Ban** — protección contra fuerza bruta
4. **🔑 SSH Hardening** — autenticación solo con claves
5. **🔄 Auto-updates** — actualización diaria automática

---

## ⚡ Opción 1: Deployment Automático (Recomendado)

Usa el script maestro que ejecuta todas las medidas en orden:

### En el servidor OpenClaw

```bash
cd openclaw-server
sudo bash security/deploy-security.sh
```

El script:
- ✓ Verifica pre-requisitos (internet, claves SSH)
- ✓ Ejecuta cada paso con confirmaciones interactivas
- ✓ Valida la configuración después de cada paso
- ✓ Muestra un resumen final del estado de seguridad

### Flujo del script

1. **Pre-verificación**
   - Conexión a internet
   - Claves SSH autorizadas (CRÍTICO)
   - Advertencias si falta algo

2. **Tailscale** (paso 1/5)
   - Instala Tailscale
   - Pide que autorices el dispositivo en el navegador
   - Espera confirmación antes de continuar

3. **UFW Firewall** (paso 2/5)
   - Configura reglas: allow SSH, Tailscale, K3s
   - Bloquea dashboard público
   - Activa el firewall

4. **Fail2Ban** (paso 3/5)
   - Instala y configura (ban tras 3 intentos)
   - Monitoriza `/var/log/auth.log`

5. **SSH Hardening** (paso 4/5)
   - Advertencia CRÍTICA sobre clave SSH
   - Pide verificación en segunda terminal
   - Deshabilita autenticación por contraseña

6. **Auto-update** (paso 5/5)
   - Instala cron diario
   - Actualiza OpenClaw automáticamente

7. **Resumen final**
   - Estado de cada medida
   - Próximos pasos (acceso al dashboard)

---

## 🔧 Opción 2: Deployment Manual

Si prefieres ejecutar cada paso individualmente:

### 1️⃣ Tailscale VPN (primero)

```bash
sudo bash security/setup-tailscale.sh
```

**Acciones post-instalación:**
1. Copia el enlace que aparece
2. Ábrelo en tu navegador
3. Inicia sesión con tu cuenta Tailscale (crea una si no tienes)
4. Instala Tailscale en tu PC/móvil: https://tailscale.com/download

**Verificación:**
```bash
tailscale status
tailscale ip -4
```

---

### 2️⃣ UFW Firewall

```bash
sudo bash security/setup-firewall.sh
```

**Verificación:**
```bash
sudo ufw status verbose
```

**Resultado esperado:**
```
Status: active
To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere                  # SSH
41641/udp                  ALLOW IN    Anywhere                  # Tailscale WireGuard
6443/tcp                   ALLOW IN    Anywhere                  # K3s API Server
```

---

### 3️⃣ Fail2Ban

```bash
sudo bash security/setup-fail2ban.sh
```

**Verificación:**
```bash
sudo systemctl status fail2ban
sudo fail2ban-client status sshd
```

**Resultado esperado:**
```
|- Status
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- Currently banned: 0
```

---

### 4️⃣ SSH Hardening ⚠️ CRÍTICO

> [!CAUTION]
> **ANTES de ejecutar este paso:**
> 
> 1. Abre una **SEGUNDA terminal**
> 2. Prueba conectar por SSH con tu clave:
>    ```bash
>    ssh -i ~/.ssh/id_rsa usuario@servidor
>    ```
> 3. Si funciona, vuelve a la primera terminal y continúa
> 4. Si NO funciona, **NO ejecutes el script**. Configura tu clave primero:
>    ```bash
>    ssh-copy-id usuario@servidor
>    ```

```bash
sudo bash security/harden-ssh.sh
```

**Verificación:**
```bash
sudo sshd -T | grep -E "passwordauthentication|pubkeyauthentication|permitrootlogin"
```

**Resultado esperado:**
```
passwordauthentication no
pubkeyauthentication yes
permitrootlogin prohibit-password
```

**Prueba en la segunda terminal:**
1. Cierra la sesión SSH
2. Intenta reconectar — debe funcionar solo con clave, SIN pedir contraseña

---

### 5️⃣ Auto-update

```bash
sudo cp security/auto-update.sh /etc/cron.daily/openclaw-update
sudo chmod +x /etc/cron.daily/openclaw-update
```

**Verificación:**
```bash
ls -lh /etc/cron.daily/openclaw-update
sudo run-parts --test /etc/cron.daily
```

El script se ejecutará automáticamente cada día ~4AM.

---

## 🔍 Verificación Completa

Después del hardening, verifica que todo está correcto:

```bash
# Estado general del sistema (copia este script en un archivo verify.sh)
cat << 'EOF' > verify-security.sh
#!/bin/bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 VERIFICACIÓN DE SEGURIDAD — OpenClaw Server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "🔥 UFW Firewall:"
sudo ufw status verbose | head -n 15
echo ""

echo "🔑 SSH Configuration:"
sudo sshd -T | grep -E "passwordauthentication|pubkeyauthentication|permitrootlogin"
echo ""

echo "🛡️  Fail2Ban:"
sudo systemctl is-active fail2ban && echo "  Status: active" || echo "  Status: inactive"
sudo fail2ban-client status sshd 2>/dev/null | head -n 5 || echo "  Not configured"
echo ""

echo "🌐 Tailscale:"
tailscale status 2>/dev/null | head -n 3 || echo "  Not installed"
echo "  Private IP: $(tailscale ip -4 2>/dev/null || echo 'N/A')"
echo ""

echo "🔄 Auto-update:"
[[ -x /etc/cron.daily/openclaw-update ]] && echo "  ✓ Installed" || echo "  ✗ Not installed"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
EOF

chmod +x verify-security.sh
./verify-security.sh
```

---

## 🌐 Acceso al Dashboard de OpenClaw

El dashboard **NO** está expuesto públicamente. Para acceder:

### 1. En tu PC/móvil, instala Tailscale

Descarga desde: https://tailscale.com/download

### 2. Inicia sesión con la misma cuenta

Ambos dispositivos (servidor y tu PC) deben estar en el mismo Tailnet.

### 3. En el servidor, crea un port-forward

```bash
sudo kubectl port-forward svc/openclaw 18789:18789 \
  -n openclaw --address=$(tailscale ip -4)
```

### 4. En tu navegador, abre

```
http://<IP-TAILSCALE-DEL-SERVIDOR>:18789
```

Para obtener la IP del servidor:
```bash
tailscale ip -4
```

### 5. Si pide autenticación

```bash
# Generar token de acceso
sudo kubectl exec deployment/openclaw -n openclaw -- openclaw auth token

# Si requiere aprobación de dispositivo
sudo kubectl exec deployment/openclaw -n openclaw -- openclaw devices list
sudo kubectl exec deployment/openclaw -n openclaw -- openclaw devices approve <ID>
```

---

## 🚨 Troubleshooting

### No puedo conectar por SSH después del hardening

**Solución 1: Acceso vía Tailscale**
```bash
# Desde tu PC (con Tailscale instalado)
ssh -i ~/.ssh/id_rsa usuario@<IP-TAILSCALE-SERVIDOR>
```

**Solución 2: Acceso por consola del VPS**
1. Accede a la consola web de tu proveedor de VPS
2. Restaura el backup de SSH:
   ```bash
   sudo cp /etc/ssh/sshd_config.bak.* /etc/ssh/sshd_config
   sudo systemctl restart sshd
   ```

### El firewall me bloqueó

Si tienes acceso por consola:
```bash
sudo ufw disable
```

### Una IP fue baneada por error

```bash
sudo fail2ban-client set sshd unbanip <IP>
```

### Tailscale no conecta

```bash
# Reintentar conexión
sudo tailscale down
sudo tailscale up
```

### El dashboard no carga

1. Verifica que el port-forward está activo:
   ```bash
   ps aux | grep "kubectl port-forward"
   ```

2. Verifica que el pod está corriendo:
   ```bash
   sudo kubectl get pods -n openclaw
   ```

3. Verifica logs:
   ```bash
   sudo kubectl logs -f deployment/openclaw -n openclaw
   ```

---

## 📋 Checklist de Seguridad

- [ ] ✅ UFW activo con reglas configuradas
- [ ] ✅ SSH solo con clave pública (no contraseñas)
- [ ] ✅ Fail2Ban monitorizando intentos fallidos
- [ ] ✅ Tailscale conectado (red VPN privada)
- [ ] ✅ Auto-update instalado en cron
- [ ] ✅ Dashboard accesible solo vía Tailscale
- [ ] ✅ Puerto 18789 NO expuesto públicamente
- [ ] ✅ Backup de configuración SSH guardado

---

## 🔐 Resumen de Puertos

| Puerto | Servicio | Acceso | Estado |
|--------|----------|--------|--------|
| 22 | SSH | Público (solo clave) | ✅ Abierto |
| 41641/udp | Tailscale | Público | ✅ Abierto |
| 6443 | K3s API | Público (opcional) | ✅ Abierto |
| 18789 | OpenClaw Dashboard | Solo Tailscale | 🔒 Bloqueado |
| 8000 | Whisper (interno) | Solo cluster K3s | 🔒 Bloqueado |

---

## 📚 Referencias

- [README del proyecto](file:///home/alvaro/openclaw-server/README.md)
- [Tailscale Docs](https://tailscale.com/kb/)
- [UFW Guide](https://help.ubuntu.com/community/UFW)
- [Fail2Ban Wiki](https://github.com/fail2ban/fail2ban/wiki)
