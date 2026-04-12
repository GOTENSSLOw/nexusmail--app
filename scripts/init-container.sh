#!/bin/bash
set -e

echo "=== Init Container: Setting up users and database ==="

cd /app

# Run migrations
python manage.py migrate --noinput

# Create Django superuser
DJANGO_SUPERUSER_PASSWORD=admin python manage.py createsuperuser --noinput --username admin --email admin@${MAIL_DOMAIN:-lan.local} 2>/dev/null || echo "Superuser already exists"

# Create system users
IFS=',' read -ra USERS_ARR <<< "${USERS:-user1,user2,user3}"
IFS=',' read -ra PASS_ARR <<< "${USER_PASSWORDS:-user112345,user212345,user312345}"

for i in "${!USERS_ARR[@]}"; do
    user="${USERS_ARR[$i]}"
    pass="${PASS_ARR[$i]}"
    
    if id "$user" &>/dev/null; then
        echo "User $user already exists, skipping"
        continue
    fi
    
    useradd -m -s /bin/bash "$user"
    echo "$user:$pass" | chpasswd
    
    mkdir -p "/home/$user/Maildir"/{cur,new,tmp}
    chown -R "$user:$user" "/home/$user/Maildir"
    chmod -R 700 "/home/$user/Maildir"
    
    echo "Created user: $user"
done

# Generate Dovecot-compatible passwd file to shared volume
mkdir -p /etc/userdb
USERS_COMMA="${USERS:-user1,user2,user3}"
USER_PATTERN=$(echo "$USERS_COMMA" | tr ',' '|')
grep -E "^($USER_PATTERN):" /etc/passwd > /etc/userdb/passwd
grep -E "^($USER_PATTERN):" /etc/shadow > /etc/userdb/shadow
chmod 600 /etc/userdb/shadow
echo "Generated /etc/userdb/passwd for Dovecot authentication"

echo "=== Init Container: Done ==="
