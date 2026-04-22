#!/usr/bin/env bash
#
# scripts/start-vm.sh - VM native startup script for NexusMail
#
# Starts Postfix, Dovecot, Django, and Frontend as native services on a VM/server.
#
# Usage: start-vm.sh [OPTIONS]
#
# Options:
#   (no args)   Start all services
#   --stop      Stop all services
#   --status    Show what's running
#   --logs      Follow logs
#   --init      Run initialization only (migrations, users, config)
#   --help      Show this help

set -euo pipefail

# Detect script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"
source "${SCRIPT_DIR}/lib-init.sh"

# =============================================================================
# Help
# =============================================================================

show_help() {
    header "NexusMail VM Launcher"
    echo ""
    echo "Usage: start-vm.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  (no args)   Start all services"
    echo "  --stop      Stop all services"
    echo "  --status    Show what's running"
    echo "  --logs      Follow logs"
    echo "  --init      Run initialization only (migrations, users, config)"
    echo "  --help      Show this help"
    echo ""
    echo "Services: Postfix (SMTP), Dovecot (IMAP), Django (API), Frontend (React)"
    echo ""
}

# =============================================================================
# Dependency check
# =============================================================================

check_dependencies() {
    header "Checking VM dependencies"
    
    if ! check_vm_deps; then
        error "VM dependencies check failed"
        exit 1
    fi
    
    ok "All VM dependencies found"
}

# =============================================================================
# Systemd availability check
# =============================================================================

has_systemd() {
    if command -v systemctl &>/dev/null && [[ -d /run/systemd/system ]]; then
        return 0
    fi
    return 1
}

# =============================================================================
# Start Postfix
# =============================================================================

start_postfix() {
    header "Starting Postfix"
    
    if has_systemd; then
        info "Using systemd: sudo systemctl start postfix"
        if sudo systemctl start postfix; then
            ok "Postfix started via systemd"
        else
            error "Failed to start Postfix via systemd"
            return 1
        fi
    else
        info "No systemd detected, using postfix directly"
        # Try to start postfix directly (for non-systemd systems)
        if sudo postfix start 2>/dev/null || sudo postfix reload 2>/dev/null; then
            ok "Postfix started"
        else
            error "Failed to start Postfix"
            return 1
        fi
    fi
}

# =============================================================================
# Stop Postfix
# =============================================================================

stop_postfix() {
    header "Stopping Postfix"
    
    if has_systemd; then
        info "Using systemd: sudo systemctl stop postfix"
        sudo systemctl stop postfix 2>/dev/null || true
        ok "Postfix stopped"
    else
        info "Using postfix stop"
        sudo postfix stop 2>/dev/null || sudo postfix flush 2>/dev/null || true
        ok "Postfix stopped"
    fi
}

# =============================================================================
# Start Dovecot
# =============================================================================

start_dovecot() {
    header "Starting Dovecot"
    
    if has_systemd; then
        info "Using systemd: sudo systemctl start dovecot"
        if sudo systemctl start dovecot; then
            ok "Dovecot started via systemd"
        else
            error "Failed to start Dovecot via systemd"
            return 1
        fi
    else
        info "No systemd detected, using dovecot directly"
        if sudo dovecot 2>/dev/null; then
            ok "Dovecot started"
        else
            error "Failed to start Dovecot"
            return 1
        fi
    fi
}

# =============================================================================
# Stop Dovecot
# =============================================================================

stop_dovecot() {
    header "Stopping Dovecot"
    
    if has_systemd; then
        info "Using systemd: sudo systemctl stop dovecot"
        sudo systemctl stop dovecot 2>/dev/null || true
        ok "Dovecot stopped"
    else
        info "Using kill for dovecot"
        sudo pkill dovecot 2>/dev/null || true
        ok "Dovecot stopped"
    fi
}

# =============================================================================
# Start Django
# =============================================================================

start_django() {
    header "Starting Django"
    
    local backend_dir="${PROJECT_ROOT}/backend"
    local log_file="${PROJECT_ROOT}/${LOG_DIR}/django.log"
    
    if ! [[ -d "$backend_dir" ]]; then
        error "Backend directory not found: $backend_dir"
        return 1
    fi
    
    # Check if already running
    if is_running "django"; then
        warn "Django is already running (PID: $(get_pid django))"
        return 0
    fi
    
    info "Starting Django on 0.0.0.0:8000"
    info "Log file: $log_file"

    # Ensure log directory exists before nohup tries to write
    mkdir -p "$(dirname "$log_file")"

    cd "$backend_dir"

    # Start Django in background, redirect output to log file
    nohup "${VENV_PYTHON}" manage.py runserver 0.0.0.0:8000 >> "$log_file" 2>&1 &
    local django_pid=$!
    
    cd "$PROJECT_ROOT"
    
    if [[ -n "$django_pid" ]]; then
        save_pid "django" "$django_pid"
        ok "Django started (PID: $django_pid)"
    else
        error "Failed to start Django"
        return 1
    fi
}

