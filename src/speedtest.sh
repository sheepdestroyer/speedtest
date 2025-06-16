#!/bin/bash

# Define the log file path
LOG_FILE="./debug.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "${LOG_FILE}"
}

# --- Main script execution starts here ---

log_message "Script started."

CONFIG_FILE="test-servers-list.txt" # Assuming it's in the same directory as the script

if [ ! -f "${CONFIG_FILE}" ]; then
    log_message "ERROR: Configuration file ${CONFIG_FILE} not found."
    echo "ERROR: Configuration file ${CONFIG_FILE} not found."
    exit 1
fi

# Check if CONFIG_FILE is empty or contains only whitespace/comments
if ! grep -qE '^[[:space:]]*[^#[:space:]]' "${CONFIG_FILE}"; then
    log_message "ERROR: Configuration file ${CONFIG_FILE} is empty or contains no active URLs."
    echo "ERROR: Configuration file ${CONFIG_FILE} is empty or contains no active URLs."
    exit 1
fi

log_message "Reading server list from ${CONFIG_FILE}."
echo "Reading server list from ${CONFIG_FILE}."

# Loop through active URLs in the config file
# Skips lines starting with # and empty lines
grep -E '^[[:space:]]*[^#[:space:]]' "${CONFIG_FILE}" | while IFS= read -r TEST_URL; do
    # Trim leading/trailing whitespace from URL
    TEST_URL=$(echo "${TEST_URL}" | xargs)

    log_message "Starting speed test with aria2c for URL: ${TEST_URL}"
    echo "Starting speed test for URL: ${TEST_URL}"

    # Using settings from previous successful tests for aria2c
    # Outputting to /tmp and cleaning up.
    # Removed --quiet=true to allow aria2c to print its summary to stdout.
    # Using --remove-control-file=true for cleanup.
    aria2c_command="aria2c --min-split-size=1M --max-concurrent-downloads=16 --split=16 --max-connection-per-server=16 --dir=/tmp --out=speedtest_temp_file --allow-overwrite=true --file-allocation=none --check-certificate=false --summary-interval=0 --remove-control-file=true ${TEST_URL}"

    log_message "Executing command: ${aria2c_command}"

    # Execute the command. Pipe its stdout and stderr to tee.
    # tee will print to console and append to LOG_FILE.
    local -a aria2c_args
    aria2c_args=(
        "--min-split-size=1M"
        "--max-concurrent-downloads=16"
        "--split=16"
        "--max-connection-per-server=16"
        "--dir=/tmp"
        "--out=speedtest_temp_file"
        "--allow-overwrite=true"
        "--file-allocation=none"
        # Consider removing --check-certificate=false or making it configurable due to security risks (see separate comment)
        "--check-certificate=false"
        "--summary-interval=0"
        "--remove-control-file=true"
        "${TEST_URL}"
    )

    log_message "Executing command: aria2c $(printf '%q ' "${aria2c_args[@]}")"

    aria2c "${aria2c_args[@]}" 2>&1 | tee -a "${LOG_FILE}"
    exit_status=${PIPESTATUS[0]} # Get exit status of aria2c, not tee

    if [ ${exit_status} -eq 0 ]; then
        log_message "aria2c command completed successfully for URL: ${TEST_URL}."
    else
        log_message "aria2c command failed with exit code ${exit_status} for URL: ${TEST_URL}. Check ${LOG_FILE} for details."
    fi
    # Clean up the downloaded file from /tmp
    rm -f /tmp/speedtest_temp_file
    log_message "Cleaned up /tmp/speedtest_temp_file for URL: ${TEST_URL}."
    echo "Finished test for URL: ${TEST_URL}"
    echo "-----------------------------------------------------"
done

log_message "All speed tests finished."
echo "All speed tests finished. Check ${LOG_FILE} for detailed logs."
