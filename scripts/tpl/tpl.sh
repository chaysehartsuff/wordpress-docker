#!/bin/bash

SCRIPT_DIR="$(realpath "$(dirname "$0")")"

# Parameter definitions
declare -A PARAMETERS=(
    ["test_param"]="string,optional"
)
declare -A PARAMETER_DESCRIPTIONS=(
    ["test_param"]="Test parameter"
)
PARAMETER_ORDER=("test_param")

# Flag definitions
declare -A FLAGS=(
    ["help"]="show_help"
    ["h"]="show_help"
)
declare -A FLAG_DESCRIPTIONS=(
    ["help,h"]="Displays all available parameters and flags"
)

# Protection functions
declare -A PROTECTION=(
)

# Command description
description="Template script to be extended from."

function show_help {
    color "bright_yellow" "Description:"
    color "cyan" "  $description"
    echo

    color "bright_yellow" "Parameters:"
    for param in "${PARAMETER_ORDER[@]}"; do
        # Get the parameter rules from PARAMETERS
        param_rules="${PARAMETERS[$param]}"
        # Check if a description exists for the parameter
        if [[ -n "${PARAMETER_DESCRIPTIONS[$param]}" ]]; then
            param_desc=" ${PARAMETER_DESCRIPTIONS[$param]}"
        else
            param_desc=""
        fi
        color "green" "  $param" -n
        color "bright_blue" "   $param_rules" -n
        color "white" "  $param_desc"
    done
    echo

    color "bright_yellow" "Flags:"
    for flag in "${!FLAG_DESCRIPTIONS[@]}"; do
        if [[ "$flag" == *","* ]]; then
            IFS=',' read -r -a flags <<< "$flag"
            flag_display=""
            for single_flag in "${flags[@]}"; do
                flag_display+="--$single_flag "
            done
            color "magenta" "  $flag_display"
        else
            color "magenta" "  --$flag"
        fi
        color "white" "   ${FLAG_DESCRIPTIONS[$flag]}"
    done

    exit 1
}

# protect functions

