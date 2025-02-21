#!/bin/bash

# Function to parse JSON keys
parse_json_keys() {
    local json=$1
    # Extract the keys by looking for string followed by ":"
    echo "$json" | grep -oP '"\K([^"]+)(?=":)'
}

parse_json_value() {
    local json=$1
    local key=$2

    if [[ "$key" == "mac_address" ]]; then
        # Use a more specific regex to handle the mac_address extraction correctly
        echo "$json" | grep -oP '"mac_address":\s*"([^"]+)"' | sed -E 's/.*"\s*:\s*"([^"]+)".*/\1/'
    else
        # For other keys, use a generic extraction method
        echo "$json" | grep -oP "\"$key\":\s*\"?([^\",}]+)\"?" | sed -E 's/.*: *//;s/"//g'
    fi
}

# Normalize a string to lowercase
normalize_case() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

convert_to_bytes() {
    local value=$1
    local unit=$2

    # Check if the value is a float and remove trailing zeros
    if [[ "$value" =~ ^[0-9]+[.][0-9]+$ ]]; then
        value=$(printf "%.3f" "$value")  # Keeping up to 3 decimals to preserve precision
    fi

    case "$unit" in
        kb)
            # Convert KB to bytes by multiplying by 1024
            echo "$value * 1024" | bc ;;
        mb)
            # Convert MB to bytes by multiplying by 1024*1024
            echo "$value * 1024 * 1024" | bc ;;
        gb)
            # Convert GB to bytes by multiplying by 1024*1024*1024
            echo "$value * 1024 * 1024 * 1024" | bc ;;
        tb)
            # Convert TB to bytes by multiplying by 1024*1024*1024*1024
            echo "$value * 1024 * 1024 * 1024 * 1024" | bc ;;
        pb)
            # Convert PB to bytes by multiplying by 1024^5
            echo "$value * 1024 * 1024 * 1024 * 1024 * 1024" | bc ;;
        g)
            # Convert GB to bytes (10^9, since it's "G" for gigabytes without the "B")
            echo "$value * 1000000000" | bc ;;
        *)
            # If no conversion needed (e.g., already in bytes)
            echo "$value"
            ;;
    esac
}

normalize_precision() {
    printf "%.2f\n" "$1"
}


