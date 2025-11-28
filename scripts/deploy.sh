#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/tpl/tpl.sh"

# Parameter definitions
declare -A PARAMETERS=(

)
declare -A PARAMETER_DESCRIPTIONS=(

)
PARAMETER_ORDER=()

# Flag definitions
declare -A FLAGS=(
    ["help"]="show_help"
    ["h"]="show_help"
    ["restart"]=
    ["r"]=
    ["migrate"]="migrate"
    ["rebuild"]="rebuild_assets"
    ["watch"]="watch_assets"
    ["backup-mysql"]="backup_mysql"
    ["restore-mysql"]="restore_mysql"
    ["backup-docker-images"]="backup_docker_images"
    ["restore-docker-images"]="restore_docker_images"
    ["check-external-network"]="check_external_network"
)
declare -A FLAG_DESCRIPTIONS=(
    ["help,h"]="Displays all available parameters and flags"
    ["restart,r"]="Restarts containers"
    ["backup-mysql"]="Backup MySQL database"
    ["restore-mysql"]="Restores most recent MySQL database backup"
    ["backup-docker-images"]="Backup Docker images"
    ["restore-docker-images"]="Restores Docker images from backup"
    ["check-external-network"]="Returns status of external network"
)

# Protection functions
declare -A PROTECTION=(
    ["assign_command"]="DOCKER_CMD,docker compose,docker-compose"
    ["source_file"]="../.env"
    ["check_command"]="docker"
)

# Command description
description="Deploys and connects service to server container."

function run {

    cd $SCRIPT_DIR/../
    APP_PATH="/var/www/html"
    echo "Current working directory: $(pwd)"

    # Start Docker containers
    $DOCKER_CMD up -d

    echo "Waiting for container '$APP_CONTAINER_NAME' to be running..."
    for i in {1..10}; do
        STATUS=$(docker inspect -f '{{.State.Running}}' "$APP_CONTAINER_NAME" 2>/dev/null)
        if [ "$STATUS" == "true" ]; then
            echo "Container is running."
            break
        fi
        echo "Still waiting... ($i/10)"
        sleep 1
    done

    # If still not running, bail early
    if [ "$STATUS" != "true" ]; then
        echo "❌ Container '$APP_CONTAINER_NAME' failed to start."
        exit 1
    fi

    echo "Connecting containers to server network..."
    connect_to_network $APP_CONTAINER_NAME $EXTERNAL_NETWORK

    # Set permissions based on environment
    if [[ "$APP_ENV" == "dev" ]]; then
        echo "Setting loose permissions on local environment..."
        sudo chmod -R 777 ./src
    elif [[ "$APP_ENV" == "prod" ]]; then
        echo "Setting stricter permissions on production environment..."
        sudo chmod -R 750 ./src
    fi

    echo "Application setup complete!"
}

function restart {
    $DOCKER_CMD down
    run
}


function backup_mysql {
    local BACKUP_DIR="$SCRIPT_DIR/../backups/mysql"
    local TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    local BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.sql"
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    echo "Backing up MySQL database to $BACKUP_FILE..."
    
    # Use docker_exec to run mysqldump inside the container
    docker_exec "$DB_CONTAINER_NAME" "mysqldump -h $DB_HOST -P 3306 -u $DB_USERNAME -p$DB_PASSWORD $DB_DATABASE > /tmp/db_backup.sql" "/"
    
    # Copy the backup file from the container to the host
    docker cp "$DB_CONTAINER_NAME:/tmp/db_backup.sql" "$BACKUP_FILE"
    
    # Remove the temporary backup file from the container
    docker_exec "$DB_CONTAINER_NAME" "rm /tmp/db_backup.sql" "/"
    
    if [ -f "$BACKUP_FILE" ]; then
        color "green" "✅ Database backup completed successfully: $BACKUP_FILE"
    else
        color "red" "❌ Database backup failed!"
    fi
    
    exit 0
}

