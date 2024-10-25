#!/bin/bash

echo "1. Terminating all blitz64 processes and malicious kswapd0 processes run by user debian..."

# Terminate any blitz64 process
pkill -f blitz64

# Terminate kswapd0 process if it's run by user debian
pkill -u debian -f kswapd0

echo "2. Clearing crontab entries for root and debian..."
crontab -r -u root
crontab -r -u debian

echo "3. Removing kswapd0 and blitz64 files..."
find / -type f \( -name "kswapd0" -o -name "blitz64" \) -exec rm -f {} + 2>/dev/null

echo "4. Cleaning up temporary directories /tmp and /var/tmp..."
rm -rf /tmp/* /var/tmp/*

echo "5. Setting up noexec and nosuid mount options for /tmp and /var/tmp..."
if ! grep -q "tmpfs /tmp" /etc/fstab; then
   echo "tmpfs /tmp tmpfs defaults,noexec,nosuid 0 0" >> /etc/fstab
   echo "tmpfs /var/tmp tmpfs defaults,noexec,nosuid 0 0" >> /etc/fstab
fi

echo "Creating and mounting /tmp and /var/tmp with noexec and nosuid options..."
mkdir -p /tmp /var/tmp
mount -t tmpfs -o defaults,noexec,nosuid tmpfs /tmp
mount -t tmpfs -o defaults,noexec,nosuid tmpfs /var/tmp

echo "6. Installing and configuring Fail2ban to protect SSH..."
apt install fail2ban -y

cat <<EOL > /etc/fail2ban/jail.local
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
findtime = 600
EOL

systemctl restart fail2ban

echo "7. Updating system packages..."
apt update && apt upgrade -y

echo "All tasks completed."
