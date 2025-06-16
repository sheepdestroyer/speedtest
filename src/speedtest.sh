#!/bin/bash

# Define the log file path
LOG_FILE="./debug.log"
CONFIG_FILE="test-servers-list.txt"

# Associative array to store PID and URL/tempfile, and array for PIDs
declare -A pids_info # Stores "url;temp_file" keyed by PID
active_pids=()   # Stores PIDs for waiting

# Counter for unique temp files
file_counter=0

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}"
}

# --- Main script execution starts here ---

log_message "Script started."

if [ ! -f "${CONFIG_FILE}" ]; then
    log_message "ERROR: Configuration file ${CONFIG_FILE} not found."
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Configuration file ${CONFIG_FILE} not found." >&2
    exit 1
fi

if ! grep -q -v -e '^#' -e '^[[:space:]]*$' "${CONFIG_FILE}"; then
    log_message "ERROR: No active URLs found in ${CONFIG_FILE}."
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: No active URLs found in ${CONFIG_FILE}." >&2
    exit 1
fi

log_message "Reading server list from ${CONFIG_FILE}."

# Use process substitution to read the loop, avoiding subshell issues for array population
while IFS= read -r url || [[ -n "$url" ]]; do
    url=$(echo "${url}" | xargs)
    if [ -z "${url}" ]; then
        continue
    fi

    log_message "Preparing to start speed test for URL: ${url}"

    file_counter=$((file_counter+1))
    current_temp_file="/tmp/speedtest_temp_file_${file_counter}"

    aria2c_base_command="aria2c --min-split-size=1M --max-concurrent-downloads=16 --split=16 --max-connection-per-server=16 --dir=/dev --out=null --allow-overwrite=true --file-allocation=none --check-certificate=false --summary-interval=0 --remove-control-file=true"
    aria2c_command_final="${aria2c_base_command} --out=${current_temp_file} ${url}"

    # Log the command that will be executed
    log_message "Executing command in background: ${aria2c_command_final}"

    eval "${aria2c_command_final}" >> "${LOG_FILE}" 2>&1 &
    pid=$! # No 'local' here

    pids_info[$pid]="${url};${current_temp_file}"
    active_pids+=("${pid}")

    log_message "aria2c process for URL ${url} started in background with PID: ${pid}. Temp file: ${current_temp_file}"

done < <(grep -v -e '^#' -e '^[[:space:]]*$' "${CONFIG_FILE}")


log_message "All download tasks launched. Waiting for completion..."
echo # Newline for console readability

for pid_to_wait in "${active_pids[@]}"; do
    # Retrieve URL and temp file from pids_info
    IFS=';' read -r url_for_pid temp_file_for_pid <<< "${pids_info[$pid_to_wait]}"

    wait "${pid_to_wait}"
    exit_status=$? # No 'local' here

    if [ ${exit_status} -eq 0 ]; then
        log_message "aria2c (PID: ${pid_to_wait}) for URL '${url_for_pid}' completed successfully."
    else
        log_message "aria2c (PID: ${pid_to_wait}) for URL '${url_for_pid}' failed. Exit code: ${exit_status}."
    fi

    log_message "Cleaning up temporary file ${temp_file_for_pid} for PID ${pid_to_wait}"
    rm -f "${temp_file_for_pid}"
done

log_message "All background downloads have finished processing."
log_message "Script finished."
echo "$(date '+%Y-%m-%d %H:%M:%S') - All speed tests processed. Check ${LOG_FILE} for detailed logs."
