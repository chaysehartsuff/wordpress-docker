source "$(dirname "$BASH_SOURCE")/tpl.sh"

# Parameter definitions
declare -A PARAMETERS=(
    ["script_name"]="string,required"
    ["script_path"]="path,optional"
)
declare -A PARAMETER_DESCRIPTIONS=(
    ["script_name"]="Name of new file."
    ["script_path"]="Path where new script will be created."
)
PARAMETER_ORDER=("script_name" "script_path")

# Flag definitions
declare -A FLAGS=(
    ["help"]="show_help"
    ["h"]="show_help"
    ["create"]=
)
declare -A FLAG_DESCRIPTIONS=(
    ["help,h"]="Displays all available parameters and flags"
    ["create"]="Creates a new script extending base_script.sh"
)

# Protection functions
declare -A PROTECTION=(
)

# Command description
description="Creates new script extending base script."

function run {
    if get_flag "create"; then
        script_name="$(get_param "script_name")"
        confirm "Do you want to generate a new script?"
        echo "Creating new script..."
        script_path="$(get_param "script_path")"
        echo "path: $script_path"
        if [[ -n "$script_path" ]]; then
            create_script "$script_name" "$script_path"
        else
            create_script "$script_name"
        fi
    else
        script_name="$(get_param "script_name")"
        echo -n "Please use the "
        color "yellow" "--create" -n
        echo " flag to confirm creation of $script_name"
    fi
}

function create_script {
    local script_name="$1"
    local custom_path="$2"
    local file_name="${script_name}.sh"

    # Determine the full path based on whether a custom path was provided
    local full_path
    if [[ -n "$custom_path" ]]; then
        full_path="${custom_path}/${file_name}"
    else
        local script_dir="$(realpath "$(dirname "$0")")"  # Absolute path of the current script directory
        full_path="${script_dir}/${file_name}"
    fi

    # Check if the file already exists
    if [[ -f "$full_path" ]]; then
        color "red" "Error: File " -n
        color "yellow" "'$file_name'" -n
        color "red" " already exists in the specified location."
        exit 1
    fi

    # Create the file and make it executable
    touch "$full_path"
    chmod +x "$full_path"

    # Use the globally defined SCRIPT_DIR to hardcode the path to tpl.sh
    cat <<EOL > "$full_path"
#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/tpl/tpl.sh"

# Parameter definitions
declare -A PARAMETERS=(
    ["input"]="string,required"
    ["input2"]="string,optional"
)
declare -A PARAMETER_DESCRIPTIONS=(
    ["input"]="The first input of the script"
    ["input2"]="The second input of the script"
)
PARAMETER_ORDER=("input" "input2")

# Flag definitions
declare -A FLAGS=(
    ["help"]="show_help"
    ["h"]="show_help"
    ["show-input"]=
)
declare -A FLAG_DESCRIPTIONS=(
    ["help,h"]="Displays all available parameters and flags"
    ["show-input"]="Prints the input"
)

# Protection functions
declare -A PROTECTION=(
    ["confirm"]="Are you sure you want to continue?"
)

# Command description
description="Command description."

function run {
    if get_flag "show-input"; then
        echo -n "input: "
        color "green" "\$(get_param "input")"
        echo -n "input2: "
        color "green" "\$(get_param "input2")"
    else
        echo -n "Test script works. Use "
        color "yellow" "--show-input" -n
        echo " to see input values."
    fi
}

main "\$@"
EOL

    color "green" "File " -n
    color "yellow" "'$file_name'" -n
    color "green" " created successfully at" -n
    color "yellow" " '$full_path'"
}


main "$@"
