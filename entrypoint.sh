#!/bin/bash
set -e

mkdir -p /etc/ssh/keys

for type in rsa ecdsa ed25519; do
    keyfile="/etc/ssh/keys/ssh_host_${type}_key"
    if [ ! -f "$keyfile" ]; then
        ssh-keygen -t "$type" -f "$keyfile" -N ""
    fi
done

exec /usr/sbin/sshd -D -e