# prompt user to proceed
function confirm {
    local message="$1"
    color "yellow" "$message (y/n): " -n
    read -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        color "red" "Action canceled."
        exit 1
    fi
    return 0
}
# Ensures sourced file exists
function source_file {
    local file="$1"

    # Check if path starts with '.' or '..' for relative paths
    if [[ "$file" == ./* || "$file" == ../* ]]; then
        file="$SCRIPT_DIR/$file"
    elif [[ "$file" != /* ]]; then
        # If it's not an absolute path, assume it's relative to $SCRIPT_DIR
        file="$SCRIPT_DIR/$file"
    fi

    # Check if the file exists and source it
    if [[ -f "$file" ]]; then
        source "$file"
    else
        color "red" "Error: Source file " -n
        color "yellow" " '$file'" -n
        color "red" " not found."
        exit 1
    fi
}
# Checks if command exists on system
function check_command {
    local command="$1"
    local show_error="${2:-true}"

    if ! eval "command -v $command" &> /dev/null; then
        if [[ "$show_error" == true ]]; then
            color "red" "Error: Command '$command' not found."
        fi
        return 1
    fi
    return 0
}
# Assigns var_name to available command in parameter list
function assign_command {
    local var_name="$1"
    shift
    local commands=("$@")

    for cmd in "${commands[@]}"; do
        if check_command "$cmd" false; then
            eval "$var_name='$cmd'"
            return 0
        fi
    done

    return 1
}


# get functions
function get_flag {
    local flag_name="$1"
    for flag in "${FLAGS_FOUND[@]}"; do
        if [[ "$flag" == "$flag_name" ]]; then
            return 0
        fi
    done
    return 1
}

function get_param {
    local param_name="$1"
    local param_index=0

    for param in "${PARAMETER_ORDER[@]}"; do
        if [[ "$param" == "$param_name" ]]; then
            echo "${PARAMS[$param_index]:-}"
            return 0
        fi
        ((param_index++))
    done
    echo ""
}

# echo with a color
function color {
    local color_name="$1"
    local text="$2"
    local no_newline="$3"
    local color_code=""

    # Map color names to ANSI codes
    case "$color_name" in
        "black") color_code="\033[30m" ;;
        "red") color_code="\033[31m" ;;
        "green") color_code="\033[32m" ;;
        "yellow") color_code="\033[33m" ;;
        "blue") color_code="\033[34m" ;;
        "magenta") color_code="\033[35m" ;;
        "cyan") color_code="\033[36m" ;;
        "white") color_code="\033[37m" ;;
        "grey") color_code="\033[90m" ;;
        "bright_red") color_code="\033[91m" ;;
        "bright_green") color_code="\033[92m" ;;
        "bright_yellow") color_code="\033[93m" ;;
        "bright_blue") color_code="\033[94m" ;;
        "bright_magenta") color_code="\033[95m" ;;
        "bright_cyan") color_code="\033[96m" ;;
        "bright_white") color_code="\033[97m" ;;
        *)
            echo "Error: Unsupported color '$color_name'"
            return 1
            ;;
    esac

    if [[ "$no_newline" == "-n" ]]; then
        echo -ne "${color_code}${text}\033[0m"
    else
        echo -e "${color_code}${text}\033[0m"
    fi
}


# Validate function to check parameter types
function validate {
    local param_name="$1"
    local param_value="$2"
    local param_properties="${PARAMETERS[$param_name]}"
    
    IFS=',' read -r -a conditions <<< "$param_properties"
    
    local error=""
    local required=true

    for condition in "${conditions[@]}"; do
        case "$condition" in
            "string")
                if [[ ! "$param_value" =~ ^[a-zA-Z0-9_]+$ ]]; then
                    error="Error: Parameter '$param_name' must be a string."
                fi
                ;;
            "integer")
                if [[ ! "$param_value" =~ ^[0-9]+$ ]]; then
                    error="Error: Parameter '$param_name' must be an integer."
                fi
                ;;
            "path")
                if [[ ! -e "$param_value" ]]; then
                    error="Error: Parameter '$param_name' must be a valid path."
                fi
                ;;
            "required")
                required=true
                ;;
            "optional")
                required=false
                ;;
            *)
                error="Error: Unknown condition '$condition' for parameter '$param_name'."
                ;;
        esac
    done

    if [[ -n "$error" && -n "$param_value" ]]; then
        color "red" "$error"
        exit 1
    fi

    if [[ "$required" == true && -z "$param_value" ]]; then
        color "red" "Error: Parameter " -n
        color "yellow" "$param_name" -n
        color "red" " is required but missing."
        exit 1
    fi
}


function run {
    test_param="$(get_param "test_param")"
    if [[ "$test_param" ]]; then
        echo -n "Test param: "
        color "green" "$test_param"
    else
        echo "Base script works."
    fi
}

# Main function to parse parameters and flags
function main {
    local FLAGS_FOUND=()
    local PARAMS=()
    local param_index=0

    # Separate flags and parameters
    for arg in "$@"; do
        if [[ "$arg" == --* ]]; then
            FLAGS_FOUND+=("${arg#--}")  # Remove `--` prefix and add to FLAGS array
        else
            PARAMS+=("$arg")
        fi
    done

    # Match parameters with values in the order defined in PARAMETERS
    for param_name in "${PARAMETER_ORDER[@]}"; do
        local param_value="${PARAMS[$param_index]:-}"
        
        validate "$param_name" "$param_value"
        
        ((param_index++))
    done

    # Process PROTECTION
    for key in "${!PROTECTION[@]}"; do
        if declare -f "$key" > /dev/null; then
            # Split the PROTECTION value by commas into an array
            IFS=',' read -r -a params <<< "${PROTECTION[$key]}"

            # Call the function with each parameter as a separate argument
            if ! "$key" "${params[@]}"; then
                echo "$key failed. Exiting."
                exit 1
            fi
        else
            echo "Error: Protection function '$key' not found."
            exit 1
        fi
    done

    # Process flags
    for flag in "${FLAGS_FOUND[@]}"; do
        if [[ -v FLAGS[$flag] ]]; then
            # If the flag exists in FLAGS and has an associated function, call it
            if [[ -n "${FLAGS[$flag]}" ]]; then
                "${FLAGS[$flag]}"
            fi
        else
            color "red" "Error: Unsupported flag " -n
            color "yellow" "--$flag"
            exit 1
        fi
    done

    run
}

# Do not run main if script is extended
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
