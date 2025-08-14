#!/bin/sh
set -e

# GLPI Podman Setup Script
# This script sets up GLPI with MariaDB using rootless Podman containers

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GLPI_DIR="${SCRIPT_DIR}"

printf "=== Setting up GLPI with Podman ===\n"

# Create volume directories
printf "Creating volume directories...\n"
mkdir -p "${GLPI_DIR}/volumes/glpi/config"
mkdir -p "${GLPI_DIR}/volumes/glpi/files" 
mkdir -p "${GLPI_DIR}/volumes/glpi/plugins"
mkdir -p "${GLPI_DIR}/volumes/mariadb"

# Create pod for GLPI services
printf "Creating GLPI pod...\n"
podman pod create \
  --name glpi-pod \
  --publish 1021:80 \
  --network bridge

# Create MariaDB container in pod
printf "Creating MariaDB container...\n"
podman run -d \
  --pod glpi-pod \
  --name glpi-mariadb \
  --env-file "${GLPI_DIR}/glpi.env" \
  --volume "${GLPI_DIR}/volumes/mariadb:/var/lib/mysql:Z" \
  --restart unless-stopped \
  --health-cmd='mysqladmin ping -h localhost' \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  docker.io/library/mariadb:10.6

# Wait for MariaDB to be healthy
printf "Waiting for MariaDB to be ready"
for i in $(seq 1 30); do
    if podman healthcheck run glpi-mariadb 2>/dev/null; then
        printf "\nMariaDB is ready!\n"
        break
    fi
    printf "."
    sleep 2
done

# Create GLPI application container in pod
printf "Creating GLPI application container...\n"
podman run -d \
  --pod glpi-pod \
  --name glpi-app \
  --env-file "${GLPI_DIR}/glpi.env" \
  --env MYSQL_HOST=127.0.0.1 \
  --volume "${GLPI_DIR}/volumes/glpi/config:/var/www/html/config:Z" \
  --volume "${GLPI_DIR}/volumes/glpi/files:/var/www/html/files:Z" \
  --volume "${GLPI_DIR}/volumes/glpi/plugins:/var/www/html/plugins:Z" \
  --restart unless-stopped \
  --health-cmd='curl -f http://localhost:80/status.php || exit 1' \
  --health-interval=30s \
  --health-timeout=15s \
  --health-retries=3 \
  docker.io/diouxx/glpi:latest

# Generate systemd service files
printf "Generating systemd service files...\n"
mkdir -p "${HOME}/.config/systemd/user"
cd "${HOME}/.config/systemd/user"
podman generate systemd --new --files --name glpi-pod

printf "\n=== GLPI Setup Complete ===\n"
printf "GLPI is available at: http://localhost:1021\n"
printf "Default credentials: glpi / glpi\n"
printf "\nTo enable auto-start: systemctl --user enable pod-glpi-pod.service\n"
printf "To manage: podman pod {start,stop,restart} glpi-pod\n"