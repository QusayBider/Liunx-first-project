#!/bin/bash

# Load dependencies
source gnmi_cli_config.sh
source data_fetcher.sh
source data_comparator.sh
source report_generator.sh

# Prompt the user for a gNMI path
echo "Enter the gNMI path for comparison:"
read gnmi_path

# Validate if the entered path exists in the configuration
if [[ -n "${PATH_TO_CLI[$gnmi_path]}" ]]; then
    generate_report "$gnmi_path"
else
    echo "Error: The gNMI path '$gnmi_path' is not recognized. Please provide a valid path."
fi
