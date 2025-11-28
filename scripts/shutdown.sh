#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/tpl/tpl.sh"

declare -A PARAMETERS=(

)
declare -A PARAMETER_DESCRIPTIONS=(

)
PARAMETER_ORDER=()

# Command description
description="Script to shut down Docker Compose and optionally clean up Docker resources."

# Define parameters and flags
declare -A FLAGS=(
    ["remove-containers"]="remove_containers"
    ["remove-images"]="remove_images"
    ["remove-volumes"]="remove_volumes"
    ["remove-networks"]="remove_networks"
    ["remove-all"]="remove_all"
    ["clear-cache"]="clear_cache"
    ["help"]="show_help"
    ["h"]="show_help"
)

# Define flag descriptions
declare -A FLAG_DESCRIPTIONS=(
    ["remove-containers"]="Removes all stopped containers."
    ["remove-images"]="Removes all unused images."
    ["remove-volumes"]="Removes all unused volumes."
    ["remove-networks"]="Removes all unused networks."
    ["remove-all"]="Stops all running containers and removes all containers, images, volumes, and networks."
    ["clear-cache"]="Clears Docker build cache."
    ["help,h"]="Displays this help message."
)

# Main functions for each flag
function remove_containers {
    color "yellow" "Removing all stopped containers..."
    docker container prune -f
}

function remove_images {
    color "yellow" "Removing all unused images..."
    docker image prune -a -f
}

function remove_volumes {
    color "yellow" "Removing all unused volumes..."
    docker volume prune -f
}

function remove_networks {
    color "yellow" "Removing all unused networks..."
    docker network prune -f
}

function remove_all {
    color "yellow" "Stopping all running containers and removing all containers, images, volumes, and networks..."
    docker system prune -a --volumes -f
}

function clear_cache {
    color "yellow" "Clearing Docker build cache..."
    docker builder prune -f
}

# Default action
function default_action {
    color "green" "Bringing down Docker Compose..."
    docker compose down
}

# Execute the main script logic
function run {
    get_flag "help" && show_help

    default_action

    for flag in "remove-containers" "remove-images" "remove-volumes" "remove-networks" "remove-all" "clear-cache"; do
        if get_flag "$flag"; then
            "$flag"
        fi
    done
}

# Run the main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
