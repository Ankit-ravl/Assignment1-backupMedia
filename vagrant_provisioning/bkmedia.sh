#!/bin/bash

CONFIG_FILE="locations.cfg"
BACKUP_DIR="/var/backups/media"
LOG_FILE="/tmp/backup.log"

# Display configured locations
display_locations() {
    if [[ ! -f $CONFIG_FILE ]]; then
        echo "Error: Configuration file $CONFIG_FILE not found."
        exit 1
    fi

    echo "Configured Locations:"
    nl -s": " $CONFIG_FILE
}

# Perform backup
backup() {
    local line_number
    line_number=$1

    if [[ -z $line_number ]]; then
        # Back up all locations
        while IFS= read -r src; do
            if [[ -n $src ]]; then
                perform_backup "$src"
            else
                echo "Error: Invalid or empty line in $CONFIG_FILE."
            fi
        done < "$CONFIG_FILE"
    else
        # Back up specific location by line number
        local src
        src=$(sed -n "${line_number}p" "$CONFIG_FILE")
        if [[ -n $src ]]; then
            perform_backup "$src"
        else
            echo "Error: Invalid line number $line_number."
        fi
    fi
}

# Perform backup using rsync
perform_backup() {
    local src
    src=$1
    local dest 
    dest="$BACKUP_DIR/$(echo "$src" | sed 's/[^a-zA-Z0-9]/_/g')"

    echo "Starting backup from $src to $BACKUP_DIR"

    mkdir -p "$dest"

    if rsync -avz --delete "$src" "$dest" >> "$LOG_FILE" 2>&1; then

        # Compress the backup directory after transfer
        tar -czf "$dest.tar.gz" -C "$BACKUP_DIR" "$(basename "$dest")"

        # Delete the uncompressed data
        rm -rf "$dest"

        echo "Backup successful for $src" | tee -a "$LOG_FILE"

    else
        echo "Backup failed for $src" | tee -a "$LOG_FILE"
    fi
}

# Restore backups
restore() {
    local line_number
    line_number=$1

    if [[ -z $line_number ]]; then
        # restoring all backups
        echo "Restoring backups for all configured locations..."
        while IFS= read -r src; do
            if [[ -n $src ]]; then
                local dest
                local archive

                dest="$BACKUP_DIR/$(echo "$src" | sed 's/[^a-zA-Z0-9]/_/g')"
                archive="$dest.tar.gz"

                if [[ -f $archive ]]; then
                    echo "Decompressing $archive for restore"
                    mkdir -p "$dest"
                    tar -xzf "$archive" -C "$dest"

                    echo "Restoring from $dest to $src"
                    rsync -avz "$dest/" "$src" >> "$LOG_FILE" 2>&1

                    #clean up temporary decompressed files
                    rm -rf "$dest"
                else
                    echo "Backup archive $archive not found for $src"
                fi
            else
                echo "Source address null"
            fi
        done < "$CONFIG_FILE"
    else
        #restoring for only one location as per line number
       
        local src
        src=$(sed -n "${line_number}p" "$CONFIG_FILE")
        echo "Restoring location for $src .."

        if [[ -n $src ]]; then
            local dest
            local archive

            dest="$BACKUP_DIR/$(echo "$src" | sed 's/[^a-zA-Z0-9]/_/g')"
            archive="$dest.tar.gz"

            if [[ -f $archive ]]; then
                echo "Decompressing $archive for restore"
                mkdir -p "$dest"
                tar -xzf "$archive" -C "$dest"

                echo "Restoring from $dest to $src"
                rsync -avz "$dest/" "$src" >> "$LOG_FILE" 2>&1

                #clean up the temporary decompressed files
                rm -rf "$dest"
            else
                echo "Backup archive $archive not found in $src"
            fi
        else
            echo "Error: Invalid line number."
        fi
    fi
}

# Main script logic
case $1 in
    "")
        display_locations
        ;;
    "-B")
        if [[ $2 == "-L" ]]; then
            backup "$3"
        else
            backup
        fi
        ;;
    "-R")
        if [[ $2 == "-L" ]]; then
            restore "$3"
        else
            restore
        fi
        ;;
    *)
        echo "Usage: $0 [-B [-L n]] | [-R [-L n]]"
        exit 1
        ;;
esac
