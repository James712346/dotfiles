#!/usr/bin/env bash

### GLOBAL CONSTANTS ###
# ANSI Escape Sequences
declare -rx ERROR_TEXT="\033[1;31m"
declare -rx DEBUG_TEXT="\033[1;33m"
declare -rx STATUS_TEXT="\033[1;32m"
declare -rx ADDRESS_TEXT="\033[1;34m"
declare -rx PATH_TEXT="\033[1;35m"
declare -rx RESET_TEXT="\033[0m"

# Exit Codes
declare -rx EC_DSPLY_UNSET=1
declare -rx EC_CDIR_FAILED=2
declare -rx EC_MISSING_DEP=3
declare -rx EC_NO_WACONFIG=4
declare -rx EC_BAD_BACKEND=5
declare -rx EC_WIN_NOT_SPEC=6
declare -rx EC_NO_WIN_FOUND=7

# Paths
declare -rx ICONS_PATH="./Icons"
declare -rx APPDATA_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/winapps"
declare -rx CONFIG_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/winapps"
declare -rx CONFIG_FILE="${CONFIG_PATH}/winapps.conf"
declare -rx COMPOSE_FILE="${CONFIG_PATH}/compose.yaml"
declare -rx USER_WINAPPS_APPLICATIONS="${APPDATA_PATH}/apps"
declare -rx SYSTEM_WINAPPS_APPLICATIONS="/usr/local/share/winapps/apps"

# Other
declare -rx DEFAULT_VM_NAME="RDPWindows"
declare -rx CONTAINER_NAME="WinApps"
declare -rx DEFAULT_FLAVOR="docker"

### GLOBAL VARIABLES ###
declare -x WINAPPS_PATH="" # Generated programmatically following dependency checks.
declare -x WAFLAVOR=""     # As specified within the WinApps configuration file.
declare -x VM_NAME=""      # Export VM_NAME for subshells
declare -x ROFI_THEME=""   # Custom rofi theme path
declare -x ROFI_THEME_ARG="" # Built theme argument for rofi

### FUNCTIONS ###
# Check 'x11'/'wayland' Display Server Protocol
function check_dsp() {
    if [[ -n "$XDG_SESSION_TYPE" && "$XDG_SESSION_TYPE" == "wayland" ]]; then
        # Rofi works natively on Wayland, no need to force X11
        export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
    fi
}

# Check WinApps Configuration File Exists
function check_config_exists() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        # Throw an error.
        show_error_message "ERROR: WinApps configuration file NOT FOUND.\nPlease ensure ${CONFIG_FILE} exists."
        exit "$EC_NO_WACONFIG"
    fi
}

