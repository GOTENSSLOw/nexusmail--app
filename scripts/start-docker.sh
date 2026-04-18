#!/usr/bin/env bash
#
# scripts/start-docker.sh - Docker Compose wrapper for NexusMail
#
# Usage: start-docker.sh [OPTIONS]
#
# Options:
#   (no args)   Start all services (build + up)
#   --stop      Stop all services (docker compose down)
#   --status    Show container status
#   --logs      Follow logs for all services
#   --rebuild   Force rebuild all images before starting
#   --help      Show this help

set -euo pipefail

# Detect script directory and source lib.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

# =============================================================================
# Help
# =============================================================================

show_help() {
    header "NexusMail Docker Launcher"
    echo ""
    echo "Usage: start-docker.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  (no args)   Start all services (build + up)"
    echo "  --stop      Stop all services (docker compose down)"
    echo "  --status    Show container status"
    echo "  --logs      Follow logs for all services"
    echo "  --rebuild   Force rebuild all images before starting"
    echo "  --help      Show this help"
    echo ""
}

# =============================================================================
# Docker dependency check
# =============================================================================

check_dependencies() {
    header "Checking dependencies"
    
    if ! check_docker_deps; then
        error "Docker dependencies check failed"
        exit 1
    fi
    
    ok "Docker dependencies OK"
}

# =============================================================================
# Wait for init container to complete
# =============================================================================

wait_for_init() {
    header "Waiting for init container"
    
    local max_wait=120
    local elapsed=0
    local interval=2
    
    while (( elapsed < max_wait )); do
        # Check if init container has exited
        local status
        status=$(docker compose ps init --format json 2>/dev/null | \
            docker compose ps init --format '{{.State}}' 2>/dev/null || echo "running")
        
        if [[ "$status" == "exited" ]]; then
            ok "Init container completed"
            return 0
        fi
        
        info "Waiting for init container... (${elapsed}s/${max_wait}s)"
        sleep "$interval"
        elapsed=$((elapsed + interval))
    done
    
    error "Init container did not complete within ${max_wait}s"
    return 1
}

# =============================================================================
# Wait for Django to be ready
# =============================================================================

wait_for_django() {
    header "Waiting for Django to be ready"
    
    local host="localhost"
    local port="8000"
    local timeout="60"
    
    info "Checking if Django is responding on ${host}:${port}"
    
    if wait_for_port "$port" "$timeout"; then
        ok "Django is ready"
        return 0
    else
        error "Django did not become ready within ${timeout}s"
        return 1
    fi
}

# =============================================================================
# Show status table
# =============================================================================

show_status_table() {
    header "Container Status"
    
    echo ""
    printf "%-15s %-12s %-25s\n" "CONTAINER" "STATUS" "PORTS"
    printf "%-15s %-12s %-25s\n" "---------" "------" "-----"
    
    # Get container info
    local containers
    containers=$(docker compose ps --format json 2>/dev/null || docker compose ps 2>/dev/null)
    
    # Parse and display status (works with both json and table format)
    while IFS= read -r line; do
        if [[ "$line" =~ \{.*\} ]]; then
            # JSON format
            local name status ports
            name=$(echo "$line" | docker compose ps init --format '{{.Name}}' 2>/dev/null || echo "unknown")
            status=$(echo "$line" | docker compose ps init --format '{{.State}}' 2>/dev/null || echo "unknown")
            # For ports, we need to get from docker compose ps
            printf "%-15s %-12s %-25s\n" "$name" "$status" "see compose"
        else
            # Table format - parse columns
            local name status ports
            name=$(echo "$line" | awk '{print $1}' | head -1)
            status=$(echo "$line" | awk '{print $NF}' | head -1)
            ports=$(echo "$line" | grep -oP '\d+:\d+' | tr '\n' ',' | sed 's/,$//')
            if [[ -n "$name" && "$name" != "CONTAINER" ]]; then
                printf "%-15s %-12s %-25s\n" "$name" "$status" "${ports:-—}"
            fi
        fi
    done <<< "$containers"
    
    echo ""
}

# =============================================================================
# Show service URLs
# =============================================================================

show_service_urls() {
    echo ""
    header "Services Running"
    echo ""
    echo "  Frontend:  http://localhost:5173"
    echo "  Django:     http://localhost:8000"
    echo "  SMTP:       localhost:25"
    echo "  IMAP:       localhost:143"
    echo "  IMAP (pop): localhost:110"
    echo ""
    ok "All services are running"
    echo ""
}

# =============================================================================
# Start services
# =============================================================================

start_services() {
    local rebuild=false
    if [[ "${1:-}" == "--rebuild" ]]; then
        rebuild=true
    fi
    
    header "Starting NexusMail services"
    
    # Check dependencies
    check_dependencies
    
    # Load environment
    info "Loading environment from .env"
    load_env
    
    # Build if needed
    if $rebuild; then
        header "Building images (no cache)"
        info "docker compose build --no-cache"
        if ! docker compose build --no-cache; then
            error "Build failed"
            exit 1
        fi
        ok "Build complete"
    else
        header "Building images (if needed)"
        info "docker compose build"
        if ! docker compose build; then
            error "Build failed"
            exit 1
        fi
        ok "Build complete"
    fi
    
    # Start services
    header "Starting services"
    info "docker compose up -d"
    if ! docker compose up -d; then
        error "Failed to start services"
        exit 1
    fi
    ok "Services started"
    
    # Wait for init container
    if ! wait_for_init; then
        error "Init container failed"
        error "Check logs with: docker compose logs init"
        exit 1
    fi
    
    # Wait for Django
    if ! wait_for_django; then
        error "Django failed to become ready"
        error "Check logs with: docker compose logs django"
        exit 1
    fi
    
    # Show status
    show_status_table
    show_service_urls
}

# =============================================================================
# Stop services
# =============================================================================

stop_services() {
    header "Stopping NexusMail services"
    
    info "docker compose down"
    if ! docker compose down; then
        error "Failed to stop services"
        exit 1
    fi
    
    ok "All services stopped"
}

# =============================================================================
# Show status
# =============================================================================

show_status() {
    header "NexusMail Service Status"
    echo ""
    
    info "docker compose ps"
    echo ""
    docker compose ps
    echo ""
    
    show_status_table
}

# =============================================================================
# Show logs
# =============================================================================

show_logs() {
    header "Following logs (Ctrl+C to exit)"
    echo ""
    
    docker compose logs -f
}

# =============================================================================
# Main
# =============================================================================

main() {
    case "${1:-}" in
        --stop)
            stop_services
            ;;
        --status)
            show_status
            ;;
        --logs)
            show_logs
            ;;
        --rebuild)
            start_services --rebuild
            ;;
        --help|-h)
            show_help
            ;;
        "")
            start_services
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