normalize_value() {
    local value=$1

    # Normalize to lowercase to handle case differences
    value=$(normalize_case "$value")

    # Check if the value is a MAC address and normalize it
    if [[ "$value" =~ ^[0-9a-f]{2}(:[0-9a-f]{2}){5}$ ]]; then
        value=$(echo "$value" | tr '[:upper:]' '[:lower:]')
    fi

    # Remove underscores from the value
    value=$(echo "$value" | tr -d '_')

    # Check if value includes a unit (e.g., KB, MB, GB, TB)
    if [[ "$value" =~ ([0-9.]+)\s*(kb|mb|gb|tb|g) ]]; then
        value=$(convert_to_bytes "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}")
    fi

    # Check for "bytes" suffix in gNMI output and remove it
    if [[ "$value" =~ ([0-9]+)bytes ]]; then
        value="${BASH_REMATCH[1]}"
    fi

    # Handle percentage values (removing the % symbol)
    if [[ "$value" =~ ([0-9.]+)% ]]; then
        value="${BASH_REMATCH[1]}"
    fi

    # If the value is numeric (integer or float), normalize it
    if [[ "$value" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        value=$(normalize_precision "$value")
    fi

    # Return the normalized value
    echo "$value"
}




# Compare gNMI and CLI outputs
compare_outputs() {
    local gnmi_path="$1"

    # Access data
    local gnmi_data="${GNMI_OUTPUTS[$gnmi_path]}"
    local cli_data="${CLI_OUTPUTS[$gnmi_path]}"

    if [[ -z "$gnmi_data" || -z "$cli_data" ]]; then
        echo "Error: gNMI or CLI output for $gnmi_path not found."
        return
    fi

    # Parse and normalize keys
    gnmi_keys=$(parse_json_keys "$gnmi_data" | tr '[:upper:]' '[:lower:]')
    cli_keys=$(echo -e "$cli_data" | awk -F ': ' '{print $1}' | tr '[:upper:]' '[:lower:]')

    # Initialize result variables
    local missing_keys=""
    local extra_keys=""
    local value_mismatches=""

    # Check for missing keys and value mismatches
    for gnmi_key in $gnmi_keys; do
        if ! echo "$cli_keys" | grep -q "^$gnmi_key$"; then
            missing_keys+="$gnmi_key, "
        else
            # Extract and normalize values
            gnmi_value=$(normalize_value "$(parse_json_value "$gnmi_data" "$gnmi_key")")
            cli_value=$(normalize_value "$(echo -e "$cli_data" | grep -i "^$gnmi_key" | awk -F ': ' '{print $2}')")

            if [[ "$gnmi_value" != "$cli_value" ]]; then
                value_mismatches+="$gnmi_key: gNMI value = $gnmi_value, CLI value = $cli_value, "
            fi
        fi
    done

    # Check for extra keys
    for cli_key in $cli_keys; do
        if ! echo "$gnmi_keys" | grep -q "^$cli_key$"; then
            extra_keys+="$cli_key, "
        fi
    done

    # Output results
    [[ -n "$missing_keys" ]] && echo "Missing keys in CLI output: ${missing_keys%, }"
    [[ -n "$extra_keys" ]] && echo "Extra keys in CLI output: ${extra_keys%, }"
    [[ -n "$value_mismatches" ]] && echo "Value mismatches: ${value_mismatches%, }"

    if [[ -z "$missing_keys" && -z "$extra_keys" && -z "$value_mismatches" ]]; then
        echo "All keys and values match for $gnmi_path."
    fi
}



# Function to extract adjacency data from gNMI JSON
extract_gnmi_adjacencies() {
    local json=$1
    echo "$json" | grep -oP '"adjacencies": \[.*?\]' \
        | grep -oP '{"neighbor_id":\s*"[^"]+",\s*"state":\s*"[^"]+"}' \
        | sed -E 's/.*"neighbor_id":\s*"([^"]+)",\s*"state":\s*"([^"]+)".*/\1: \2/' \
        | tr '\n' ', ' | sed 's/, $//'
}

# Function to extract adjacency data from CLI
extract_cli_adjacencies() {
    local data=$1
    echo "$data" | grep -oP 'neighbor_id: [^,]+, state: [^\n]+' \
        | sed -E 's/neighbor_id: ([^,]+), state: ([^\n]+)/\1: \2/' \
        | tr '\n' ', ' | sed 's/, $//'
}

# Function to compare gNMI and CLI outputs
compare_outputs2() {
    local path="$1"
    local gnmi_data="${GNMI_OUTPUTS[$path]}"
    local cli_data="${CLI_OUTPUTS[$path]}"

    if [[ -z "$gnmi_data" || -z "$cli_data" ]]; then
        echo "Error: Missing gNMI or CLI data for path $path."
        return
    fi

    # Extract individual fields from gNMI
    local gnmi_area_id=$(echo "$gnmi_data" | grep -oP '"area_id":\s*"[^"]+"' | sed -E 's/"area_id":\s*"([^"]+)"/\1/')
    local gnmi_active_interfaces=$(echo "$gnmi_data" | grep -oP '"active_interfaces":\s*[0-9]+' | sed -E 's/"active_interfaces":\s*([0-9]+)/\1/')
    local gnmi_lsdb_entries=$(echo "$gnmi_data" | grep -oP '"lsdb_entries":\s*[0-9]+' | sed -E 's/"lsdb_entries":\s*([0-9]+)/\1/')
    local gnmi_adjacencies=$(extract_gnmi_adjacencies "$gnmi_data")

    # Extract individual fields from CLI
    local cli_area_id=$(echo "$cli_data" | grep -oP '^area_id:\s*[^\n]+' | sed -E 's/area_id:\s*(.*)/\1/')
    local cli_active_interfaces=$(echo "$cli_data" | grep -oP '^active_interfaces:\s*[0-9]+' | sed -E 's/active_interfaces:\s*(.*)/\1/')
    local cli_lsdb_entries=$(echo "$cli_data" | grep -oP '^lsdb_entries:\s*[0-9]+' | sed -E 's/lsdb_entries:\s*(.*)/\1/')
    local cli_adjacencies=$(extract_cli_adjacencies "$cli_data")

    # Compare values
    local mismatched_keys=""

    if [[ "$gnmi_area_id" != "$cli_area_id" ]]; then
        mismatched_keys+="area_id (gNMI: $gnmi_area_id, CLI: $cli_area_id), "
    fi
    if [[ "$gnmi_active_interfaces" != "$cli_active_interfaces" ]]; then
        mismatched_keys+="active_interfaces (gNMI: $gnmi_active_interfaces, CLI: $cli_active_interfaces), "
    fi
    if [[ "$gnmi_lsdb_entries" != "$cli_lsdb_entries" ]]; then
        mismatched_keys+="lsdb_entries (gNMI: $gnmi_lsdb_entries, CLI: $cli_lsdb_entries), "
    fi
    if [[ "$gnmi_adjacencies" != "$cli_adjacencies" ]]; then
        mismatched_keys+="adjacencies (gNMI: $gnmi_adjacencies, CLI: $cli_adjacencies), "
    fi

    # Print results
    if [[ -n "$mismatched_keys" ]]; then
        echo "Mismatched keys: ${mismatched_keys%, }"
    else
        echo "All keys and values match for path $path."
    fi
    echo
}