# Read WinApps configuration file
function read_winapps_config_file() {
    # Read the WinApps configuration file line by line.
    while IFS= read -r LINE; do
        # Check if the line begins with 'WAFLAVOR='.
        if [[ "$LINE" == WAFLAVOR=\"* ]]; then
            # Extract the value.
            WAFLAVOR=$(echo "$LINE" | sed -n '/^WAFLAVOR="/s/^WAFLAVOR="\([^"]*\)".*/\1/p')
        # Check if the line begins with 'VM_NAME='.
        elif [[ "$LINE" == VM_NAME=\"* ]]; then
            # Extract the value.
            VM_NAME=$(echo "$LINE" | sed -n '/^VM_NAME="/s/^VM_NAME="\([^"]*\)".*/\1/p')
        # Check if the line begins with 'ROFI_THEME='.
        elif [[ "$LINE" == ROFI_THEME=\"* ]]; then
            # Extract the value.
            ROFI_THEME=$(echo "$LINE" | sed -n '/^ROFI_THEME="/s/^ROFI_THEME="\([^"]*\)".*/\1/p')
        fi
    done < "$CONFIG_FILE"

    # Use the default VM name if a name was not specified.
    if [[ -z "$VM_NAME" ]]; then
        VM_NAME="$DEFAULT_VM_NAME"
        echo -e "${DEBUG_TEXT}> USING DEFAULT VM_NAME '${VM_NAME}'${RESET_TEXT}"
    else
        echo -e "${DEBUG_TEXT}> USING VM NAME '${VM_NAME}'${RESET_TEXT}"
    fi

    # Use the default WinApps flavor if a flavor was not specified.
    if [[ -z "$WAFLAVOR" ]]; then
        WAFLAVOR="$DEFAULT_FLAVOR"
        echo -e "${DEBUG_TEXT}> USING DEFAULT BACKEND '${WAFLAVOR}'${RESET_TEXT}"
    else
        # Check if a valid flavor was specified.
        if [[ "$WAFLAVOR" != "docker" && "$WAFLAVOR" != "podman" && "$WAFLAVOR" != "libvirt" && "$WAFLAVOR" != "manual" ]]; then
            # Throw an error.
            show_error_message "ERROR: Specified WinApps backend '${WAFLAVOR}' INVALID.\nPlease ensure 'WAFLAVOR' is set to \"docker\", \"podman\", \"libvirt\", or \"manual\" within ${CONFIG_FILE}."
            exit "$EC_BAD_BACKEND"
        else
            echo -e "${DEBUG_TEXT}> USING BACKEND '${WAFLAVOR}'${RESET_TEXT}"
        fi
    fi

    # Set up rofi theme argument if a theme was specified.
    if [[ -n "$ROFI_THEME" ]]; then
        # Expand tilde to home directory if present
        ROFI_THEME="${ROFI_THEME/#\~/$HOME}"
        
        if [[ -f "$ROFI_THEME" ]]; then
            ROFI_THEME_ARG="-theme $ROFI_THEME"
            echo -e "${DEBUG_TEXT}> USING ROFI THEME '${ROFI_THEME}'${RESET_TEXT}"
        else
            echo -e "${DEBUG_TEXT}> WARNING: ROFI THEME FILE NOT FOUND '${ROFI_THEME}'${RESET_TEXT}"
            ROFI_THEME_ARG=""
        fi
    else
        echo -e "${DEBUG_TEXT}> USING DEFAULT ROFI THEME${RESET_TEXT}"
        ROFI_THEME_ARG=""
    fi
}

# Check FreeRDP Running
function check_freerdp_running() {
    if find "${APPDATA_PATH}" -maxdepth 1 -name 'FreeRDP_Process_*.cproc' -print -quit | grep -q .; then
        echo "YES"
    else
        echo "NO"
    fi
}
export -f check_freerdp_running

# Kill FreeRDP
function kill_freerdp() {
    # Declare variables.
    local TERMINATED_PROCESS_IDS=()
    local TERMINATED_PROCESS_IDS_STRING=""

    # Loop through each matching file and add to the array
    for FREERDP_PROCESS_FILE in "${APPDATA_PATH}/FreeRDP_Process_"*.cproc; do
        # This check ensures the pattern is not treated as a literal string if no files match the pattern.
        if [ -f "$FREERDP_PROCESS_FILE" ]; then
            # Extract the file name from the path.
            FREERDP_PROCESS_FILE=$(basename "$FREERDP_PROCESS_FILE")

            # Remove the 'FreeRDP_Process_' prefix.
            FREERDP_PROCESS_FILE="${FREERDP_PROCESS_FILE#FreeRDP_Process_}"

            # Remove the '.cproc' file extension.
            FREERDP_PROCESS_FILE="${FREERDP_PROCESS_FILE%.cproc}"

            # Terminate the process (SIGKILL).
            kill -9 "$FREERDP_PROCESS_FILE" &>/dev/null

            # Print debug feedback.
            echo -e "${DEBUG_TEXT}> KILLED FREERDP PROCESS '${FREERDP_PROCESS_FILE}'${RESET_TEXT}"

            # Add the process ID to the list of terminated processes.
            TERMINATED_PROCESS_IDS+=("$FREERDP_PROCESS_FILE")
        fi
    done

    # Convert the array of process IDs to a comma-delimited string.
    TERMINATED_PROCESS_IDS_STRING=$(printf "%s, " "${TERMINATED_PROCESS_IDS[@]}" | sed 's/, $//')

    # Display feedback if any processes were terminated.
    [ ${#TERMINATED_PROCESS_IDS[@]} -ne 0 ] && show_error_message "KILLED FreeRDP process(es): ${TERMINATED_PROCESS_IDS_STRING}."
}
export -f kill_freerdp

# Error Message
function show_error_message() {
    local MESSAGE="${1}"
    
    # Use rofi for error display
    rofi -e "$MESSAGE" $ROFI_THEME_ARG &
}
export -f show_error_message

# Info Message
function show_info_message() {
    local MESSAGE="${1}"
    
    # Use rofi for info display
    rofi -e "$MESSAGE" $ROFI_THEME_ARG &
}
export -f show_info_message

# Application Selection
function app_select() {
    if check_reachable; then
        local ALL_FILES=()
        local APP_LIST=()
        local SORTED_APP_LIST=()
        local SELECTED_APP=""

        # Store the paths of all files within the directory 'WINAPPS_PATH'.
        ALL_FILES=()
        while IFS= read -r file; do
            ALL_FILES+=("$file")
        done < <(find "$WINAPPS_PATH" -maxdepth 1 -type f)

        # Ignore files that do not contain "${WINAPPS_PATH}/winapps".
        # Ignore files named "winapps" and "windows".
        for FILE in "${ALL_FILES[@]}"; do
            if grep -q "${WINAPPS_PATH}/winapps" "$FILE" && [ "$(basename "$FILE")" != "windows" ] && [ "$(basename "$FILE")" != "winapps" ]; then
                # Store the filename.
                FILENAME=$(basename "$FILE")

                # Store the application name.
                if [ -f "${USER_WINAPPS_APPLICATIONS}/${FILENAME}/info" ]; then
                    # WinApps 'User' Installation.
                    # Identify the 'FULL_NAME' line and extract the string within double quotes.
                    APPNAME=$(grep '^FULL_NAME=' "${USER_WINAPPS_APPLICATIONS}/${FILENAME}/info" | sed 's/^FULL_NAME="//;s/"$//')
                elif [ -f "${SYSTEM_WINAPPS_APPLICATIONS}/${FILENAME}/info" ]; then
                    # WinApps 'System' Installation.
                    # Identify the 'FULL_NAME' line and extract the string within double quotes.
                    APPNAME=$(grep '^FULL_NAME=' "${SYSTEM_WINAPPS_APPLICATIONS}/${FILENAME}/info" | sed 's/^FULL_NAME="//;s/"$//')
                else
                    # Set the application name as the file name.
                    APPNAME="$FILENAME"
                fi

                # Store names in arrays.
                APP_LIST+=("${APPNAME}|${FILENAME}")
            fi
        done

        # Sort applications in alphabetical order based on the application name.
        SORTED_APP_LIST=()
        while IFS= read -r line; do
            SORTED_APP_LIST+=("$line")
        done < <(printf "%s\n" "${APP_LIST[@]}" | sort)

        # Build menu string
        local MENU_STRING=""
        for APP in "${SORTED_APP_LIST[@]}"; do
            IFS='|' read -r application_name file_name <<< "$APP"
            MENU_STRING+="${application_name}\n"
        done

        # Display application selection with rofi
        SELECTED_APP=$(echo -e "$MENU_STRING" | rofi -dmenu -i -p "Select Windows Application" $ROFI_THEME_ARG)

        if [ -n "$SELECTED_APP" ]; then
            # Find the corresponding file name
            for APP in "${SORTED_APP_LIST[@]}"; do
                IFS='|' read -r application_name file_name <<< "$APP"
                if [ "$application_name" = "$SELECTED_APP" ]; then
                    # Run Selected Application
                    winapps "$file_name" &>/dev/null &
                    echo -e "${DEBUG_TEXT}> LAUNCHED '${file_name}'${RESET_TEXT}"
                    break
                fi
            done
        fi
    fi
}
export -f app_select

# Launch Windows
function launch_windows() {
    if check_reachable; then
        # Run Windows
        winapps windows &>/dev/null &
        echo -e "${DEBUG_TEXT}> LAUNCHED WINDOWS RDP SESSION${RESET_TEXT}"
    fi
}
export -f launch_windows

# Check Windows Exists
function check_windows_exists() {
    if [[ $WAFLAVOR == "libvirt" ]]; then
        # Check Virtual Machine State
        local WINSTATE=""
        WINSTATE=$(LC_ALL=C virsh domstate "$VM_NAME" 2>&1 | xargs)

        if grep -q "argument is empty" <<< "$WINSTATE"; then
            # Unspecified
            show_error_message "ERROR: Windows VM NOT SPECIFIED.\nPlease ensure a virtual machine name is specified."
            exit "$EC_WIN_NOT_SPEC"
        elif grep -q "failed to get domain" <<< "$WINSTATE"; then
            # Not Found
            show_error_message "ERROR: Windows VM NOT FOUND.\nPlease ensure '${VM_NAME}' exists."
            exit "$EC_NO_WIN_FOUND"
        fi
    elif [[ $WAFLAVOR == "podman" ]]; then
        if ! podman ps --all --filter name="WinApps" | grep -q "$CONTAINER_NAME"; then
            # Not Found
            show_error_message "ERROR: Podman container '${CONTAINER_NAME}' NOT FOUND.\nPlease ensure '${CONTAINER_NAME}' exists."
            exit "$EC_NO_WIN_FOUND"
        fi
    elif [[ $WAFLAVOR == "docker" ]]; then
        if ! docker ps --all --filter name="WinApps" | grep -q "$CONTAINER_NAME"; then
            # Not Found
            show_error_message "ERROR: Docker container '${CONTAINER_NAME}' NOT FOUND.\nPlease ensure '${CONTAINER_NAME}' exists."
            exit "$EC_NO_WIN_FOUND"
        fi
    fi
}
export -f check_windows_exists

# Check Reachable
function check_reachable() {
    # Only bother checking if Windows is reachable when using 'libvirt'.
    if [[ "$WAFLAVOR" == "libvirt" ]]; then
        # shellcheck disable=SC2155 # Silence warning regarding declaring and assigning variables separately.
        local VM_MAC=$(LC_ALL=C virsh domiflist "$VM_NAME" | grep -Eo '([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})') # Virtual Machine MAC Address
        # shellcheck disable=SC2155 # Silence warning regarding declaring and assigning variables separately.
        local VM_IP=$(ip neigh show | grep "$VM_MAC" | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}") # Virtual Machine IP Address

        if [ -z "$VM_IP" ]; then
            # Empty
            show_error_message "ERROR: Windows VM is UNREACHABLE.\nPlease ensure '${VM_NAME}' has an IP address."
            return 1
        else
            # Not Empty
            # Print Feedback
            echo -e "${ADDRESS_TEXT}# VM MAC ADDRESS: ${VM_MAC}${RESET_TEXT}"
            echo -e "${ADDRESS_TEXT}# VM IP ADDRESS: ${VM_IP}${RESET_TEXT}"
        fi
    fi
}
export -f check_reachable

# Get Windows State
function get_windows_state() {
    local STATE=""

    if [[ "$WAFLAVOR" == "manual" ]]; then
        echo "MANUAL"
        return
    fi

    # Check Windows State
    if [[ "$WAFLAVOR" == "libvirt" ]]; then
        # Possible values are 'running', 'paused' and 'shut off'.
        STATE=$(LC_ALL=C virsh domstate "$VM_NAME" 2>&1 | xargs)

        # Map state to standard terminology.
        if [[ "$STATE" == "running" ]]; then
            echo "ON"
        elif [[ "$STATE" == "paused" ]]; then
            echo "PAUSED"
        elif [[ "$STATE" == "shut off" ]]; then
            echo "OFF"
        fi
    elif [[ "$WAFLAVOR" == "podman" ]]; then
        # Possible values are 'created', 'up', 'paused', 'stopping' and 'exited'.
        STATE=$(podman ps --all --filter name="$CONTAINER_NAME" --format '{{.Status}}')
        STATE=${STATE,,} # Convert the string to lowercase.
        STATE=${STATE%% *} # Extract the first word.

        # Map state to standard terminology.
        if [[ "$STATE" == "up" ]] || [[ "$STATE" == "stopping" ]]; then
            echo "ON"
        elif [[ "$STATE" == "paused" ]]; then
            echo "PAUSED"
        elif [[ "$STATE" == "exited" ]] || [[ "$STATE" == "created" ]]; then
            echo "OFF"
        fi
    elif [[ "$WAFLAVOR" == "docker" ]]; then
        # Possible values are 'created', 'restarting', 'up', 'paused' and 'exited'.
        STATE=$(docker ps --all --filter name="$CONTAINER_NAME" --format '{{.Status}}')
        STATE=${STATE,,} # Convert the string to lowercase.
        STATE=${STATE%% *} # Extract the first word.

        # Map state to standard terminology.
        if [[ "$STATE" == "up" ]] || [[ "$STATE" == "restarting" ]]; then
            echo "ON"
        elif [[ "$STATE" == "paused" ]]; then
            echo "PAUSED"
        elif [[ "$STATE" == "exited" ]] || [[ "$STATE" == "created" ]]; then
            echo "OFF"
        fi
    fi
}
export -f get_windows_state

# Show Main Menu
function show_main_menu() {
    local STATE=$(get_windows_state)
    
    # Print Feedback
    echo -e "${STATUS_TEXT}* VM STATE: ${STATE}${RESET_TEXT}"

    local MENU_OPTIONS=""

    if [[ "$STATE" == "MANUAL" ]]; then
        MENU_OPTIONS="Applications\nLaunch Windows\nKill FreeRDP\nQuit"
    elif [[ "$STATE" == "ON" ]]; then
        MENU_OPTIONS="Applications\nLaunch Windows\nPause\nHibernate\nPower Off\nReboot\nForce Power Off\nReset\nKill FreeRDP\nQuit"
    elif [[ "$STATE" == "PAUSED" ]]; then
        MENU_OPTIONS="Resume\nHibernate\nPower Off\nReboot\nForce Power Off\nReset\nKill FreeRDP\nQuit"
    elif [[ "$STATE" == "OFF" ]]; then
        MENU_OPTIONS="Power On\nKill FreeRDP\nQuit"
    fi

    local CHOICE=$(echo -e "$MENU_OPTIONS" | rofi -dmenu -i -p "WinApps Launcher [${STATE}]" $ROFI_THEME_ARG)

    case "$CHOICE" in
        "Applications")
            app_select
            show_main_menu
            ;;
        "Launch Windows")
            launch_windows
            show_main_menu
            ;;
        "Power On")
            start_windows
            show_main_menu
            ;;
        "Power Off")
            stop_windows
            show_main_menu
            ;;
        "Pause")
            pause_windows
            show_main_menu
            ;;
        "Resume")
            resume_windows
            show_main_menu
            ;;
        "Reboot")
            reboot_windows
            show_main_menu
            ;;
        "Reset")
            reset_windows
            show_main_menu
            ;;
        "Force Power Off")
            force_stop_windows
            show_main_menu
            ;;
        "Hibernate")
            hibernate_windows
            show_main_menu
            ;;
        "Kill FreeRDP")
            kill_freerdp
            show_main_menu
            ;;
        "Quit")
            exit 0
            ;;
        *)
            # Empty selection or ESC pressed
            exit 0
            ;;
    esac
}
export -f show_main_menu

