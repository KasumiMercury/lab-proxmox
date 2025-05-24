#!/bin/bash

# all_environments: all environments to be selected from
# provided as a JSON array string
# example: '["dev", "staging", "prod"]'
all_environments=$1
target=$2

if [ -z "$all_environments" ]; then
  echo "No environments provided. Exiting."
  exit 1
fi
if [ -z "$target" ]; then
  echo "No target environment provided. Exiting."
  exit 1
fi

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
