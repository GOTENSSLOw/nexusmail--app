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
    
    # Create Django user (for API authentication)
    python manage.py shell -c "
from django.contrib.auth.models import User
if not User.objects.filter(username='$user').exists():
    User.objects.create_user('$user', '$user@${MAIL_DOMAIN:-lan.local}', '$pass')
    print('Created Django user: $user')
else:
    print('Django user $user already exists')
"
    
    echo "Created system user: $user"
done

# Generate Dovecot-compatible passwd file to shared volume
mkdir -p /etc/userdb
> /etc/userdb/passwd

for i in "${!USERS_ARR[@]}"; do
    user="${USERS_ARR[$i]}"
    pass="${PASS_ARR[$i]}"
    
    # Get the user's UID and GID
    uid=$(id -u "$user")
    gid=$(id -g "$user")
    
    # Generate Dovecot passwd entry with CRYPT scheme
    # Dovecot passwd format: user:{scheme}password:uid:gid:gecos:home:shell
    crypt_pass=$(python3 -c "import crypt; print(crypt.crypt('$pass'))")
    echo "$user:${CRYPT}$crypt_pass:$uid:$gid::/home/$user:/bin/bash" >> /etc/userdb/passwd
done

chmod 644 /etc/userdb/passwd
echo "Generated /etc/userdb/passwd for Dovecot authentication"

echo "=== Init Container: Done ==="