# Start Windows
function start_windows() {
    if [[ "$WAFLAVOR" == "manual" ]]; then
        echo -e "${DEBUG_TEXT}> SKIPPING VM CONTROL IN 'manual' MODE${RESET_TEXT}"
        return
    fi
    
    # Issue Command
    if [[ "$WAFLAVOR" == "libvirt" ]]; then
        virsh start "$VM_NAME" &>/dev/null &
        wait $!
        echo -e "${DEBUG_TEXT}> STARTED '${VM_NAME}'${RESET_TEXT}"
    elif [[ "$WAFLAVOR" == "podman" ]]; then
        podman-compose --file "$COMPOSE_FILE" start &>/dev/null &
        wait $!
        echo -e "${DEBUG_TEXT}> STARTED '${CONTAINER_NAME}'${RESET_TEXT}"
    elif [[ "$WAFLAVOR" == "docker" ]]; then
        docker compose --file "$COMPOSE_FILE" start &>/dev/null &
        wait $!
        echo -e "${DEBUG_TEXT}> STARTED '${CONTAINER_NAME}'${RESET_TEXT}"
    fi
}
export -f start_windows

# Stop Windows
function stop_windows() {
    if [[ "$(check_freerdp_running)" == "YES" ]]; then
        # FreeRDP Sessions Running
        show_error_message "ERROR: Powering Off Windows VM FAILED.\nPlease ensure all FreeRDP instance(s) are terminated."
    else
        # Issue Command
        if [[ "$WAFLAVOR" == "libvirt" ]]; then
            virsh shutdown "$VM_NAME" &>/dev/null &
            wait $!
            echo -e "${DEBUG_TEXT}> POWERED OFF '${VM_NAME}'${RESET_TEXT}"
        elif [[ "$WAFLAVOR" == "podman" ]]; then
            podman-compose --file "$COMPOSE_FILE" stop &>/dev/null &
            wait $!
            echo -e "${DEBUG_TEXT}> POWERED OFF '${CONTAINER_NAME}'${RESET_TEXT}"
        elif [[ "$WAFLAVOR" == "docker" ]]; then
            docker compose --file "$COMPOSE_FILE" stop &>/dev/null &
            wait $!
            echo -e "${DEBUG_TEXT}> POWERED OFF '${CONTAINER_NAME}'${RESET_TEXT}"
        fi
    fi
}
export -f stop_windows

