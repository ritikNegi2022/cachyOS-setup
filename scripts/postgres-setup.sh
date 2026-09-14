#!/bin/bash
# Full PostgreSQL setup with data directory, databases, and service configuration
# Part of arch-setup — see setup.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[ok]${NC}  $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[err]${NC} $*" >&2; }

if [[ $EUID -eq 0 ]]; then
    SUDO=()
else
    SUDO=(sudo)
fi

PG_DATA_DIR="/var/lib/postgres/data"
PG_BIN="/usr/bin"
PG_USER="postgres"
PG_PORT=5432

# ---------------------------------------------------------------------------
# 1. Detect PostgreSQL version
# ---------------------------------------------------------------------------
log "Detecting PostgreSQL version..."

if command -v psql >/dev/null 2>&1; then
    PG_VERSION=$(psql --version | grep -oE '[0-9]+(\.[0-9]+)?' | head -1)
    log "PostgreSQL version: $PG_VERSION"
else
    warn "psql not found - PostgreSQL may not be installed yet"
fi

# ---------------------------------------------------------------------------
# 2. Install PostgreSQL server if missing
# NOTE: on Arch, `psql` lives in postgresql-libs (often pulled in by other
# packages), while the server binaries (initdb/pg_ctl) live in `postgresql`.
# Guard on initdb, NOT psql — otherwise the server install is skipped and
# initdb fails below.
# ---------------------------------------------------------------------------
if ! command -v initdb >/dev/null 2>&1; then
    log "Installing PostgreSQL server..."
    "${SUDO[@]}" pacman -S --noconfirm --needed postgresql postgresql-libs
    log "PostgreSQL installed"
fi

# ---------------------------------------------------------------------------
# 3. Initialize database cluster if needed
# ---------------------------------------------------------------------------
log "Checking PostgreSQL data directory..."

if [[ -d "$PG_DATA_DIR" && -f "$PG_DATA_DIR/PG_VERSION" ]]; then
    log "PostgreSQL data directory already initialized at $PG_DATA_DIR"
else
    log "Initializing PostgreSQL data directory..."

    # Ensure postgres user exists (Arch creates it via the package; belt + suspenders)
    if ! id -u postgres >/dev/null 2>&1; then
        "${SUDO[@]}" useradd -r -M -d /var/lib/postgres -s /bin/bash postgres
    fi

    "${SUDO[@]}" mkdir -p "$PG_DATA_DIR"
    "${SUDO[@]}" chown postgres:postgres "$PG_DATA_DIR"
    "${SUDO[@]}" chmod 700 "$PG_DATA_DIR"

    log "Running initdb as postgres user..."
    "${SUDO[@]}" -u postgres "$PG_BIN/initdb" -D "$PG_DATA_DIR"

    log "Database cluster initialized"
fi

# ---------------------------------------------------------------------------
# 4. Configure pg_hba.conf for local trust auth (dev only)
# ---------------------------------------------------------------------------
log "Configuring pg_hba.conf for local connections..."

PG_HBA="$PG_DATA_DIR/pg_hba.conf"

if [[ -f "$PG_HBA" && ! -f "$PG_HBA.orig" ]]; then
    "${SUDO[@]}" cp "$PG_HBA" "$PG_HBA.orig"
    log "Backed up pg_hba.conf"
fi

if [[ -f "$PG_HBA" ]] && ! "${SUDO[@]}" grep -q "cachyOS-setup additions" "$PG_HBA"; then
    "${SUDO[@]}" tee -a "$PG_HBA" >/dev/null << 'EOF'

# === cachyOS-setup additions ===
# Local socket connections (dev only - trust auth)
local   all             all                                     trust
# IPv4 local connections (dev only - trust auth)
host    all             all             127.0.0.1/32            trust
# IPv6 local connections (dev only - trust auth)
host    all             all             ::1/128                 trust
EOF
    log "Added local trust rules to pg_hba.conf (dev only)"
fi

# ---------------------------------------------------------------------------
# 5. Create default databases
# ---------------------------------------------------------------------------
log "Creating default databases..."

# Helper: create DB if missing. Never fatal — a failed create only warns.
create_db() {
    local db_name="$1"
    local db_owner="${2:-$PG_USER}"

    if ! "${SUDO[@]}" -u postgres "$PG_BIN/psql" -tAc "SELECT 1 FROM pg_database WHERE datname='$db_name'" 2>/dev/null | grep -q 1; then
        if "${SUDO[@]}" -u postgres "$PG_BIN/createdb" -O "$db_owner" "$db_name" 2>/dev/null; then
            log "  Created database '$db_name'"
        else
            warn "  Could not create database '$db_name' (skipping)"
        fi
    else
        log "  Database '$db_name' already exists"
    fi
}

log "Default databases configured (will create after service start)"

# ---------------------------------------------------------------------------
# 6. Enable + start service
# ---------------------------------------------------------------------------
log "Configuring PostgreSQL systemd service..."

"${SUDO[@]}" systemctl enable postgresql.service
"${SUDO[@]}" systemctl start postgresql.service 2>/dev/null || true

log "PostgreSQL service enabled and started"

# Now create DBs (needs running server)
create_db "api_watch"
create_db "flight_booking"
create_db "tourscanner-db-test"
log "Databases created (if server running)" 2>/dev/null || true

log "PostgreSQL service enabled and started"

# ---------------------------------------------------------------------------
# 7. Summary
# ---------------------------------------------------------------------------
log ""
log "============================================"
log "  POSTGRESQL SETUP COMPLETE"
log "============================================"
log ""
log "  Data directory: $PG_DATA_DIR"
log "  Port: $PG_PORT"
log "  User: $PG_USER"
log ""
log "  Useful commands:"
log "    sudo -u postgres psql                       # psql as postgres"
log "    psql -U postgres -d api_watch               # connect to specific DB"
log "    sudo -u postgres createdb -O postgres mydb  # new database"
log ""
log "  To set postgres password (if needed):"
log "    sudo -u postgres psql -c \"ALTER USER postgres PASSWORD 'your_password';\""
log ""
log "  Config files:"
log "    $PG_HBA        (authentication; backup at .orig)"
log "    $PG_DATA_DIR/postgresql.conf"
