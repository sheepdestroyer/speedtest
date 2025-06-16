# Here Jules will list its tasks, individual steps, and mark them as planned or done as you keep track with progress. 

## Speedtest - Implementation Plan (TODO)
This document outlines the steps to build the internet speedtest

## Phase 0 : Init
*   [x] Read all files from the repo.
*   [x] Post-Brainstorming, update README.md with your general direction and technological choices.
*   [x] list tasks.
*   [x] list individual steps for each task.

## Phase 1 : Project Setup 

*   [x] Initialize project structure (directories, files, dependencies..).
*   [x] Set up basic logging.
*   [x] Add `.gitignore`.
*   [x] Keep README and TODO in sync with progress
        
## Phase 2 : Background Processing and Advanced Output Parsing
*   [x] **Task 2.1: Implement Background Downloads.**
    *   [x] Modify \`src/speedtest.sh\` to launch each \`aria2c\` download process in the background.
    *   [x] Manage Process IDs (PIDs) of backgrounded \`aria2c\` instances.
*   [ ] **Task 2.2: Monitor Background Processes.**
    *   [ ] Implement a mechanism to check the status of background \`aria2c\` processes (e.g., still running, completed successfully, failed).
    *   [ ] Ensure proper cleanup of completed or failed processes.
*   [ ] **Task 2.3: Structured Output from \`aria2c\`.**
    *   [ ] Investigate \`aria2c\` options for machine-readable output (e.g., specific log formats, RPC interface if feasible for shell scripting).
    *   [ ] If direct machine-readable output is complex for pure shell, refine parsing of \`aria2c\`'s standard output to extract key metrics reliably (download speed, percentage complete, ETA per file).
    *   [ ] Consider using \`aria2c\`'s \`--summary-interval\` and redirecting output to temporary files for each download if that simplifies parsing.
*   [ ] **Task 2.4: Real-time Data Aggregation.**
    *   [ ] Develop a method to collect and store the parsed real-time data from all active downloads.
    *   [ ] This data will serve as the source for the TUI. This might involve writing to temporary structured files.

## Phase 3 : Text-based User Interface (TUI) Development
*   [ ] **Task 3.1: Research and Select TUI Toolkit.**
    *   [ ] Investigate and choose a suitable TUI toolkit or library compatible with Bash and Fedora 42 (e.g., \`ncurses\` via \`dialog\`, pure Bash ANSI, other CLI UI libraries).
    *   [ ] Document the chosen toolkit and its basic usage.
*   [ ] **Task 3.2: Design TUI Layout.**
    *   [ ] Define the visual structure of the TUI.
    *   [ ] Specify areas for: list of active downloads, overall combined speed, real-time graph, status messages.
*   [ ] **Task 3.3: Implement TUI Structure.**
    *   [ ] Develop the basic framework of the TUI using the selected toolkit.
    *   [ ] Implement functions for drawing and updating different sections of the TUI.
*   [ ] **Task 3.4: Integrate Real-time Data.**
    *   [ ] Connect the TUI to the real-time data aggregated in Phase 2 (Task 2.4).
    *   [ ] Ensure the TUI updates dynamically at a reasonable refresh rate.
*   [ ] **Task 3.5: Implement Bandwidth Display (Gbps/MBps).**
    *   [ ] Add logic to convert bandwidth data into both Megabytes per second (MBps) and Gigabits per second (Gbps).
    *   [ ] Display these values clearly in the TUI.
*   [ ] **Task 3.6: Implement Basic Real-time Graph.**
    *   [ ] Create a simple text-based graph in the TUI (e.g., bar chart or scrolling line graph).

## Phase 4 : Concurrency and Looping
*   [ ] **Task 4.1: Implement True Parallel Downloads.**
    *   [ ] Refactor script to launch and manage multiple \`aria2c\` instances truly concurrently.
    *   [ ] Manage a pool of background jobs and aggregate their data for the TUI.
*   [ ] **Task 4.2: Implement Download Looping Feature.**
    *   [ ] Add a command-line option (e.g., \`--loop\`) to enable continuous downloading.
    *   [ ] If a download finishes, restart it or pick the next server.
*   [ ] **Task 4.3: Resource Management for Concurrency (Advanced).**
    *   [ ] Consider safeguards to prevent overwhelming the system/network with many concurrent, looping downloads.

## General Tasks / Reminders
*   [ ] **Task G.1: Keep Documentation Synchronized.**
    *   [ ] Throughout all development phases, ensure \`README.md\` and \`Jules-TODO.md\` are kept up-to-date with changes and progress.
    *   [ ] Update \`README.md\` as new features are implemented.
    *   [ ] Regularly mark tasks in \`Jules-TODO.md\` as planned, in progress, or done.
