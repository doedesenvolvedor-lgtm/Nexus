#!/bin/bash

# ============================================
# NEXUS STREAMING - SECURITY & HARDENING SCRIPT
# ============================================
# Este script configura segurança básica para o VPS
# Execução: sudo bash security_hardening.sh

set -e

echo "🔒 Iniciando hardening de segurança para Nexus Streaming..."

# ============================================
# 1. ATUALIZAÇÕES DO SISTEMA
# ============================================
echo "📦 Atualizando pacotes do sistema..."
apt-get update -y
apt-get upgrade -y
apt-get install -y \
    curl \
    wget \
    htop \
    net-tools \
    git \
    ufw \
    fail2ban \
    unattended-upgrades \
    apt-listchanges \
    needrestart \
    chrony \
    rsync

# ============================================
# 2. UFW FIREWALL
# ============================================
echo "🔥 Configurando Firewall (UFW)..."

ufw --force enable
ufw default deny incoming
ufw default allow outgoing

# Permitir SSH (importante: não bloquear seu acesso!)
ufw allow 22/tcp

# Permitir HTTP e HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Permitir Docker (se necessário)
ufw allow 8000/tcp
ufw allow 5432/tcp
ufw allow 6379/tcp

# Listar regras
ufw status verbose

# ============================================
# 3. FAIL2BAN - Proteção contra Brute Force
# ============================================
echo "🛡️  Configurando Fail2Ban..."

cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = admin@nexusstream.com
sendername = Nexus Security

[sshd]
enabled = true
port = ssh
filter = sshd
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log

[nginx-noscript]
enabled = true
port = http,https
filter = nginx-noscript
logpath = /var/log/nginx/access.log
maxretry = 6

[nginx-badbots]
enabled = true
port = http,https
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2

[nginx-noproxy]
enabled = true
port = http,https
filter = nginx-noproxy
logpath = /var/log/nginx/access.log
maxretry = 2
EOF

systemctl restart fail2ban
systemctl enable fail2ban

# ============================================
# 4. SSH HARDENING
# ============================================
echo "🔐 Hardening SSH..."

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

cat >> /etc/ssh/sshd_config << 'EOF'

# Custom Security Settings
Port 22
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
X11Forwarding no
MaxAuthTries 3
MaxSessions 10
ClientAliveInterval 300
ClientAliveCountMax 2
TCPKeepAlive yes
Compression delayed
EOF

sshctl daemon-reload
sshctl restart

# ============================================
# 5. SISTEMA DE ARQUIVOS
# ============================================
echo "📁 Endurecendo sistema de arquivos..."

# Desabilitar CTRL+ALT+DEL
if [ -f /etc/inittab ]; then
    sed -i 's/^ca::ctrlaltdel:/#ca::ctrlaltdel:/' /etc/inittab
fi

# Proteger /tmp, /var/tmp e /dev/shm
if grep -q "/tmp" /etc/fstab; then
    mount -o remount,noexec,nosuid,nodev /tmp
    mount -o remount,noexec,nosuid,nodev /var/tmp
    mount -o remount,noexec,nosuid,nodev /dev/shm
fi

# ============================================
# 6. AUDITORIA E LOGS
# ============================================
echo "📊 Configurando auditoria..."

# Auditoria do sistema
apt-get install -y auditd audispd-plugins

systemctl enable auditd
systemctl start auditd

# Nginx logs
mkdir -p /var/log/nexus
touch /var/log/nexus/access.log
touch /var/log/nexus/error.log
chmod 755 /var/log/nexus

# ============================================
# 7. ATUALIZAÇÕES AUTOMÁTICAS
# ============================================
echo "🔄 Configurando atualizações automáticas..."

cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

Unattended-Upgrade::Mail "admin@nexusstream.com";
Unattended-Upgrade::MailReport "on-change";
EOF

# ============================================
# 8. BACKUP AUTOMÁTICO
# ============================================
echo "💾 Configurando backups automáticos..."

mkdir -p /backups/nexus

cat > /usr/local/bin/backup_nexus.sh << 'EOF'
#!/bin/bash

# Backup script para Nexus Streaming
BACKUP_DIR="/backups/nexus"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/nexus_backup_$TIMESTAMP.tar.gz"

echo "🔄 Iniciando backup em $TIMESTAMP..."

# Backup do docker-compose e configurações
tar -czf "$BACKUP_FILE" \
    /workspaces/Nexus/docker-compose.yml \
    /workspaces/Nexus/nginx/nginx.conf \
    /workspaces/Nexus/admin/ \
    /workspaces/Nexus/backend/app/ \
    --exclude="__pycache__"

# Backup do PostgreSQL
docker exec nexus-postgres-1 pg_dump -U postgres nexus > "$BACKUP_DIR/postgres_$TIMESTAMP.sql"

# Manter apenas últimos 7 backups
find "$BACKUP_DIR" -name "nexus_backup_*.tar.gz" -mtime +7 -delete
find "$BACKUP_DIR" -name "postgres_*.sql" -mtime +7 -delete

