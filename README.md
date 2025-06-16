# An aria2c based speedtest

This shell speed test will benchmark 8Gbps internet connections.
It will :

## Project Direction and Technology

This project aims to create a robust command-line internet speed test tool. The script will leverage the power of `aria2c` to perform downloads from a list of test servers, providing insights into internet connection performance.

### Technological Choices

*   **Core Scripting:** The primary script (`src/speedtest.sh`) is written in **Bash**, ensuring wide compatibility and access to powerful shell utilities.
*   **Download Engine:** **`aria2c`** is used for its multi-connection and multi-segment download capabilities, which are essential for accurately benchmarking high-speed connections. The script utilizes options such as `--min-split-size`, `--max-concurrent-downloads`, `--split`, and `--max-connection-per-server` to optimize downloads.
*   **Configuration:** Test server URLs are managed externally in the `test-servers-list.txt` file, allowing for easy updates and customization.
*   **Logging:** Detailed logs of script operations and `aria2c` status messages (including errors and final outputs) are stored in `./debug.log`. Individual `aria2c` process outputs are temporarily stored and cleaned up.
*   **Output & Real-time Statistics:** The script actively monitors the background `aria2c` download processes. It parses `aria2c`'s summary output (which is captured from each process) to extract per-second download speeds. Furthermore, it calculates and displays a real-time aggregated download speed (in KB/s) for all concurrent downloads, updating this information directly on the console. Future enhancements might include more sophisticated graphing (e.g., TUI based) and display in additional units like Gbps/MBps.
*   **Concurrency:** The script launches download tasks for multiple servers (from `test-servers-list.txt`) concurrently using background processes. It then monitors these processes, collects individual speed data, and aggregates it to provide a total real-time speed.

- Be based around the following aria2c commmand options :  
`aria2c --min-split-size=1M --max-concurrent-downloads=16 --split=16 --max-connection-per-server=16 --dir=/dev --out=/dev/null --summary-interval=1 --remove-control-file=true $(TEST_URL_BIG_FILE)`

- Download directly to `/dev/null` so storage is not a bottleneck

- Be threaded, so it can launch this command simultaneously for as many test URLs provided in test-servers-list.txt, for instance :
```
http://appliwave.testdebit.info/1G.iso
http://speedtest.milkywan.fr/files/1G.iso
http://scaleway.testdebit.info/1G.iso
```

- Use the most modern and efficient shell libraries available on Fedora 42

- Log to ./debug.log

- Graph real time stats refresh at 10 fps

- Display realtime bandwidth values in both Gbps and in MBps.
 
- Have a cmdline option should activate looping : re-starting individual downloads when they end