# Pause Windows
function pause_windows() {
    if [[ "$(check_freerdp_running)" == "YES" ]]; then
        # FreeRDP Sessions Running
        show_error_message "ERROR: Pausing Windows VM FAILED.\nPlease ensure all FreeRDP instance(s) are terminated."
    else
        # Issue Command
        if [[ "$WAFLAVOR" == "libvirt" ]]; then
            virsh suspend "$VM_NAME" &>/dev/null &
            wait $!
            echo -e "${DEBUG_TEXT}> PAUSED '${VM_NAME}'${RESET_TEXT}"
        elif [[ "$WAFLAVOR" == "podman" ]]; then
            podman-compose --file "$COMPOSE_FILE" pause &>/dev/null &
            wait $!
            echo -e "${DEBUG_TEXT}> PAUSED '${CONTAINER_NAME}'${RESET_TEXT}"
        elif [[ "$WAFLAVOR" == "docker" ]]; then
            docker compose --file "$COMPOSE_FILE" pause &>/dev/null &
            wait $!
            echo -e "${DEBUG_TEXT}> PAUSED '${CONTAINER_NAME}'${RESET_TEXT}"
        fi
    fi
}
export -f pause_windows

# Resume Windows
function resume_windows() {
    # Issue Command
    if [[ "$WAFLAVOR" == "libvirt" ]]; then
        virsh resume "$VM_NAME" &>/dev/null &
        wait $!
        echo -e "${DEBUG_TEXT}> RESUMED '${VM_NAME}'${RESET_TEXT}"
    elif [[ "$WAFLAVOR" == "podman" ]]; then
        podman-compose --file "$COMPOSE_FILE" unpause &>/dev/null &
        wait $!
        echo -e "${DEBUG_TEXT}> RESUMED '${CONTAINER_NAME}'${RESET_TEXT}"
    elif [[ "$WAFLAVOR" == "docker" ]]; then
        docker compose --file "$COMPOSE_FILE" unpause &>/dev/null &
        wait $!
        echo -e "${DEBUG_TEXT}> RESUMED '${CONTAINER_NAME}'${RESET_TEXT}"
    fi
}
export -f resume_windows

