#!/bin/sh
set -e

# GLPI Podman Setup Script
# This script sets up GLPI with MariaDB using rootless Podman containers

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GLPI_DIR="${SCRIPT_DIR}"

printf "=== Setting up GLPI with Podman ===\n"

# Volume directories in /srv/glpi (should be created by services.sh with proper permissions)
GLPI_VOLUMES="/srv/glpi"
printf "Using volume directory: %s\n" "$GLPI_VOLUMES"

# Verify volume directories exist and are accessible
if [ ! -d "$GLPI_VOLUMES" ]; then
    printf "Error: Volume directory %s does not exist or is not accessible\n" "$GLPI_VOLUMES" >&2
    printf "This should be created by services.sh with proper permissions\n" >&2
    exit 1
fi

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
sed -i "s|MARIADB_VOLUME_PLACEHOLDER|${GLPI_VOLUMES}/mariadb:/var/lib/mysql|g" "${HOME}/.config/containers/systemd/glpi-mariadb.container"

# Copy and configure GLPI app container quadlet from local template
cp "${GLPI_DIR}/glpi-app.container" "${HOME}/.config/containers/systemd/glpi-app.container"
sed -i "s|ENV_FILE_PLACEHOLDER|${GLPI_DIR}/glpi.env|g" "${HOME}/.config/containers/systemd/glpi-app.container"
sed -i "s|CONFIG_VOLUME_PLACEHOLDER|${GLPI_VOLUMES}/config:/var/www/html/config|g" "${HOME}/.config/containers/systemd/glpi-app.container"
sed -i "s|FILES_VOLUME_PLACEHOLDER|${GLPI_VOLUMES}/files:/var/www/html/files|g" "${HOME}/.config/containers/systemd/glpi-app.container"
sed -i "s|PLUGINS_VOLUME_PLACEHOLDER|${GLPI_VOLUMES}/plugins:/var/www/html/plugins|g" "${HOME}/.config/containers/systemd/glpi-app.container"

# Reload systemd to recognize new quadlets
systemctl --user daemon-reload

# Quadlets are created - systemd will manage them
printf "Quadlet files created successfully.\n"

printf "\n=== GLPI Setup Complete ===\n"
printf "GLPI Quadlet files have been created.\n"
printf "To start GLPI: systemctl --user start glpi-pod.service\n"
printf "To enable auto-start: systemctl --user enable glpi-pod.service\n"
printf "Access GLPI at: http://localhost:8081 (glpi/glpi)\n"