#!/bin/bash

# File: bkmedia.sh

CONFIG_FILE="locations.cfg"
BACKUP_DIR="/var/backups/media"
LOG_FILE="backup.log"

# Function to display configured locations
display_locations() {
    if [[ ! -f $CONFIG_FILE ]]; then
        echo "Error: Configuration file '$CONFIG_FILE' not found."
        exit 1
    fi

    echo "Configured Locations:"
    nl -s": " $CONFIG_FILE
}