# Reset Windows
function reset_windows() {
    # Issue Command
    if [[ "$WAFLAVOR" == "libvirt" ]]; then
        virsh reset "$VM_NAME" &>/dev/null &
        wait $!
        echo -e "${DEBUG_TEXT}> RESET '${VM_NAME}'${RESET_TEXT}"
    elif [[ "$WAFLAVOR" == "podman" ]]; then
        podman-compose --file "$COMPOSE_FILE" kill &>/dev/null &
        wait $!
        podman-compose --file "$COMPOSE_FILE" start &>/dev/null &
        wait $!
        echo -e "${DEBUG_TEXT}> RESET '${CONTAINER_NAME}'${RESET_TEXT}"
    elif [[ "$WAFLAVOR" == "docker" ]]; then
        docker compose --file "$COMPOSE_FILE" kill &>/dev/null &
        wait $!
        docker compose --file "$COMPOSE_FILE" start &>/dev/null &
        wait $!
        echo -e "${DEBUG_TEXT}> RESET '${CONTAINER_NAME}'${RESET_TEXT}"
    fi
}
export -f reset_windows

# Reboot Windows
function reboot_windows() {
    if [[ "$(check_freerdp_running)" == "YES" ]]; then
        # FreeRDP Sessions Running
        show_error_message "ERROR: Rebooting Windows VM FAILED.\nPlease ensure all FreeRDP instance(s) are terminated."
    else
        # Issue Command
        if [[ "$WAFLAVOR" == "libvirt" ]]; then
            virsh reboot "$VM_NAME" &>/dev/null &
            wait $!
            echo -e "${DEBUG_TEXT}> RESTARTED '${VM_NAME}'${RESET_TEXT}"
        elif [[ "$WAFLAVOR" == "podman" ]]; then
            podman-compose --file "$COMPOSE_FILE" restart &>/dev/null &
            wait $!
            echo -e "${DEBUG_TEXT}> RESTARTED '${CONTAINER_NAME}'${RESET_TEXT}"
        elif [[ "$WAFLAVOR" == "docker" ]]; then
            docker compose --file "$COMPOSE_FILE" restart &>/dev/null &
            wait $!
            echo -e "${DEBUG_TEXT}> RESTARTED '${CONTAINER_NAME}'${RESET_TEXT}"
        fi
    fi
}
export -f reboot_windows

