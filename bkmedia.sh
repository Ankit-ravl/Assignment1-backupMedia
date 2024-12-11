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
        local src=$(sed -n "${line_number}p" $CONFIG_FILE)
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
    local dest="$BACKUP_DIR/$(echo $src | sed 's/[^a-zA-Z0-9]/_/g')"

    echo "Starting Back up from $src to $dest"

    # check if destination dir exists, make it if not
    mkdir -p "$dest"

    # start backup using rsync
    rsync -avz --delete "$src" "$dest" >> "$LOG_FILE" 2>&1

    if [[ $? -eq 0 ]]; then
        echo "Backup successful for $src | tee -a $LOG_FILE"
    else
        echo "Backup Successful for $src | tee -a $LOG_FILE"
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
