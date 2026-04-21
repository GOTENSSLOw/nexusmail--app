#!/usr/bin/env bash
#
# scripts/lib.sh - Core shared utilities library for NexusMail startup scripts
#
# This file is meant to be sourced by other scripts, not executed directly.
# If executed directly, it will print usage and exit.
#
# Usage: source scripts/lib.sh
#

# Guard: if not being sourced, print usage and exit
if [[ -z "${BASH_SOURCE[0]}" || "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Usage: source scripts/lib.sh"
    echo ""
    echo "This is a library file that provides common functions for startup scripts."
    echo "It should be sourced, not executed directly."
    exit 1
fi

# =============================================================================
# Configuration
# =============================================================================

PID_DIR=".pids"
LOG_DIR=".logs"

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
    COLOR_RESET='\033[0m'
    COLOR_BLUE='\033[0;34m'
    COLOR_GREEN='\033[0;32m'
    COLOR_RED='\033[0;31m'
    COLOR_YELLOW='\033[0;33m'
    COLOR_BOLD='\033[1m'
else
    COLOR_RESET=''
    COLOR_BLUE=''
    COLOR_GREEN=''
    COLOR_RED=''
    COLOR_YELLOW=''
    COLOR_BOLD=''
fi

# =============================================================================
# Color output functions
# =============================================================================

info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

ok() {
    echo -e "${COLOR_GREEN}[OK]${COLOR_RESET} $*"
}

error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*"
}

header() {
    echo -e "${COLOR_BOLD}=== $* ===${COLOR_RESET}"
}

# =============================================================================
# PID management
# =============================================================================

# Get the absolute path to the project root (where this script is sourced from)
_get_project_root() {
    local source="${BASH_SOURCE[0]}"
    while [[ -h "$source" ]]; do
        local dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    echo "$(cd -P "$(dirname "$source")/.." && pwd)"
}

# Resolve PROJECT_ROOT - set from environment or detect
PROJECT_ROOT="${PROJECT_ROOT:-$(_get_project_root)}"
export PROJECT_ROOT

_save_pid_file() {
    local service="$1"
    local pid="$2"
    local pid_dir="${PROJECT_ROOT}/${PID_DIR}"
    
    mkdir -p "$pid_dir"
    echo "$pid" > "${pid_dir}/${service}.pid"
}

_save_pid() {
    local service="$1"
    local pid="$2"
    
    if [[ -z "$service" || -z "$pid" ]]; then
        error "save_pid: requires <service> and <pid> arguments"
        return 1
    fi
    
    _save_pid_file "$service" "$pid"
}

# save_pid <service> <pid> — writes PID to .pids/<service>.pid
save_pid() {
    _save_pid "$@"
}

_get_pid() {
    local service="$1"
    
    if [[ -z "$service" ]]; then
        error "get_pid: requires <service> argument"
        return 1
    fi
    
    local pid_file="${PROJECT_ROOT}/${PID_DIR}/${service}.pid"
    
    if [[ ! -f "$pid_file" ]]; then
        return 1
    fi
    
    cat "$pid_file" 2>/dev/null
}

# get_pid <service> — reads PID from file
get_pid() {
    _get_pid "$@"
}

is_running() {
    local service="$1"
    
    if [[ -z "$service" ]]; then
        error "is_running: requires <service> argument"
        return 1
    fi
    
    local pid
    pid=$(get_pid "$service") || return 1
    
    if [[ -z "$pid" ]]; then
        return 1
    fi
    
    # Check if process with this PID exists and is running
    if kill -0 "$pid" 2>/dev/null; then
        return 0
    fi
    
    return 1
}

# is_running <service> — returns 0 if process with saved PID is alive
# Usage: if is_running "dovecot"; then ...

kill_service() {
    local service="$1"
    
    if [[ -z "$service" ]]; then
        error "kill_service: requires <service> argument"
        return 1
    fi
    
    if ! is_running "$service"; then
        warn "Service $service is not running"
        # Clean up stale PID file
        rm -f "${PROJECT_ROOT}/${PID_DIR}/${service}.pid" 2>/dev/null
        return 0
    fi
    
    local pid
    pid=$(get_pid "$service")
    
    if [[ -n "$pid" ]]; then
        kill "$pid" 2>/dev/null && ok "Killed service $service (PID: $pid)" || error "Failed to kill service $service"
    fi
    
    # Remove PID file
    rm -f "${PROJECT_ROOT}/${PID_DIR}/${service}.pid" 2>/dev/null
}

# kill_service <service> — kills process by saved PID

# =============================================================================
# Logging
# =============================================================================

_log_to_file() {
    local service="$1"
    local message="$2"
    local log_dir="${PROJECT_ROOT}/${LOG_DIR}"
    
    mkdir -p "$log_dir"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "${log_dir}/${service}.log"
}

# log_to_file <service> <message> — appends to .logs/<service>.log
log_to_file() {
    if [[ -z "$1" || -z "$2" ]]; then
        error "log_to_file: requires <service> and <message> arguments"
        return 1
    fi
    _log_to_file "$@"
}

# =============================================================================
# Environment loading
# =============================================================================

load_env() {
    local env_file="${PROJECT_ROOT}/.env"
    
    # Export PROJECT_ROOT as absolute path
    export PROJECT_ROOT
    
    if [[ ! -f "$env_file" ]]; then
        warn "No .env file found at ${env_file}, using defaults"
    else
        # Source the .env file if it exists
        set -a  # Auto-export sourced variables
        source "$env_file"
        set +a
    fi
    
    # Set defaults if not already set
    : "${MAIL_DOMAIN:=lan.local}"
    : "${USERS:=user1,user2,user3}"
    : "${USER_PASSWORDS:=user112345,user212345,user312345}"
    
    export MAIL_DOMAIN USERS USER_PASSWORDS
}

# load_env — Sources .env from project root if it exists
# Sets defaults: MAIL_DOMAIN=lan.local, USERS=user1,user2,user3, etc.
# Exports PROJECT_ROOT (absolute path to project)

# =============================================================================
# Dependency checking
# =============================================================================

require_cmd() {
    local cmd="$1"
    
    if [[ -z "$cmd" ]]; then
        error "require_cmd: requires <command> argument"
        return 1
    fi
    
    if ! command -v "$cmd" &>/dev/null; then
        error "Required command not found: $cmd"
        error "Please install $cmd or add it to your PATH"
        return 1
    fi
    
    return 0
}

# require_cmd <command> — exits with error if command not found

check_vm_deps() {
    local missing=()
    
    for cmd in python3 node npm postfix dovecot; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing VM dependencies: ${missing[*]}"
        error "Please install the missing dependencies"
        return 1
    fi
    
    return 0
}

# check_vm_deps — Checks: python3, node, npm, postfix, dovecot

check_docker_deps() {
    # Check for docker
    if ! command -v docker &>/dev/null; then
        error "Missing Docker dependency: docker"
        error "Please install Docker"
        return 1
    fi
    
    # Check for docker compose (v2 plugin) OR docker-compose (v1 standalone)
    local has_compose=false
    if command -v docker &>/dev/null && docker compose version &>/dev/null 2>&1; then
        has_compose=true
    elif command -v docker-compose &>/dev/null; then
        has_compose=true
    fi
    
    if [[ "$has_compose" != "true" ]]; then
        error "Missing Docker Compose (install 'docker-compose-plugin' or 'docker-compose')"
        return 1
    fi
    
    return 0
}

# check_docker_deps — Checks: docker, docker compose

# =============================================================================
# Utility functions
# =============================================================================

wait_for_port() {
    local port="$1"
    local timeout="${2:-30}"
    
    if [[ -z "$port" ]]; then
        error "wait_for_port: requires <port> argument"
        return 1
    fi
    
    # Validate port is a number
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        error "wait_for_port: port must be a number, got '$port'"
        return 1
    fi
    
    local elapsed=0
    local interval=0.5
    
    while (( $(echo "$elapsed < $timeout" | bc -l 2>/dev/null || echo "$elapsed < $timeout") )); do
        # Try multiple methods to check if port is listening
        if command -v ss &>/dev/null; then
            if ss -tlnp 2>/dev/null | grep -q ":${port} "; then
                return 0
            fi
        elif command -v netstat &>/dev/null; then
            if netstat -tlnp 2>/dev/null | grep -q ":${port} "; then
                return 0
            fi
        elif command -v lsof &>/dev/null; then
            if lsof -i ":${port}" -sTCP:LISTEN 2>/dev/null | grep -q LISTEN; then
                return 0
            fi
        fi
        
        sleep "$interval"
        elapsed=$(echo "$elapsed + $interval" | bc -l 2>/dev/null || echo "$elapsed + $interval" | awk '{printf "%.1f", $1 + $3}')
    done
    
    error "Timeout waiting for port $port after ${timeout}s"
    return 1
}

# wait_for_port <port> <timeout> — waits until port is listening

is_root() {
    [[ "$(id -u)" -eq 0 ]]
}

# is_root — Returns 0 if running as root

# =============================================================================
# End of lib.sh
# =============================================================================
