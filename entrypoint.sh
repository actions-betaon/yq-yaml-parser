#!/bin/sh -l

_yaml_to_properties() {
  local yaml_file="$1"
  yq -o p --properties-separator '=' '... comments = ""' "$yaml_file"
}

_replace_dots() {
  local string="$1"
  local replacement="$2"
  echo "$string" | awk -v rep="$replacement" 'BEGIN{FS=OFS=":"} {gsub(/\./,rep,$1); print}'
}

_set_github_output() {
  local propAndValue="$1"
  prop="${propAndValue%%=*}"
  value="${propAndValue#*=}"
  echo "${value//\\n/$'\n'}"
  if echo "$value" | grep -q "\\n"; then
    {
      echo "$prop<<EOF"
      echo "${value//\\n/$'\n'}"
      echo EOF
    } >> "$GITHUB_OUTPUT"
  else
    #echo "$propAndValue" >>"$GITHUB_OUTPUT"
    echo "N\A"
  fi
}

set -e

_properties=$(_yaml_to_properties "$INPUT_YAML_FILE_PATH")
_parsed_properties=$(_replace_dots "$_properties" "_")

#echo "$_properties"
#echo "$_parsed_properties"

echo "$_parsed_properties" | while read -r propAndValue;
do
  #echo "$propAndValue" >>"$GITHUB_OUTPUT"
  _set_github_output "$propAndValue"
done

# Use workflow commands to do things like set debug messages
#echo "::notice file=entrypoint.sh,line=30::$_properties"

# Write outputs to the $GITHUB_OUTPUT file
echo "time=$(date)" >>"$GITHUB_OUTPUT"

exit 0
