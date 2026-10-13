#!/usr/bin/env bash
# code generated with assistance of google ai mode, because time is a horrible thing to waste.
# How it works
# Looks for the .ldmp file with latest modification time stamp, then calculates its size. 
# Math logic: File size in bytes. remove 40 bytes for header, and then divide by 8 as each candidate stored as an 8 bit hash.
# C=Candidate, Fb = filesize in bytes 
# C = (FSb - 40b) / 8

# Function to run the calculation once and output a standardized data string
calculate_progress() {
    # Find the most recently modified .ldmp file in the current directory
    local latest_ldmp
    latest_ldmp=$(ls -t *.ldmp 2>/dev/null | head -n 1)

    # Check if an .ldmp file actually exists
    if [ -z "$latest_ldmp" ]; then
        echo "ERROR"
        return 1
    fi

    # Run the Python calculation and return raw metrics separated by pipe
    python3 -c "import os; \
                size = os.path.getsize('$latest_ldmp'); \
                candidates = int((size - 40) / 8); \
                print(f'{os.path.basename(\"$latest_ldmp\")}|{size}|{candidates}')"
}

# Run initial calculation
current_data=$(calculate_progress)

if [ "$current_data" == "ERROR" ]; then
    echo "Error: No .ldmp files found in the current directory."
    exit 1
fi

# Parse the initial metrics for a clean startup display
IFS='|' read -r filename size candidates <<< "$current_data"
timestamp=$(date +"%H:%M:%S")

# Check if the user passed the -r flag
if [ "$1" == "-r" ]; then
    echo "Monitoring latest .ldmp file for changes... Press [Ctrl+C] to stop."
    echo "--------------------------------------------------------------------------------"
    # Print the initial starting state
    printf "[%s] File: %s | Size: %'d bytes | Candidates: %'d\n" "$timestamp" "$filename" "$size" "$candidates"
    
    # Store the previous data payload to monitor updates
    last_data="$current_data"

    # Loop indefinitely until Ctrl+C is pressed
    while true; do
        sleep 5
        current_data=$(calculate_progress)
        
        # Check if the data payload has mutated
        if [ "$current_data" != "$last_data" ] && [ "$current_data" != "ERROR" ]; then
            IFS='|' read -r filename size candidates <<< "$current_data"
            timestamp=$(date +"%H:%M:%S")
            
            # Print only the new, unique update line
            printf "[%s] File: %s | Size: %'d bytes | Candidates: %'d\n" "$timestamp" "$filename" "$size" "$candidates"
            
            # Update the cache
            last_data="$current_data"
        fi
    done
else
    # Run once if no flag is provided
    printf "File: %s | Size: %'d bytes | Candidates: %'d\n" "$filename" "$size" "$candidates"
fi
