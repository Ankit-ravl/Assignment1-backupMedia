#!/bin/bash

CONFIG_FILE="locations.cfg"
BACKUP_DIR="/var/backups/media"
LOG_FILE="/tmp/backup.log"
ENTANGLEMENT_LOG="/tmp/entanglement.log"
CHECKSUM_FILE="/tmp/checksums.txt"

#Detect entagled files
genrate_checksums(){

    #if backdir is empty, exit
    if [[ ! $(ls -A $BACKUP_DIR) ]]; then
        echo "Backup directory is empty. Exiting..."
        exit 1
    fi

    echo "Detecting quantam entanglement..."
    
    mkdir -p /tmp/hashes
    mkdir -p /tmp/archives

    #iterate through all the archives and 
    for archive in "$BACKUP_DIR"/*.tar.gz; do

        #extract the archive
        tar -xzf "$archive" -C /tmp/archives

        #extract just the file name from the archive
        archive=$(basename "$archive")

        #calculate the hash of the extracted files
        find /tmp/archives -type f -exec sha256sum {} \; >> /tmp/hashes/"$archive".txt

        #remove the extracted files
        rm -rf /tmp/archives/*
    done

    #create checksum file if it does not exist
    if [[ ! -f $CHECKSUM_FILE ]]; then
        touch $CHECKSUM_FILE
    fi

    #combine all the hashes and remove duplicates
    cat /tmp/hashes/*.txt | sort | uniq >> $CHECKSUM_FILE
    
}

#Detect entagled files
detect_entaglement(){
    local src
    src=$1

    # Extract hostname and path
    local hostname
    local path

    hostname=$(echo "$src" | cut -d':' -f1)
    path=$(echo "$src" | cut -d':' -f2-)
    
    #Generate remote checksums
    ssh "$hostname" "find $path -type f -exec sha256sum {} \;" > /tmp/current_remote_checksums.txt
    check_error "generating remote checksums"

    # Create exclusion list
    create_exclusion_list

    # Log entanglements based on exclusion list
    log_entanglements_from_exclusion_list "$src"

}

# Create a exclusion list based on the checksums
create_exclusion_list() {

    # Compare only the checksums ignoring filenames and create an exclusion list
    awk '{print $1}' "$CHECKSUM_FILE" | sort > /tmp/stored_checksums_only.txt
    awk '{print $1}' /tmp/current_remote_checksums.txt | sort > /tmp/current_checksums_only.txt

    comm -12 /tmp/stored_checksums_only.txt /tmp/current_checksums_only.txt > /tmp/exclude_checksums.txt

    grep -Ff /tmp/exclude_checksums.txt /tmp/current_remote_checksums.txt > /tmp/exclude_list.txt

    echo "Exclusion list created at /tmp/exclude_list.txt"
}

#log entagled files
log_entanglements_from_exclusion_list() {
    local src=$1
    local exclude_list_file="/tmp/exclude_list.txt"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %T")

    if [[ ! -f "$exclude_list_file" ]]; then
        echo "No exclusion list found to log entanglements."
        return 1
    fi

    while IFS= read -r line; do
        checksum=$(echo "$line" | awk '{print $1}')
        file=$(echo "$line" | awk '{$1=""; print $0}' | xargs) # Handle spaces in file paths
        echo "Entangled file detected: $file (Checksum: $checksum)" >> "$ENTANGLEMENT_LOG"
        echo "Source: $src" >> "$ENTANGLEMENT_LOG"
        echo "Timestamp: $timestamp" >> "$ENTANGLEMENT_LOG"
        echo "---------------------------------------------" >> "$ENTANGLEMENT_LOG"
    done < "$exclude_list_file"

    echo "Entanglements logged at $ENTANGLEMENT_LOG"
}



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

    # Generate the checksums
    genrate_checksums

    # Check if CHECKSUM_FILE exists or is empty
    if [[ ! -f $CHECKSUM_FILE || ! -s $CHECKSUM_FILE ]]; then
        echo "No checksum file found. Performing initial backup for $src..."
        # Perform the first backup without exclusions
        rsync -avz --delete "$src" "$dest" >> "$LOG_FILE" 2>&1

    else
        # Generate the exclusion list for subsequent backups
        detect_entaglement "$src"

        # Perform the backup with exclusions
        if rsync -avz --checksum --exclude-from="/tmp/exclude_list.txt" "$src" "$dest" >> "$LOG_FILE" 2>&1; then
            echo "Backup successful for $src" | tee -a "$LOG_FILE"
        else
            echo "Backup failed for $src" | tee -a "$LOG_FILE"
        fi
    fi

    # Compress the backup directory after transfer
    tar -czf "$dest.tar.gz" -C "$BACKUP_DIR" "$(basename "$dest")"

    # Delete the uncompressed data
    rm -rf "$dest"
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

                # Get the name of the archived folder based on server address
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

check_error() {
    if [[ $? -ne 0 ]]; then
        echo "Error occurred during $1. Check the log file for details." | tee -a "$LOG_FILE"
        exit 1
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
