#!/bin/bash
set -e

BACKUP_DIR="/var/lib/backups/data"

echo "Creating users and configuring accounts…"
useradd -m -s /bin/bash sysadmin || true
echo "sysadmin:sysadmin" | chpasswd
usermod -aG sudo sysadmin

useradd -r -m -s /bin/false automation_bot || true

useradd -m -s /bin/bash auditor || true
echo "auditor:auditor" | chpasswd
usermod -aG adm auditor

echo "Creating permissions…"
chown -R automation_bot:automation_bot /var/lib/backups
chmod 700 ${BACKUP_DIR}

echo "SSH setup and environment preparation…"
mkdir -p /home/automation_bot/.ssh
chmod 700 /home/automation_bot/.ssh
chown -R automation_bot:automation_bot /home/automation_bot/.ssh

touch /home/automation_bot/.ssh/authorized_keys
chmod 600 /home/automation_bot/.ssh/authorized_keys
chown automation_bot:automation_bot /home/automation_bot/.ssh/authorized_keys

echo "Backup node successfully configured!"