# =============================================================================
# Stop Django
# =============================================================================

stop_django() {
    header "Stopping Django"
    
    if is_running "django"; then
        kill_service "django"
    else
        info "Django is not running"
    fi
}

# =============================================================================
# Start Frontend
# =============================================================================

start_frontend() {
    header "Starting Frontend"
    
    local frontend_dir="${PROJECT_ROOT}/frontend"
    local log_file="${PROJECT_ROOT}/${LOG_DIR}/frontend.log"
    
    if ! [[ -d "$frontend_dir" ]]; then
        error "Frontend directory not found: $frontend_dir"
        return 1
    fi
    
    # Check if already running
    if is_running "frontend"; then
        warn "Frontend is already running (PID: $(get_pid frontend))"
        return 0
    fi
    
    info "Starting Frontend on 0.0.0.0:5173"
    info "Log file: $log_file"

    # Ensure log directory exists before nohup tries to write
    mkdir -p "$(dirname "$log_file")"

    cd "$frontend_dir"

    # Install node_modules if missing
    if [[ ! -d "node_modules" ]]; then
        info "node_modules not found, running npm install..."
        if ! npm install >> "$log_file" 2>&1; then
            error "npm install failed — check $log_file"
            cd "$PROJECT_ROOT"
            return 1
        fi
        ok "npm install complete"
    fi

    # Start frontend in background, redirect output to log file
    nohup npm run dev -- --host 0.0.0.0 --port 5173 >> "$log_file" 2>&1 &
    local frontend_pid=$!
    
    cd "$PROJECT_ROOT"
    
    if [[ -n "$frontend_pid" ]]; then
        save_pid "frontend" "$frontend_pid"
        ok "Frontend started (PID: $frontend_pid)"
    else
        error "Failed to start Frontend"
        return 1
    fi
}

# =============================================================================
# Stop Frontend
# =============================================================================

stop_frontend() {
    header "Stopping Frontend"
    
    if is_running "frontend"; then
        kill_service "frontend"
    else
        info "Frontend is not running"
    fi
}

# =============================================================================
# Check Postfix status
# =============================================================================

check_postfix_status() {
    if has_systemd; then
        if sudo systemctl is-active postfix &>/dev/null; then
            echo "active"
            return 0
        else
            echo "inactive"
            return 1
        fi
    else
        # Check if postfix process is running
        if pgrep -x postfix &>/dev/null; then
            echo "active"
            return 0
        else
            echo "inactive"
            return 1
        fi
    fi
}

# =============================================================================
# Check Dovecot status
# =============================================================================

check_dovecot_status() {
    if has_systemd; then
        if sudo systemctl is-active dovecot &>/dev/null; then
            echo "active"
            return 0
        else
            echo "inactive"
            return 1
        fi
    else
        # Check if dovecot process is running
        if pgrep -x dovecot &>/dev/null; then
            echo "active"
            return 0
        else
            echo "inactive"
            return 1
        fi
    fi
}

# =============================================================================
# Show status table
# =============================================================================

show_status_table() {
    header "Service Status"
    
    echo ""
    printf "%-12s %-10s %-8s %s\n" "SERVICE" "STATUS" "PORT" "PID"
    printf "%-12s %-10s %-8s %s\n" "-------" "------" "----" "---"
    
    # Postfix
    local postfix_status
    postfix_status=$(check_postfix_status 2>/dev/null || echo "unknown")
    printf "%-12s %-10s %-8s %s\n" "postfix" "$postfix_status" "25" "-"
    
    # Dovecot
    local dovecot_status
    dovecot_status=$(check_dovecot_status 2>/dev/null || echo "unknown")
    printf "%-12s %-10s %-8s %s\n" "dovecot" "$dovecot_status" "143" "-"
    
    # Django
    if is_running "django"; then
        printf "%-12s %-10s %-8s %s\n" "django" "active" "8000" "$(get_pid django 2>/dev/null || echo '-')"
    else
        printf "%-12s %-10s %-8s %s\n" "django" "inactive" "8000" "-"
    fi
    
    # Frontend
    if is_running "frontend"; then
        printf "%-12s %-10s %-8s %s\n" "frontend" "active" "5173" "$(get_pid frontend 2>/dev/null || echo '-')"
    else
        printf "%-12s %-10s %-8s %s\n" "frontend" "inactive" "5173" "-"
    fi
    
    echo ""
}

# =============================================================================
# Show service URLs
# =============================================================================

show_service_urls() {
    echo ""
    header "Service URLs"
    echo ""
    echo "  Frontend:  http://localhost:5173"
    echo "  Django:     http://localhost:8000"
    echo "  SMTP:       localhost:25"
    echo "  IMAP:      localhost:143"
    echo ""
}

