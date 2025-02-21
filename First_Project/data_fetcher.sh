fetch_data() {
    local gnmi_path=$1
    
    # Check if the gnmi_path exists in GNMI_OUTPUTS
    if [[ -n "${GNMI_OUTPUTS[$gnmi_path]}" ]]; then
        echo "gNMI Output for $gnmi_path:"
        echo "${GNMI_OUTPUTS[$gnmi_path]}"
    else
        echo "gNMI Output for $gnmi_path not found"
    fi

    # Check if the gnmi_path exists in CLI_OUTPUTS
    if [[ -n "${CLI_OUTPUTS[$gnmi_path]}" ]]; then
        echo "CLI Output for $gnmi_path:"
        echo -e "${CLI_OUTPUTS[$gnmi_path]}"
    else
        echo "CLI Output for $gnmi_path not found"
    fi
}
