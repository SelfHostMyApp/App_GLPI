#!/bin/sh
set -e

# GLPI Podman Setup Script
# This script sets up GLPI with MariaDB using rootless Podman containers

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GLPI_DIR="${SCRIPT_DIR}"

printf "=== Setting up GLPI with Podman ===\n"

# Create volume directories in podman user's home
printf "Creating volume directories...\n"
mkdir -p "${HOME}/volumes/glpi/config"
mkdir -p "${HOME}/volumes/glpi/files" 
mkdir -p "${HOME}/volumes/glpi/plugins"
mkdir -p "${HOME}/volumes/glpi/mariadb"

# Quadlets will manage the containers - no manual podman commands needed
printf "Quadlets will handle container creation via systemd...\n"

# Create Quadlet files for systemd integration using templates
printf "Creating Quadlet files...\n"
mkdir -p "${HOME}/.config/containers/systemd"

# Copy and configure pod quadlet from local template
cp "${GLPI_DIR}/glpi-pod.pod" "${HOME}/.config/containers/systemd/glpi-pod.pod"

# Copy and configure MariaDB container quadlet from local template
cp "${GLPI_DIR}/glpi-mariadb.container" "${HOME}/.config/containers/systemd/glpi-mariadb.container"
sed -i "s|ENV_FILE_PLACEHOLDER|${GLPI_DIR}/glpi.env|g" "${HOME}/.config/containers/systemd/glpi-mariadb.container"
sed -i "s|MARIADB_VOLUME_PLACEHOLDER|${HOME}/volumes/glpi/mariadb:/var/lib/mysql|g" "${HOME}/.config/containers/systemd/glpi-mariadb.container"

# Copy and configure GLPI app container quadlet from local template
cp "${GLPI_DIR}/glpi-app.container" "${HOME}/.config/containers/systemd/glpi-app.container"
sed -i "s|ENV_FILE_PLACEHOLDER|${GLPI_DIR}/glpi.env|g" "${HOME}/.config/containers/systemd/glpi-app.container"
sed -i "s|CONFIG_VOLUME_PLACEHOLDER|${HOME}/volumes/glpi/config:/var/www/html/config|g" "${HOME}/.config/containers/systemd/glpi-app.container"
sed -i "s|FILES_VOLUME_PLACEHOLDER|${HOME}/volumes/glpi/files:/var/www/html/files|g" "${HOME}/.config/containers/systemd/glpi-app.container"
sed -i "s|PLUGINS_VOLUME_PLACEHOLDER|${HOME}/volumes/glpi/plugins:/var/www/html/plugins|g" "${HOME}/.config/containers/systemd/glpi-app.container"

# Reload systemd to recognize new quadlets
systemctl --user daemon-reload

printf "\n=== GLPI Setup Complete ===\n"
printf "GLPI is available at: http://localhost:8081\n"
printf "Default credentials: glpi / glpi\n"
printf "\nTo enable auto-start: systemctl --user enable glpi-pod.service\n"
printf "To manage: systemctl --user {start,stop,restart} glpi-pod.service\n"