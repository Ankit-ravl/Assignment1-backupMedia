#!/bin/bash

# File: bkmedia.sh

CONFIG_FILE="locations.cfg"
BACKUP_DIR="/var/backups/media"
LOG_FILE="backup.log"

# Function to display configured locations
display_locations() {
    if [[ ! -f $CONFIG_FILE ]]; then
        echo "Error: Configuration file $CONFIG_FILE not found."
        exit 1
    fi

    echo "Configured Locations:"
    nl -s": " $CONFIG_FILE
}

#Function for backup
backup() {
    local line_number=$1

    if [[ -z $line_number ]]; then
        # Back up all locations
        while IFS= read -r src; do
            if [[ -n $src ]]; then
                perform_backup "$src"
            else
               echo "Error : Invalid or Empty line in $CONFIG_FILE."
	    fi
       done < "$CONFIG_FILE"
    else
        # Back specfic location by line_number
        src=$(sed -n "${line_number}p" $CONFIG_FILE)
        local src

        if [[ -n $src ]]; then
            perform_backup "$src"
        else
            echo "Error: Invalid line number $line_number."
        fi
    fi
}
# Function to perform the backup using resync
perform_backup(){
    local src=$1

    dest="${BACKUP_DIR}/${src//[^a-zA-Z0-9]/_}"
    local dest

    echo "Starting Back up from $src to $dest"

    # check if destination dir exists, make it if not
    mkdir -p "$dest"

    # Save the mapping to metadata file
    echo "$src $dest" >> "$BACKUP_DIR/backup_metadata.txt"

    # start backup using rsync
    if rsync -avz --delete "$src" "$dest" >> "$LOG_FILE" 2>&1; then
        echo "Backup successful for $src | tee -a $LOG_FILE"
    else
        echo "Backup Successful for $src | tee -a $LOG_FILE"
    fi

}

restore() {
    local line_number=$1

    if [[ -z $line_number ]]; then
        echo "Error: Specify a line number with -L option for restore."
        exit 1
    fi

    src=$(sed -n "${line_number}p" "$CONFIG_FILE")
    local src

    if [[ -n $src ]]; then
        # Find the corresponding backup directory from metadata file
        dest=$(grep "^$src " "$BACKUP_DIR/backup_metadata.txt" | awk '{print $2}')
        local dest

        if [[ -z $dest ]]; then
            echo "Error: No backup found for $src in metadata."
            exit 1
        fi

        echo "Restoring from $dest to $src"

        # Perform restoration
        if rsync -avz "$dest/" "$src" >> "$LOG_FILE" 2>&1; then
            echo "Restore successful for $src" | tee -a "$LOG_FILE"
        else
            echo "Restore failed for $src" | tee -a "$LOG_FILE"
        fi
    else
        echo "Error: Invalid line number."
    fi
}



#Script Switch
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
            echo "Error: Missing -L option for restore."
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 [-B [-L n]] | [-R -L n]"
        exit 1
        ;;
esac
