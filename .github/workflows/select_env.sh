#!/bin/bash

# all_environments: all environments to be selected from
# provided as a JSON array string
# example: '["dev", "staging", "prod"]'
target=$1

if [ -z "$target" ]; then
  echo "No target environment provided. Exiting."
  exit 1
fi

# get all environments from /terraform/environments directory
all_environments=$(find ./terraform/environments -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | jq -R . | jq -s . | jq -c .)
echo "All environments: $all_environments"

target_env=()

# Convert the JSON array to a bash array
all_environments=$(echo "$all_environments" | jq -r '.[]')

if [ "$target" == "all" ]; then
  # If target is "all", select all environments
  target_env=("$all_environments")
else
  # If target is not "all", check if it exists in the provided environments
  if [[ $all_environments =~ $target ]]; then
    target_env=("$target")
  else
    echo "Target environment '$target' not found in the provided environments. Exiting."
    exit 1
  fi
fi

printf "%s\n" "${target_env[@]}" | jq -R . | jq -s . | jq -c .
