#!/bin/bash
set -e

echo "=== Postfix Init ==="

MAIL_DOMAIN="${maildomain:-lan.local}"
echo "Mail domain: $MAIL_DOMAIN"

# --- Generate main.cf from template ---
sed "s/\${MAIL_DOMAIN}/$MAIL_DOMAIN/g" /etc/postfix/main.cf.template > /etc/postfix/main.cf

# --- Fix aliases database ---
# Alpine Postfix uses lmdb by default but the file doesn't exist
touch /etc/postfix/aliases
postmap lmdb:/etc/postfix/aliases 2>/dev/null || true

# --- Register system users from /home into Postfix's /etc/passwd ---
# Postfix needs users in its own /etc/passwd to deliver mail locally
if [ -d /home ]; then
    next_uid=1000
    for userdir in /home/*; do
        if [ -d "$userdir" ]; then
            username=$(basename "$userdir")
            
            # Skip if user already exists
            if id "$username" &>/dev/null; then
                echo "User $username already exists"
            else
                # Create system user with matching UID
                useradd -m -u "$next_uid" -s /sbin/nologin "$username" 2>/dev/null || true
                echo "Registered user: $username (uid=$next_uid)"
            fi
            next_uid=$((next_uid + 1))
        fi
    done
fi

# --- Ensure Maildir structure for users ---
if [ -d /home ]; then
    for userdir in /home/*; do
        if [ -d "$userdir" ]; then
            username=$(basename "$userdir")
            mkdir -p "$userdir/Maildir"/{cur,new,tmp}
            chown -R "$username:$username" "$userdir/Maildir" 2>/dev/null || true
            chmod -R 700 "$userdir/Maildir" 2>/dev/null || true
            echo "Ensured Maildir for: $username"
        fi
    done
fi

echo "=== Postfix Init Done ==="

# Execute the CMD
exec "$@"
