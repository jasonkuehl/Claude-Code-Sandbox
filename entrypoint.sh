#!/bin/bash
set -e

mkdir -p /etc/ssh/keys

for type in rsa ecdsa ed25519; do
    keyfile="/etc/ssh/keys/ssh_host_${type}_key"
    if [ ! -f "$keyfile" ]; then
        ssh-keygen -t "$type" -f "$keyfile" -N ""
    fi
done

if [ -z "${SSH_PASSWORD:-}" ] || [ "$SSH_PASSWORD" = "changeme" ]; then
    echo "WARNING: SSH_PASSWORD is unset or still 'changeme'; set it in .env" >&2
fi
echo "root:${SSH_PASSWORD:-changeme}" | chpasswd

exec /usr/sbin/sshd -D -e
