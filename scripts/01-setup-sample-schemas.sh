#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Script: create-sample-schemas.sh
# Purpose: Install Oracle sample schemas in an Oracle Database 19c container
# -----------------------------------------------------------------------------

set -Eeuo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
ORACLE_SID="${ORACLE_SID:-ORCLCDB}"
PDB_SERVICE="${PDB_SERVICE:-orclpdb1}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-1521}"

# Passwords (prefer exporting these before running the script)
SYS_PWD="${SYS_PWD:-123456}"
SYSTEM_PWD="${SYSTEM_PWD:-123456}"

HR_PWD="${HR_PWD:-hrpw}"
OE_PWD="${OE_PWD:-oepw}"
PM_PWD="${PM_PWD:-pmpw}"
IX_PWD="${IX_PWD:-ixpw}"
SH_PWD="${SH_PWD:-shpw}"
BI_PWD="${BI_PWD:-bipw}"

DEFAULT_TS="users"
TEMP_TS="temp"

SCHEMA_DIR="$HOME/app/db-sample-schemas"
LOG_DIR="$ORACLE_HOME/demo/schema/log"
CONN_STRING="${DB_HOST}:${DB_PORT}/${PDB_SERVICE}"

# -----------------------------------------------------------------------------
# Validation
# -----------------------------------------------------------------------------
if [[ -z "${ORACLE_HOME:-}" ]]; then
  echo "ERROR: ORACLE_HOME is not set."
  exit 1
fi

if [[ ! -d "$SCHEMA_DIR" ]]; then
  echo "ERROR: Sample schema directory not found: $SCHEMA_DIR"
  exit 1
fi

command -v sqlplus >/dev/null 2>&1 || {
  echo "ERROR: sqlplus is not available in PATH."
  exit 1
}

# -----------------------------------------------------------------------------
# Prepare environment
# -----------------------------------------------------------------------------
echo "Creating log directory: $LOG_DIR"
mkdir -p "$LOG_DIR"

cd "$SCHEMA_DIR"

echo "Updating embedded paths in schema files..."
if sed --version >/dev/null 2>&1; then
  # GNU sed (Linux)
  sed -i -- "s#__SUB__CWD__#$(pwd)#g" ./*.sql ./*/*.sql ./*/*.dat
else
  # BSD sed (macOS)
  sed -i.bak -- "s#__SUB__CWD__#$(pwd)#g" ./*.sql ./*/*.sql ./*/*.dat
fi

# -----------------------------------------------------------------------------
# Install sample schemas
# -----------------------------------------------------------------------------
echo "Installing Oracle sample schemas..."
sqlplus -s "sys/${SYS_PWD}@${ORACLE_SID} as sysdba" <<EOF

@mksample \
  "${SYSTEM_PWD}" \
  "${SYS_PWD}" \
  "${HR_PWD}" \
  "${OE_PWD}" \
  "${PM_PWD}" \
  "${IX_PWD}" \
  "${SH_PWD}" \
  "${BI_PWD}" \
  "${DEFAULT_TS}" \
  "${TEMP_TS}" \
  "${LOG_DIR}/" \
  "${CONN_STRING}"

EXIT
EOF

echo "Sample schema installation completed successfully."