# Force Stop Windows
function force_stop_windows() {
    # Issue Command
    if [[ "$WAFLAVOR" == "libvirt" ]]; then
        virsh destroy "$VM_NAME" --graceful &>/dev/null &
        wait $!
        echo -e "${DEBUG_TEXT}> FORCE STOPPED '${VM_NAME}'${RESET_TEXT}"
    elif [[ "$WAFLAVOR" == "podman" ]]; then
        podman-compose --file "$COMPOSE_FILE" kill &>/dev/null &
        wait $!
        echo -e "${DEBUG_TEXT}> FORCE STOPPED '${CONTAINER_NAME}'${RESET_TEXT}"
    elif [[ "$WAFLAVOR" == "docker" ]]; then
        docker compose --file "$COMPOSE_FILE" kill &>/dev/null &
        wait $!
        echo -e "${DEBUG_TEXT}> FORCE STOPPED '${CONTAINER_NAME}'${RESET_TEXT}"
    fi
}
export -f force_stop_windows

# Hibernate Windows
function hibernate_windows() {
    if [[ "$(check_freerdp_running)" == "YES" ]]; then
        # FreeRDP Sessions Running
        show_error_message "ERROR: Hibernating Windows VM FAILED.\nPlease ensure all FreeRDP instance(s) are terminated."
    else
        # Issue Command
        if [[ "$WAFLAVOR" == "libvirt" ]]; then
            virsh managedsave "$VM_NAME" &>/dev/null &
            wait $!
            echo -e "${DEBUG_TEXT}> HIBERNATED '${VM_NAME}'${RESET_TEXT}"
        else
            # Throw an error.
            show_error_message "ERROR: Hibernation is NOT SUPPORTED with the current configuration.\nTo enable hibernation, please use 'libvirt' instead of 'Docker' or 'Podman'."
        fi
    fi
}
export -f hibernate_windows

