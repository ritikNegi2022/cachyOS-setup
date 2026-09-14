#!/bin/bash
# PostgreSQL service runner — start/stop/status/logs/connect/backup helpers
# Part of arch-setup — see setup.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[ok]${NC}  $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[err]${NC} $*" >&2; }
info() { echo -e "${BLUE}[info]${NC} $*"; }

PG_USER="${PG_USER:-postgres}"
PG_DATA_DIR="${PG_DATA_DIR:-/var/lib/postgres/data}"
PG_PORT="${PG_PORT:-5432}"

if [[ $EUID -eq 0 ]]; then
    SUDO=()
else
    SUDO=(sudo)
fi

print_header() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  PostgreSQL Service Runner${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_usage() {
    cat << EOF
Usage: $(basename "$0") <command> [options]

Commands:
    start       Start PostgreSQL service
    stop        Stop PostgreSQL service
    restart     Restart PostgreSQL service
    status      Show PostgreSQL service status
    logs        Show PostgreSQL logs (last 50 lines, -f to follow)
    connect     Connect with psql (default db: postgres)
    create-db   Create a new database
    list-dbs    List all databases
    backup      Dump all databases to a SQL file
    restore     Restore from a SQL backup
    enable      Enable PostgreSQL to start on boot
    disable     Disable PostgreSQL from starting on boot
    shell       Open psql as postgres via sudo
    help        Show this help message

Examples:
    $(basename "$0") start
    $(basename "$0") connect api_watch
    $(basename "$0") create-db myapp_db
    $(basename "$0") backup ~/backups
    $(basename "$0") logs -f

Environment variables:
    PG_USER       PostgreSQL user (default: postgres)
    PG_DATA_DIR   Data directory (default: /var/lib/postgres/data)
    PG_PORT       Port (default: 5432)
EOF
}

check_postgres_running() {
    systemctl is-active --quiet postgresql 2>/dev/null
}

get_pg_version() {
    psql --version 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+)?' | head -1 || echo "unknown"
}

require_initialized() {
    if [[ ! -f "$PG_DATA_DIR/PG_VERSION" ]]; then
        err "PostgreSQL not initialized in $PG_DATA_DIR"
        err "Run scripts/postgres-setup.sh first."
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

do_start() {
    print_header
    if check_postgres_running; then
        log "PostgreSQL is already running"
        return 0
    fi
    require_initialized
    info "Data directory: $PG_DATA_DIR"
    info "Port: $PG_PORT"
    "${SUDO[@]}" systemctl start postgresql
    if check_postgres_running; then
        log "PostgreSQL started successfully"
        info "Listening on port $PG_PORT"
    else
        err "Failed to start PostgreSQL"
        exit 1
    fi
}

do_stop() {
    print_header
    if ! check_postgres_running; then
        log "PostgreSQL is not running"
        return 0
    fi
    "${SUDO[@]}" systemctl stop postgresql
    if ! check_postgres_running; then
        log "PostgreSQL stopped successfully"
    else
        err "Failed to stop PostgreSQL"
        exit 1
    fi
}

do_restart() {
    print_header
    log "Restarting PostgreSQL service..."
    do_stop
    sleep 1
    do_start
}

do_status() {
    print_header
    if check_postgres_running; then
        log "PostgreSQL service: ACTIVE"
        echo ""
        systemctl status postgresql --no-pager 2>/dev/null | head -12 || true
        info "PostgreSQL version: $(get_pg_version)"
    else
        warn "PostgreSQL service: INACTIVE"
        info "Start with: $(basename "$0") start"
    fi
}

do_logs() {
    print_header
    local follow=false
    if [[ "${1:-}" == "-f" || "${1:-}" == "--follow" ]]; then
        follow=true
    fi
    info "PostgreSQL logs (journalctl):"
    echo ""
    if $follow; then
        "${SUDO[@]}" journalctl -u postgresql -f --no-pager
    else
        "${SUDO[@]}" journalctl -u postgresql -n 50 --no-pager
    fi
}

do_connect() {
    local db_name="${1:-postgres}"
    psql -U "$PG_USER" -d "$db_name"
}

do_create_db() {
    local db_name="${1:-}"
    if [[ -z "$db_name" ]]; then
        err "Database name required"
        err "Usage: $(basename "$0") create-db <database_name>"
        exit 1
    fi
    if "${SUDO[@]}" -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='$db_name'" 2>/dev/null | grep -q 1; then
        warn "Database '$db_name' already exists"
        return 0
    fi
    if "${SUDO[@]}" -u postgres createdb -O "$PG_USER" "$db_name"; then
        log "Database '$db_name' created successfully"
    else
        err "Failed to create database '$db_name'"
        exit 1
    fi
}

do_list_dbs() {
    "${SUDO[@]}" -u postgres psql -c "\l"
}

do_backup() {
    local backup_dir="${1:-$HOME/pg_backup_$(date +%Y%m%d_%H%M%S)}"
    print_header
    log "Creating backup in: $backup_dir"
    mkdir -p "$backup_dir"
    if pg_dumpall -U "$PG_USER" > "$backup_dir/all_databases.sql"; then
        log "Backup completed: $backup_dir/all_databases.sql"
        info "Size: $(du -h "$backup_dir/all_databases.sql" | cut -f1)"
    else
        err "Backup failed"
        exit 1
    fi
}

do_restore() {
    local backup_file="${1:-}"
    if [[ -z "$backup_file" ]]; then
        err "Backup file required"
        err "Usage: $(basename "$0") restore <backup_file.sql>"
        exit 1
    fi
    if [[ ! -f "$backup_file" ]]; then
        err "Backup file not found: $backup_file"
        exit 1
    fi
    print_header
    read -r -p "This will restore all databases from $backup_file. Continue? (y/N) " -n 1 REPLY
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Restore cancelled"
        return 0
    fi
    if psql -U "$PG_USER" -f "$backup_file"; then
        log "Restore completed successfully"
    else
        err "Restore failed"
        exit 1
    fi
}

do_enable() {
    print_header
    "${SUDO[@]}" systemctl enable postgresql.service
    log "PostgreSQL will start automatically on boot"
}

do_disable() {
    print_header
    "${SUDO[@]}" systemctl disable postgresql.service
    log "PostgreSQL will NOT start automatically on boot"
}

do_shell() {
    print_header
    exec "${SUDO[@]}" -u postgres psql
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

case "${1:-help}" in
    start)      do_start ;;
    stop)       do_stop ;;
    restart)    do_restart ;;
    status)     do_status ;;
    logs)       do_logs "${2:-}" ;;
    connect)    do_connect "${2:-postgres}" ;;
    create-db)  do_create_db "${2:-}" ;;
    list-dbs)   do_list_dbs ;;
    backup)     do_backup "${2:-}" ;;
    restore)    do_restore "${2:-}" ;;
    enable)     do_enable ;;
    disable)    do_disable ;;
    shell)      do_shell ;;
    help|--help|-h) print_header; print_usage ;;
    *)
        err "Unknown command: ${1:-}"
        echo ""
        print_usage
        exit 1
        ;;
esac
