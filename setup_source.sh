#!/bin/bash
set -e

REMOTE_HOST="192.168.64.6"
REMOTE_USER="automation_bot"

echo "Creating users and configuring accounts…"
useradd -m -s /bin/bash sysadmin || true
echo "sysadmin:sysadmin" | chpasswd
usermod -aG sudo sysadmin

useradd -r -M -s /bin/false backup-d || true
useradd -r -m -s /bin/false automation_bot || true

useradd -m -s /bin/bash auditor || true
echo "auditor:auditor" | chpasswd
usermod -aG adm auditor

echo "Creating archives directory and permissions…"
mkdir -p /var/lib/sources/archives

chown -R backup-d:backup-d /var/lib/sources/archives
chmod 700 /var/lib/sources/archives

chown -R root:backup-d /var/lib/sources
chmod 750 /var/lib/sources
chown -R root:backup-d /etc/sources
chmod 750 /etc/sources

chown automation_bot:automation_bot /home/automation_bot
chmod 750 /home/automation_bot

chown -R root:auditor /var/lib/sources/logs
chmod 750 /var/lib/sources/logs

echo "Configuring sudoers permissions for backup-d…"
echo "backup-d ALL=(ALL) NOPASSWD: /usr/bin/tar, /usr/bin/zstd" > /etc/sudoers.d/backup-d
chmod 440 /etc/sudoers.d/backup-d

if ! visudo -c; then
    echo "Error in sudoers!" 
    rm -f /etc/sudoers.d/backup-d
    exit 1
fi

echo "SSH setup and configuration…"
mkdir -p /home/automation_bot/.ssh
chmod 700 /home/automation_bot/.ssh
chown automation_bot:automation_bot /home/automation_bot/.ssh

if [ ! -f /home/automation_bot/.ssh/id_rsa ]; then
    su - automation_bot -s /bin/bash -c "ssh-keygen -N '' -f ~/.ssh/id_rsa"
fi

if ! ssh -o BatchMode=yes -o ConnectTimeout=5 ${REMOTE_USER}@${REMOTE_HOST} "exit" 2>/dev/null; then
    echo "Adding public key to remote host..."
    su - automation_bot -s /bin/bash -c "cat ~/.ssh/id_rsa.pub" | ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
fi

echo "Testing SSH connection…"
su - automation_bot -s /bin/bash -c "ssh -o BatchMode=yes ${REMOTE_USER}@${REMOTE_HOST} 'echo Connection successful!'"

echo "Creating the service…"
cat << 'EOF' > /usr/local/bin/app-source.sh
#!/bin/bash
LOG_FILE="/var/lib/sources/logs/app.log"

while true; do
    TIMESTAMP=$(date -u --iso-8601=seconds)
    echo "[$TIMESTAMP] App is running..." >> "$LOG_FILE"
    sleep 60
done
EOF

chmod +x /usr/local/bin/app-source.sh
chown automation_bot:automation_bot /usr/local/bin/app-source.sh

cat << 'EOF' > /etc/systemd/system/app-source.service
[Unit]
Description=Heartbeat Generator
After=network.target

[Service]
ExecStart=/usr/local/bin/app-source.sh
Restart=always
User=automation_bot

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable app-source.service
systemctl start app-source.service

echo "Source node successfully configured!"