### SEQUENTIAL LOGIC ###
# Check display server protocol.
check_dsp

# Check 'DISPLAY' variable.
[ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ] || exit "$EC_DSPLY_UNSET"

# SET WORKING DIRECTORY.
if cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"; then
    # Print Feedback
    echo -e "${PATH_TEXT}WORKING DIRECTORY: '$(pwd)'${RESET_TEXT}"
else
    echo -e "${ERROR_TEXT}ERROR:${RESET_TEXT} Failed to change directory to the script location."
    exit "$EC_CDIR_FAILED"
fi

# CHECK DEPENDENCIES.
# 'rofi'
if ! command -v rofi &> /dev/null; then
    echo -e "${ERROR_TEXT}ERROR:${RESET_TEXT} 'rofi' not installed."
    exit "$EC_MISSING_DEP"
fi

# 'winapps'
if ! command -v winapps &> /dev/null; then
    show_error_message "ERROR: 'winapps' NOT FOUND.\nPlease ensure 'winapps' is installed."
    exit "$EC_MISSING_DEP"
else
    WINAPPS_PATH=$(dirname "$(which winapps)")
fi

# INITIALISATION.
check_config_exists
read_winapps_config_file

# 'libvirt' (only check if needed)
if [[ "$WAFLAVOR" == "libvirt" ]]; then
    if ! command -v virsh &> /dev/null; then
        show_error_message "ERROR: 'libvirt' NOT FOUND.\nPlease ensure 'libvirt' is installed."
        exit "$EC_MISSING_DEP"
    fi
fi

check_windows_exists

# Show the main menu
show_main_menu
