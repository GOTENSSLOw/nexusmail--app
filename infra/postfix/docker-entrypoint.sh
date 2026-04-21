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

# --- Register system users into Postfix's /etc/passwd ---
# Postfix needs users in its own /etc/passwd to deliver mail locally
# Use USERS env var (comma-separated) for explicit registration
IFS=',' read -ra USER_LIST <<< "${USERS:-user1,user2,user3}"
next_uid=1000
for username in "${USER_LIST[@]}"; do
    username=$(echo "$username" | xargs) # trim whitespace
    if id "$username" &>/dev/null; then
        echo "User $username already exists"
    else
        useradd -m -u "$next_uid" -s /sbin/nologin "$username" 2>/dev/null || true
        echo "Registered user: $username (uid=$next_uid)"
    fi
    next_uid=$((next_uid + 1))
done

# --- Ensure Maildir structure for users ---
for username in "${USER_LIST[@]}"; do
    username=$(echo "$username" | xargs)
    userdir="/home/$username"
    mkdir -p "$userdir/Maildir"/{cur,new,tmp}
    chown -R "$username:$username" "$userdir/Maildir" 2>/dev/null || true
    chmod -R 700 "$userdir/Maildir" 2>/dev/null || true
    echo "Ensured Maildir for: $username"
done

echo "=== Postfix Init Done ==="

# Execute the CMD
exec "$@"
