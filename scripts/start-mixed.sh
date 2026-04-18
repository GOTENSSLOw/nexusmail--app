#!/usr/bin/env bash
#
# scripts/start-mixed.sh - Mixed development startup script for NexusMail
#
# Starts backend services (Postfix, Dovecot, Django) with Vite frontend in FOREGROUND.
# Backend runs in background, frontend runs in foreground for hot-reload visibility.
#
# Usage: start-mixed.sh [OPTIONS]
#
# Options:
#   (no args)   Start backend services + frontend dev server (foreground)
#   --stop      Stop all services
#   --status    Show what's running
#   --logs      Follow logs
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
    header "NexusMail Mixed Launcher (Dev Mode)"
    echo ""
    echo "Usage: start-mixed.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  (no args)   Start backend + frontend dev server (foreground)"
    echo "  --stop      Stop all services"
    echo "  --status    Show what's running"
    echo "  --logs      Follow logs"
    echo "  --help      Show this help"
    echo ""
    echo "Services: Postfix (SMTP), Dovecot (IMAP), Django (API), Frontend (Vite)"
    echo ""
    echo "NOTE: Frontend runs in FOREGROUND for hot-reload visibility."
    echo "      Backend services run in background."
    echo "      Press Ctrl+C to stop all services."
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
# Start Django (background)
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
    
    cd "$backend_dir"
    
    # Start Django in background, redirect output to log file
    nohup python3 manage.py runserver 0.0.0.0:8000 >> "$log_file" 2>&1 &
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
# Kill Django
# =============================================================================

kill_django() {
    if is_running "django"; then
        kill_service "django"
    else
        info "Django is not running"
    fi
}

# =============================================================================
# Kill Vite/Node process on port 5173
# =============================================================================

kill_frontend_vite() {
    header "Stopping Vite/Frontend"
    
    # Find and kill any process on port 5173
    if command -v lsof &>/dev/null; then
        local vite_pids
        vite_pids=$(lsof -ti :5173 2>/dev/null || true)
        if [[ -n "$vite_pids" ]]; then
            for pid in $vite_pids; do
                info "Killing process on port 5173 (PID: $pid)"
                kill "$pid" 2>/dev/null || true
            done
            ok "Vite processes killed"
        else
            info "No process found on port 5173"
        fi
    elif command -v fuser &>/dev/null; then
        fuser -k 5173/tcp 2>/dev/null || true
        ok "Vite process killed via fuser"
    else
        # Fallback: kill by process name
        pkill -f "vite" 2>/dev/null || true
        pkill -f "node.*5173" 2>/dev/null || true
        ok "Vite processes killed"
    fi
    
    # Remove PID file if exists
    rm -f "${PROJECT_ROOT}/${PID_DIR}/frontend.pid" 2>/dev/null || true
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
    
    # Frontend (check port instead of PID since it runs in foreground)
    if lsof -ti :5173 &>/dev/null || ss -tlnp 2>/dev/null | grep -q ":5173 "; then
        printf "%-12s %-10s %-8s %s\n" "frontend" "active" "5173" "(foreground)"
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
    
    kill_django
    kill_frontend_vite
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
        echo "--- System logs (postfix, dovecot) ---"
        sudo journalctl -u postfix -u dovecot -f --no-pager &
        local journal_pid=$!
        
        echo ""
        echo "--- Django log ---"
        if [[ -f "${log_dir}/django.log" ]]; then
            tail -f "${log_dir}/django.log" &
        else
            echo "(no django.log found)"
        fi
        
        # Wait for signals (logs are followed)
        wait
    else
        info "No systemd detected, showing application logs only"
        echo ""
        echo "--- Django log ---"
        tail -f "${log_dir}/django.log" 2>/dev/null &
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
# Start all services
# =============================================================================

start_all() {
    header "Starting NexusMail services (Mixed Dev Mode)"
    
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
    
    # Start Django (background)
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
    
    # Start Frontend (FOREGROUND - key difference from start-vm.sh)
    header "Starting Frontend (FOREGROUND mode)"
    
    local frontend_dir="${PROJECT_ROOT}/frontend"
    
    if ! [[ -d "$frontend_dir" ]]; then
        error "Frontend directory not found: $frontend_dir"
        exit 1
    fi
    
    info "Frontend running in FOREGROUND for hot-reload visibility"
    info "Press Ctrl+C to stop all services"
    echo ""
    
    # Set up trap for cleanup on EXIT/INT
    trap 'info "Stopping services..."; kill_django; kill_frontend_vite; stop_postfix; stop_dovecot; ok "All stopped"' EXIT INT
    
    cd "$frontend_dir"
    
    # Run Vite in FOREGROUND (will block until Ctrl+C)
    npm run dev -- --host 0.0.0.0 --port 5173
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