# =============================================================================
# Stop all services
# =============================================================================

stop_all() {
    header "Stopping all services"
    
    stop_django
    stop_frontend
    stop_postfix
    stop_dovecot
    
    # Remove PID files
    rm -f "${PROJECT_ROOT}/${PID_DIR}/"*.pid 2>/dev/null || true
    
    ok "All services stopped"
}

# =============================================================================
# Show logs
# =============================================================================

show_logs() {
    header "Following logs (Ctrl+C to exit)"
    echo ""
    
    local log_dir="${PROJECT_ROOT}/${LOG_DIR}"
    mkdir -p "$log_dir"
    
    if has_systemd; then
        info "Using journalctl for system services"
        # Combine journalctl for system services with tail for application logs
        echo "--- System logs (postfix, dovecot) ---"
        sudo journalctl -u postfix -u dovecot -f --no-pager &
        local journal_pid=$!
        
        echo ""
        echo "--- Application logs (django, frontend) ---"
        if [[ -f "${log_dir}/django.log" ]]; then
            tail -f "${log_dir}/django.log" &
        fi
        if [[ -f "${log_dir}/frontend.log" ]]; then
            tail -f "${log_dir}/frontend.log" &
        fi
        
        # Wait for signals (logs are followed)
        wait
    else
        info "No systemd detected, showing application logs only"
        echo ""
        echo "--- Django log ---"
        tail -f "${log_dir}/django.log" 2>/dev/null &
        echo ""
        echo "--- Frontend log ---"
        tail -f "${log_dir}/frontend.log" 2>/dev/null &
        echo ""
        echo "--- Postfix log ---"
        tail -f /var/log/mail.log 2>/dev/null &
        echo ""
        echo "--- Dovecot log ---"
        tail -f /var/log/dovecot.log 2>/dev/null &
        
        wait
    fi
}

# =============================================================================
# Run initialization only
# =============================================================================

run_init_only() {
    header "Running initialization only"
    
    check_dependencies
    load_env
    
    if is_initialized; then
        warn "System is already initialized"
        read -p "Re-initialize anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Skipping initialization"
            return 0
        fi
        # Remove old marker
        rm -f "${PROJECT_ROOT}/.initialized"
    fi
    
    if do_init; then
        ok "Initialization complete"
    else
        error "Initialization failed"
        exit 1
    fi
}

# =============================================================================
# Start all services
# =============================================================================

start_all() {
    header "Starting NexusMail services"
    
    # Check dependencies
    check_dependencies
    
    # Load environment
    info "Loading environment from .env"
    load_env
    
    # Run initialization if needed
    if ! is_initialized; then
        header "First-time initialization required"
        info "Running initialization (migrations, users, config)..."
        
        if ! do_init; then
            error "Initialization failed"
            exit 1
        fi
    else
        info "Initialization already complete, skipping"
    fi
    
    # Start system services
    if ! start_postfix; then
        error "Failed to start Postfix"
        exit 1
    fi
    
    if ! start_dovecot; then
        error "Failed to start Dovecot"
        exit 1
    fi
    
    # Wait for mail ports
    header "Waiting for mail services"
    if wait_for_port 25 10; then
        ok "SMTP (port 25) is listening"
    else
        warn "SMTP (port 25) may not be ready"
    fi
    
    if wait_for_port 143 10; then
        ok "IMAP (port 143) is listening"
    else
        warn "IMAP (port 143) may not be ready"
    fi
    
    # Start application services
    if ! start_django; then
        error "Failed to start Django"
        exit 1
    fi
    
    header "Waiting for Django"
    if wait_for_port 8000 30; then
        ok "Django (port 8000) is ready"
    else
        error "Django did not become ready within 30s"
        error "Check logs: ${PROJECT_ROOT}/${LOG_DIR}/django.log"
        exit 1
    fi
    
    if ! start_frontend; then
        error "Failed to start Frontend"
        exit 1
    fi
    
    header "Waiting for Frontend"
    if wait_for_port 5173 90; then
        ok "Frontend (port 5173) is ready"
    else
        error "Frontend did not become ready within 90s"
        error "Check logs: ${PROJECT_ROOT}/${LOG_DIR}/frontend.log"
        exit 1
    fi
    
    # Show status
    show_status_table
    show_service_urls
}

# =============================================================================
# Main
# =============================================================================

main() {
    case "${1:-}" in
        --stop)
            stop_all
            ;;
        --status)
            show_status_table
            ;;
        --logs)
            show_logs
            ;;
        --init)
            run_init_only
            ;;
        --help|-h)
            show_help
            ;;
        "")
            start_all
            ;;
        *)
            error "Unknown option: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