function restore_mysql {
    local BACKUP_DIR="$SCRIPT_DIR/../backups/mysql"
    
    # Check if backup directory exists
    if [ ! -d "$BACKUP_DIR" ]; then
        color "red" "❌ Backup directory does not exist: $BACKUP_DIR"
        exit 1
    fi
    
    # Find the latest backup file
    local LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/*.sql 2>/dev/null | head -n 1)
    
    if [ -z "$LATEST_BACKUP" ]; then
        color "red" "❌ No backup files found in $BACKUP_DIR"
        exit 1
    fi
    
    echo "Restoring MySQL database from $LATEST_BACKUP..."
    
    # Copy the backup file to the container
    docker cp "$LATEST_BACKUP" "$DB_CONTAINER_NAME:/tmp/db_restore.sql"
    
    # Use docker_exec to run mysql inside the container to restore the database
    docker_exec "$DB_CONTAINER_NAME" "mysql -h $DB_HOST -P 3306 -u $DB_USERNAME -p$DB_PASSWORD $DB_DATABASE < /tmp/db_restore.sql" "/"
    
    # Remove the temporary restore file from the container
    docker_exec "$DB_CONTAINER_NAME" "rm /tmp/db_restore.sql" "/"
    
    color "green" "✅ Database restored successfully from $LATEST_BACKUP"
    
    exit 0
}


function backup_docker_images {
    local BACKUP_DIR="$SCRIPT_DIR/../backups/docker_images"
    local TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    # Split image names by comma
    IFS=',' read -ra IMAGES <<< "$DOCKER_IMAGES"
    
    for IMAGE in "${IMAGES[@]}"; do
        # Trim whitespace
        IMAGE=$(echo "$IMAGE" | xargs)
        
        if [ -n "$IMAGE" ]; then
            # Create a safe filename (replace / and : with _)
            local SAFE_NAME=${IMAGE//\//_}
            local SAFE_NAME=${SAFE_NAME//:/_}
            local BACKUP_FILE="$BACKUP_DIR/${SAFE_NAME}_${TIMESTAMP}.tar.gz"
            
            color "blue" "📦 Backing up Docker image '$IMAGE'..."
            docker save "$IMAGE" | gzip > "$BACKUP_FILE"
            
            if [ $? -eq 0 ]; then
                color "green" "✅ Successfully backed up image '$IMAGE'"
            else
                color "red" "❌ Failed to backup image '$IMAGE'"
            fi
        fi
    done
    
    color "green" "✅ Docker images backup process completed"
    exit 0
}

function restore_docker_images {
    local BACKUP_DIR="$SCRIPT_DIR/../backups/docker_images"
    
    # Check if backup directory exists
    if [ ! -d "$BACKUP_DIR" ]; then
        color "red" "❌ Backup directory does not exist: $BACKUP_DIR"
        exit 1
    fi
    
    # Split image names by comma
    IFS=',' read -ra IMAGES <<< "$DOCKER_IMAGES"
    
    for IMAGE in "${IMAGES[@]}"; do
        # Trim whitespace
        IMAGE=$(echo "$IMAGE" | xargs)
        
        if [ -n "$IMAGE" ]; then
            # Create a safe filename pattern (replace / and : with _)
            local SAFE_NAME=${IMAGE//\//_}
            local SAFE_NAME=${SAFE_NAME//:/_}
            local PATTERN="${BACKUP_DIR}/${SAFE_NAME}_*.tar.gz"
            
            # Find the latest backup for this image
            local LATEST_BACKUP=$(ls -t $PATTERN 2>/dev/null | head -n 1)
            
            if [ -n "$LATEST_BACKUP" ]; then
                color "blue" "📦 Restoring Docker image '$IMAGE' from $LATEST_BACKUP..."
                gunzip -c "$LATEST_BACKUP" | docker load
                
                if [ $? -eq 0 ]; then
                    color "green" "✅ Successfully restored image '$IMAGE'"
                else
                    color "red" "❌ Failed to restore image '$IMAGE'"
                fi
            else
                color "yellow" "⚠️ No backup found for image '$IMAGE'"
            fi
        fi
    done
    
    color "green" "✅ Docker images restoration process completed"
    color "yellow" "⚠️ You may need to restart your containers with '$DOCKER_CMD up -d'"
    exit 0
}

function check_external_network {
    local network_name="$EXTERNAL_NETWORK"
    
    # Check if network exists
    if ! docker network inspect "$network_name" &>/dev/null; then
        color "yellow" "⚠️ Network '$network_name' does not exist."

        exit 1
    else
        color "green" "✅ Network '$network_name' exists."
        
        exit 0
    fi
}

function docker_exec {
    local container_name="$1"
    local command="$2"
    local exec_path="$3"

    # Check if the container name is provided
    if [[ -z "$container_name" ]]; then
        color "red" "Error: Docker container name is required."
        return 1
    fi

    # Check if the command is provided
    if [[ -z "$command" ]]; then
        color "red" "Error: Command to execute is required."
        return 1
    fi

    # Default exec_path to root ("/") if not specified
    exec_path="${exec_path:-/}"

    # Check if NON_INTERACTIVE is set or if we're not in a TTY
    if [[ "$NON_INTERACTIVE" == "true" ]] || ! tty -s; then
        # Execute without -it flags
        docker exec "$container_name" sh -c "cd $exec_path && $command"
    else
        # Execute with -it flags for interactive use
        docker exec -it "$container_name" sh -c "cd $exec_path && $command"
    fi

    # Capture the result and provide feedback
    if [[ $? -ne 0 ]]; then
        color "red" "Error: Command execution failed in container '$container_name'."
        return 1
    else
        color "green" "Success: Command executed in container '$container_name'."
        return 0
    fi
}

function connect_to_network {
    local container_name="$1"
    local network_name="$2"

    # Check if the container is already connected to the network
    if docker network inspect "$network_name" | grep -q ""Name": "$container_name""; then
        color "yellow" "Container '$container_name' is already connected to network '$network_name'. Skipping."
    else
        color "green" "Connecting container '$container_name' to network '$network_name'..."
        docker network connect "$network_name" "$container_name"
    fi
}

main "$@"
