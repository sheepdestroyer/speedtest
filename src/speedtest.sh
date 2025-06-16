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

# Function to convert speed string (e.g., 500KiB/s, 1.2MiB/s) to KB/s
# Uses bc for calculations. Treats KiB as KB (1:1 as per simplified requirement).
convert_to_kbps() {
    local speed_str=$1
    local speed_kbps=0
    local numeric_val=$(echo "${speed_str}" | grep -o -E '[0-9.]+')

    if [[ -z "${numeric_val}" ]]; then
        echo "0"
        return
    fi

    if [[ "${speed_str}" == *"GiB/s"* ]]; then
        # 1 GiB/s = 1024 * 1024 KB/s
        speed_kbps=$(echo "${numeric_val} * 1024 * 1024" | bc)
    elif [[ "${speed_str}" == *"MiB/s"* ]]; then
        # 1 MiB/s = 1024 KB/s
        speed_kbps=$(echo "${numeric_val} * 1024" | bc)
    elif [[ "${speed_str}" == *"KiB/s"* ]]; then
        # Treat KiB/s as KB/s (1:1)
        speed_kbps=$(echo "${numeric_val}" | bc)
    elif [[ "${speed_str}" == *"B/s"* ]]; then
        # Convert B/s to KB/s
        speed_kbps=$(echo "${numeric_val} / 1024" | bc)
    else
        # If no unit or unknown unit, assume it's KB/s or not a speed, return 0 or numeric_val if appropriate
        # For now, returning numeric_val if it's just a number, else 0.
        # This part might need refinement based on actual aria2c outputs for very slow speeds.
        if [[ "${speed_str}" =~ ^[0-9.]+$ ]]; then
            speed_kbps=$(echo "${numeric_val}" | bc) # Assuming it's KB/s if just a number
        else
            speed_kbps="0" # Default to 0 if format is unexpected
        fi
    fi
    # Ensure output is a number, default to 0 if bc had issues (e.g. empty input)
    if [[ ! "$speed_kbps" =~ ^[0-9.]+$ ]]; then
        echo "0"
    else
        printf "%.2f" "${speed_kbps}" # Format to two decimal places
    fi
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
    # This temp file is for aria2c's stdout/stderr, not the downloaded file itself.
    aria2c_status_temp_file="/tmp/aria2c_status_${file_counter}.log"

    # Updated base command: summary-interval=1, out=/dev/null explicitly.
    # aria2c status messages (summary, errors) will be redirected to aria2c_status_temp_file.
    aria2c_base_command="aria2c --min-split-size=1M --max-concurrent-downloads=16 --split=16 --max-connection-per-server=16 --dir=/dev --out=/dev/null --allow-overwrite=true --file-allocation=none --check-certificate=false --summary-interval=1 --remove-control-file=true"
    # The URL is the last argument for aria2c
    aria2c_command_final="${aria2c_base_command} ${url}"

    # Log the command that will be executed
    log_message "Executing command in background: ${aria2c_command_final}"
    log_message "aria2c status for this process will be captured in: ${aria2c_status_temp_file}"

    # Execute aria2c, redirecting its stdout and stderr to its unique status temp file
    eval "${aria2c_command_final}" > "${aria2c_status_temp_file}" 2>&1 &
    pid=$! # No 'local' here

    # Store URL and the aria2c status temp file path in pids_info
    pids_info[$pid]="${url};${aria2c_status_temp_file}"
    active_pids+=("${pid}")

    log_message "aria2c process for URL ${url} started with PID: ${pid}. Status file: ${aria2c_status_temp_file}"

done < <(grep -v -e '^#' -e '^[[:space:]]*$' "${CONFIG_FILE}")

log_message "All download tasks launched. Monitoring background processes..."
echo # Newline for console readability

# Initialize total speed accumulator
total_speed_kbps=0.00

while [ ${#active_pids[@]} -gt 0 ]; do
    # Reset total speed for this monitoring cycle
    total_speed_kbps=0.00
    # Create a copy of active_pids to iterate over, allowing modification of the original array
    current_pids=("${active_pids[@]}")

    for pid_to_check in "${current_pids[@]}"; do
        # Retrieve URL and status temp file from pids_info for the current PID
        # temp_file_for_pid here is the aria2c_status_temp_file
        IFS=';' read -r url_for_pid temp_file_for_pid <<< "${pids_info[$pid_to_check]}"

        # Check if the process is still running
        if kill -0 "${pid_to_check}" 2>/dev/null; then
            # Process is still running, try to read its speed from its status temp file
            if [ -f "${temp_file_for_pid}" ] && [ -s "${temp_file_for_pid}" ]; then
                last_line=$(tail -n 1 "${temp_file_for_pid}")
                # Example summary line: [#HASH DL:10.2MiB ETA:35s] Downloaded: 10.2MiB (28%) Rate: 298KiB/s Users: 1
                # Or at the very beginning: [DL:0B ETA:0s]
                # Or other messages like [NOTICE] Connecting to X servers
                if [[ "${last_line}" == *"Rate:"* ]]; then
                    # Extracts "298KiB/s" from "Rate: 298KiB/s"
                    extracted_rate=$(echo "${last_line}" | grep -o 'Rate: [^ ]*' | cut -d' ' -f2)
                    if [ -n "${extracted_rate}" ]; then
                        current_speed_kbps=$(convert_to_kbps "${extracted_rate}")
                        log_message "MONITOR: PID ${pid_to_check} (${url_for_pid}): Current Speed - ${extracted_rate} (${current_speed_kbps} KB/s)"
                        total_speed_kbps=$(echo "${total_speed_kbps} + ${current_speed_kbps}" | bc)
                    else
                        # This case should ideally not be reached if "Rate:" is present and cut works.
                        log_message "MONITOR: PID ${pid_to_check} (${url_for_pid}): Rate found but extraction failed from: '${last_line}'"
                    fi
                elif [[ "${last_line}" == *"[METADATA]"* || "${last_line}" == *"[NOTICE] Verification:"* || "${last_line}" == *"[NOTICE] Download complete:"* || "${last_line}" == *"[NOTICE] Connecting to"* || "${last_line}" == *"[DL:"* ]]; then
                    # These are normal aria2c messages, not summary lines with speed or lines we want to parse for speed.
                    # Log minimally or do nothing if too verbose.
                    log_message "MONITOR: PID ${pid_to_check} (${url_for_pid}): Received status line: '${last_line}' (No rate info)"
                else
                    # Any other line not matching above, potentially an error or unexpected output
                    log_message "MONITOR: PID ${pid_to_check} (${url_for_pid}): Waiting for speed summary, current line: '${last_line}'"
                fi
            else
                 log_message "MONITOR: PID ${pid_to_check} (${url_for_pid}): Status file ${temp_file_for_pid} is empty or not found yet."
            fi
        else
            # Process has finished
            wait "${pid_to_check}"
            exit_status=$?
            # url_for_pid and temp_file_for_pid are already retrieved before this if/else block

            if [ ${exit_status} -eq 0 ]; then
                log_message "SUCCESS: PID ${pid_to_check} (URL: ${url_for_pid}) completed successfully."
            else
                log_message "FAILED: PID ${pid_to_check} (URL: ${url_for_pid}) failed with exit code: ${exit_status}."
            fi

            if [ -f "${temp_file_for_pid}" ]; then
                 log_message "INFO: Final status messages for PID ${pid_to_check} from ${temp_file_for_pid}:"
                 tail -n 5 "${temp_file_for_pid}" | sed 's/^/    /' >> "${LOG_FILE}" # Log last few lines indented
            else
                 log_message "INFO: Status file ${temp_file_for_pid} for PID ${pid_to_check} was not found upon completion."
            fi

            log_message "CLEANUP: Removing status file ${temp_file_for_pid} for PID ${pid_to_check}."
            rm -f "${temp_file_for_pid}"

            # Remove PID from active_pids array
            # This requires creating a new array without the finished PID
            new_active_pids=()
            for pid_in_active in "${active_pids[@]}"; do
                if [ "${pid_in_active}" != "${pid_to_check}" ]; then
                    new_active_pids+=("${pid_in_active}")
                fi
            done
            active_pids=("${new_active_pids[@]}")
            unset pids_info[$pid_to_check] # Also remove from associative array

            log_message "MONITOR: PID ${pid_to_check} removed. Active PIDs remaining: ${#active_pids[@]}."
        fi
    done

    # Display the aggregated speed for the current cycle
    printf "Total Download Speed: %.2f KB/s\r" "${total_speed_kbps}"

    # Sleep for a short interval to prevent busy-waiting
    sleep 1
done

# Print a newline to move off the constantly updating speed line
echo ""

log_message "All background downloads have finished processing."
# Final summary message (total_speed_kbps is reset each cycle, so not printing it here)
log_message "Script finished. Real-time aggregated speed was displayed during monitoring."
echo "$(date '+%Y-%m-%d %H:%M:%S') - All speed tests processed. Check ${LOG_FILE} for detailed logs."
