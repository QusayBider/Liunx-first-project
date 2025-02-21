#!/bin/bash

# Generate a detailed report for a gNMI path
generate_report() {
    local gnmi_path=$1
    local gnmi_output=${GNMI_OUTPUTS[$gnmi_path]}
    local cli_output=${CLI_OUTPUTS[$gnmi_path]}

    echo "### Comparison for gNMI Path: $gnmi_path ###"
    echo " "
    echo "gNMI Output: $gnmi_output"
    echo -e "CLI Output: $cli_output"
     if [[ "$gnmi_path" != "/ospf/areas/area[id=0.0.0.0]/state" ]]; then
        compare_outputs "$gnmi_path"
    else 
        compare_outputs2 "$gnmi_path"
    fi
    echo
}
