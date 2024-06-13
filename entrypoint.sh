#!/bin/sh -l

_yaml_to_properties() {
  local yaml_file="$1"
  yq -o p --properties-separator ':' '... comments = ""' "$yaml_file"
}

_replace_dots() {
  local string="$1"
  local replacement="$2"
  echo "$string" | awk -v rep="$replacement" 'BEGIN{FS=OFS=":"} {gsub(/\./,rep,$1); print}'
}

set -e

#_properties=$(_yaml_to_properties "$INPUT_YAML_FILE_PATH")
#_parsed_properties=$(_replace_dots "$properties" "_")

# Use INPUT_<INPUT_NAME> to get the value of an input
GREETING="Hello, $INPUT_WHO_TO_GREET!"

# Use workflow commands to do things like set debug messages
#echo "::notice file=entrypoint.sh,line=23::$GREETING"

# Write outputs to the $GITHUB_OUTPUT file
#echo "time=$(date)" >>"$GITHUB_OUTPUT"

exit 0
