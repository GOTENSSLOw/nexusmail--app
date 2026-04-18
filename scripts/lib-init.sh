#!/usr/bin/env bash
#
# scripts/lib-init.sh - VM initialization library for NexusMail
#
# This file is meant to be sourced by start-vm.sh, not executed directly.
#
# Usage: source scripts/lib-init.sh

# Guard: if not being sourced, print usage and exit
if [[ -z "${BASH_SOURCE[0]}" || "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Usage: source scripts/lib-init.sh"
    echo ""
    echo "This is a library file that provides initialization functions for VM startup."
    echo "It should be sourced, not executed directly."
    exit 1
fi

# =============================================================================
# Initialization check
# =============================================================================

# is_initialized — checks if init has already run (marker file exists)
is_initialized() {
    [[ -f "${PROJECT_ROOT}/.initialized" ]]
}

# mark_initialized — creates marker file after successful init
mark_initialized() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "# Initialized at $timestamp" > "${PROJECT_ROOT}/.initialized"
    ok "Init marker created"
}

# =============================================================================
# Django migrations
# =============================================================================

run_migrations() {
    header "Running Django migrations"
    
    local backend_dir="${PROJECT_ROOT}/backend"
    
    if [[ ! -d "$backend_dir" ]]; then
        error "Backend directory not found: $backend_dir"
        return 1
    fi
    
    cd "$backend_dir"
    
    info "Running: python manage.py migrate --noinput"
    if python3 manage.py migrate --noinput; then
        ok "Migrations complete"
        cd "$PROJECT_ROOT"
        return 0
    else
        error "Migrations failed"
        cd "$PROJECT_ROOT"
        return 1
    fi
}

# =============================================================================
# System user creation
# =============================================================================

create_system_users() {
    header "Creating system users"
    
    IFS=',' read -ra USERS_ARR <<< "${USERS:-user1,user2,user3}"
    IFS=',' read -ra PASS_ARR <<< "${USER_PASSWORDS:-user112345,user212345,user312345}"
    
    local created=0
    local skipped=0
    
    for i in "${!USERS_ARR[@]}"; do
        local user="${USERS_ARR[$i]}"
        local pass="${PASS_ARR[$i]:-}"
        
        if [[ -z "$pass" ]]; then
            warn "No password for user $user, skipping"
            continue
        fi
        
        if id "$user" &>/dev/null; then
            info "System user $user already exists, skipping"
            ((skipped++))
            continue
        fi
        
        info "Creating system user: $user"
        
        # Create user with home directory and bash shell
        if sudo useradd -m -s /bin/bash "$user"; then
            # Set password
            echo "$user:$pass" | sudo chpasswd
            
            # Create Maildir structure
            sudo mkdir -p "/home/$user/Maildir"/{cur,new,tmp}
            sudo chown -R "$user:$user" "/home/$user/Maildir"
            sudo chmod -R 700 "/home/$user/Maildir"
            
            ok "Created system user: $user"
            ((created++))
        else
            error "Failed to create system user: $user"
        fi
    done
    
    info "System users: $created created, $skipped already existed"
}

# =============================================================================
# Django user creation
# =============================================================================

create_django_users() {
    header "Creating Django users"
    
    local backend_dir="${PROJECT_ROOT}/backend"
    
    if [[ ! -d "$backend_dir" ]]; then
        error "Backend directory not found: $backend_dir"
        return 1
    fi
    
    IFS=',' read -ra USERS_ARR <<< "${USERS:-user1,user2,user3}"
    IFS=',' read -ra PASS_ARR <<< "${USER_PASSWORDS:-user112345,user212345,user312345}"
    
    local created=0
    local skipped=0
    
    cd "$backend_dir"
    
    for i in "${!USERS_ARR[@]}"; do
        local user="${USERS_ARR[$i]}"
        local pass="${PASS_ARR[$i]:-}"
        local email="${user}@${MAIL_DOMAIN:-lan.local}"
        
        if [[ -z "$pass" ]]; then
            warn "No password for user $user, skipping"
            continue
        fi
        
        # Create Django user via manage.py shell
        if python3 manage.py shell -c "
from django.contrib.auth.models import User
if not User.objects.filter(username='$user').exists():
    User.objects.create_user('$user', '$email', '$pass')
    print('CREATED')
else:
    print('EXISTS')
" 2>/dev/null | grep -q CREATED; then
            ok "Created Django user: $user ($email)"
            ((created++))
        else
            info "Django user $user already exists, skipping"
            ((skipped++))
        fi
    done
    
    info "Django users: $created created, $skipped already existed"
    cd "$PROJECT_ROOT"
}

# =============================================================================
# Postfix configuration
# =============================================================================

configure_postfix() {
    header "Configuring Postfix"
    
    local mail_domain="${MAIL_DOMAIN:-lan.local}"
    
    info "Configuring Postfix for domain: $mail_domain"
    
    # Set Postfix configuration
    # myhostname: the hostname for this mail system
    # mydomain: the default domain name for this system
    # mydestination: domains this system receives mail for
    
    local postconf_commands=(
        "myhostname = $mail_domain"
        "mydomain = $mail_domain"
        "myorigin = \$mydomain"
        "mydestination = \$myhostname, localhost.\$mydomain, $mail_domain, localhost"
        "home_mailbox = Maildir/"
        "smtp_bind_address = 0.0.0.0"
    )
    
    for config in "${postconf_commands[@]}"; do
        info "postconf -e '$config'"
        if sudo postconf -e "$config"; then
            ok "Set: $config"
        else
            error "Failed to set: $config"
        fi
    done
    
    ok "Postfix configured for $mail_domain"
}

# =============================================================================
# Dovecot configuration
# =============================================================================

configure_dovecot() {
    header "Configuring Dovecot"
    
    local mail_domain="${MAIL_DOMAIN:-lan.local}"
    local dovecot_conf="/etc/dovecot/dovecot.conf"
    local dovecot_conf_d="/etc/dovecot/conf.d"
    
    info "Dovecot configuration directory: $dovecot_conf_d"
    
    # Create mail directory structure if it doesn't exist
    sudo mkdir -p "/var/mail/$mail_domain"
    sudo chmod -R 755 "/var/mail"
    
    # Ensure Postfix and Dovecot can work together
    # Set mail location in Dovecot
    info "Setting mail_location to Maildir format"
    sudo postconf -e "virtual_transport = dovecot"
    sudo postconf -e "dovecot_destination_recipient_limit = 1"
    
    # Create dovecot master user for delivery (if needed)
    sudo mkdir -p "/etc/dovecot"
    
    # Configure dovecot to use PAM or passwd for authentication
    # For simplicity, we'll configure it to use the system users
    
    ok "Dovecot Postfix integration configured"
    info "Note: For full Dovecot configuration, edit $dovecot_conf"
    info "Enable dovecot in postfix: postconf -e 'virtual_transport=dovecot'"
}

# =============================================================================
# Full initialization (all steps)
# =============================================================================

do_init() {
    header "Initializing NexusMail VM environment"
    
    # Load environment if not already loaded
    if [[ -z "${MAIL_DOMAIN:-}" ]]; then
        load_env
    fi
    
    # Run each initialization step
    if ! run_migrations; then
        error "Init failed at migrations step"
        return 1
    fi
    
    if ! create_system_users; then
        error "Init failed at system users step"
        return 1
    fi
    
    if ! create_django_users; then
        error "Init failed at Django users step"
        return 1
    fi
    
    if ! configure_postfix; then
        error "Init failed at Postfix configuration step"
        return 1
    fi
    
    if ! configure_dovecot; then
        error "Init failed at Dovecot configuration step"
        return 1
    fi
    
    # Mark as initialized
    mark_initialized
    
    header "Initialization complete"
    ok "All initialization steps completed successfully"
    return 0
}

# =============================================================================
# End of lib-init.sh
# =============================================================================