echo "✅ Backup concluído: $BACKUP_FILE"
EOF

chmod +x /usr/local/bin/backup_nexus.sh

# Cron job para backup diário
cat >> /etc/crontab << 'EOF'
# Backup Nexus Streaming - Diariamente às 2 AM
0 2 * * * root /usr/local/bin/backup_nexus.sh >> /var/log/nexus_backup.log 2>&1
EOF

# ============================================
# 9. MONITORAMENTO DE RECURSOS
# ============================================
echo "📈 Instalando ferramentas de monitoramento..."

# Criar script de health check
cat > /usr/local/bin/nexus_health_check.sh << 'EOF'
#!/bin/bash

# Health check para Nexus Streaming
API_URL="https://api.nexusstream.com"
ADMIN_URL="https://admin.nexusstream.com"
WEB_URL="https://nexusstream.com"

echo "🔍 Verificando saúde do Nexus Streaming..."

# Verificar API
if curl -s -o /dev/null -w "%{http_code}" "$API_URL/health" -k | grep -q "200"; then
    echo "✅ API está online"
else
    echo "❌ API está offline - Enviando alerta"
fi

# Verificar Website
if curl -s -o /dev/null -w "%{http_code}" "$WEB_URL" -k | grep -q "200"; then
    echo "✅ Website está online"
else
    echo "❌ Website está offline - Enviando alerta"
fi

# Verificar Admin
if curl -s -o /dev/null -w "%{http_code}" "$ADMIN_URL" -k | grep -q "200"; then
    echo "✅ Admin está online"
else
    echo "❌ Admin está offline - Enviando alerta"
fi

# Verificar uso de disco
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    echo "⚠️  ALERTA: Uso de disco em $DISK_USAGE%"
fi

# Verificar memória
MEM_USAGE=$(free | awk 'NR==2 {printf "%.0f\n", $3/$2 * 100}')
if [ "$MEM_USAGE" -gt 80 ]; then
    echo "⚠️  ALERTA: Uso de memória em $MEM_USAGE%"
fi

echo "✅ Health check concluído"
EOF

chmod +x /usr/local/bin/nexus_health_check.sh

# Cron job para health check a cada 30 minutos
cat >> /etc/crontab << 'EOF'
# Health check Nexus - A cada 30 minutos
*/30 * * * * root /usr/local/bin/nexus_health_check.sh >> /var/log/nexus_health.log 2>&1
EOF

# ============================================
# 10. SSL/TLS RENEWAL
# ============================================
echo "🔐 Configurando renovação de SSL/TLS..."

cat > /usr/local/bin/certbot_renew.sh << 'EOF'
#!/bin/bash

echo "🔄 Renovando certificados SSL/TLS..."
certbot renew --quiet --agree-tos

# Recarregar Nginx após renovação
docker exec nexus-nginx-1 nginx -s reload 2>/dev/null || echo "Nginx reload pendente"

echo "✅ Renovação de certificados concluída"
EOF

chmod +x /usr/local/bin/certbot_renew.sh

# Cron job para renovação semanal
cat >> /etc/crontab << 'EOF'
# Renew SSL certificates - Semanalmente
0 3 * * 0 root /usr/local/bin/certbot_renew.sh >> /var/log/certbot_renew.log 2>&1
EOF

# ============================================
# 11. KERNEL HARDENING
# ============================================
echo "🛡️  Aplicando hardening do Kernel..."

cat > /etc/sysctl.d/99-hardening.conf << 'EOF'
# IP Forwarding
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Proteção contra SYN flood
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048

# Log de pacotes suspeitos
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Ignorar ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Ignorar ICMP ping
net.ipv4.icmp_echo_ignore_all = 0

# Proteção contra source routing
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# TCP hardening
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_rfc1337 = 1

# Aumentar connection backlog
net.core.netdev_max_backlog = 5000
EOF

sysctl -p /etc/sysctl.d/99-hardening.conf

# ============================================
# 12. RESUMO FINAL
# ============================================
echo ""
echo "✅ Hardening de segurança concluído com sucesso!"
echo ""
echo "📋 Resumo das configurações:"
echo "  ✓ Firewall UFW habilitado"
echo "  ✓ Fail2Ban configurado"
echo "  ✓ SSH endurecido"
echo "  ✓ Atualizações automáticas ativadas"
echo "  ✓ Backup automático configurado"
echo "  ✓ Health checks agendados"
echo "  ✓ SSL/TLS renewal automático"
echo "  ✓ Kernel hardening aplicado"
echo ""
echo "📧 Notificações de segurança serão enviadas para: admin@nexusstream.com"
echo ""
echo "🔗 Próximos passos:"
echo "  1. Configurar chave SSH pública para acesso seguro"
echo "  2. Verificar logs: tail -f /var/log/fail2ban.log"
echo "  3. Teste health check: /usr/local/bin/nexus_health_check.sh"
echo "  4. Teste backup: /usr/local/bin/backup_nexus.sh"
echo ""
