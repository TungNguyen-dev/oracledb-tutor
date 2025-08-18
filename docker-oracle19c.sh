#!/usr/bin/env bash

set -Eeuo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
SCHEMA_REPO_URL="https://github.com/oracle/db-sample-schemas.git"
SCHEMA_REPO_TAG="v19.2"
SCHEMA_DIR="$HOME/SourceCode/tungnn/databases/oracledb-tutor/db-sample-schemas"

ORACLE_CONTAINER_NAME="oracle_database"
ORACLE_IMAGE="container-registry.oracle.com/database/enterprise:19.3.0.0"
ORACLE_PWD="${ORACLE_PWD:-123456}"

ORADATA_DIR="$HOME/.data/docker/oracle/oradata"
APP_DIR="$HOME/SourceCode/tungnn/databases/oracledb-tutor"
SCRIPTS_DIR="$APP_DIR/scripts"

# -----------------------------------------------------------------------------
# Validation
# -----------------------------------------------------------------------------
command -v git >/dev/null 2>&1 || {
  echo "ERROR: git is not installed."
  exit 1
}

command -v docker >/dev/null 2>&1 || {
  echo "ERROR: docker is not installed."
  exit 1
}

# -----------------------------------------------------------------------------
# Prepare Oracle sample schemas
# -----------------------------------------------------------------------------
if [[ ! -d "$SCHEMA_DIR/.git" ]]; then
  echo "Cloning Oracle sample schemas repository..."
  mkdir -p "$SCHEMA_DIR"
  git clone "$SCHEMA_REPO_URL" "$SCHEMA_DIR"
else
  echo "Sample schemas repository already exists. Skipping clone."
fi

cd "$SCHEMA_DIR"
echo "Checking out Oracle sample schemas tag: $SCHEMA_REPO_TAG"
git fetch --tags
git checkout "tags/${SCHEMA_REPO_TAG}"

# -----------------------------------------------------------------------------
# Prepare directories
# -----------------------------------------------------------------------------
echo "Preparing Oracle data directory..."
mkdir -p "$ORADATA_DIR"

# -----------------------------------------------------------------------------
# Remove existing container (if any)
# -----------------------------------------------------------------------------
if docker ps -a --format '{{.Names}}' | grep -qx "$ORACLE_CONTAINER_NAME"; then
  echo "Removing existing Oracle container: $ORACLE_CONTAINER_NAME"
  docker rm -f "$ORACLE_CONTAINER_NAME"
fi

# -----------------------------------------------------------------------------
# Run Oracle Database container
# -----------------------------------------------------------------------------
echo "Starting Oracle Database container..."
docker run -d \
  --name "$ORACLE_CONTAINER_NAME" \
  -p 1521:1521 \
  -p 5500:5500 \
  -e ORACLE_PWD="$ORACLE_PWD" \
  -v "$ORADATA_DIR:/opt/oracle/oradata" \
  -v "$SCRIPTS_DIR:/opt/oracle/scripts/startup" \
  -v "$APP_DIR:/home/oracle/app" \
  "$ORACLE_IMAGE"

echo "Oracle Database container started successfully."
