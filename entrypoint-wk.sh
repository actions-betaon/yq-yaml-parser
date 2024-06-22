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
  local prop="$1"
  local value="$2"
  local lineBreakMark="$3"

  if echo $value | grep -iq "$lineBreakMark"; then
    value_multiline=$(echo "${value//$lineBreakMark/$'\n'}")
    {
      echo "$prop<<EOF"
      echo "$value_multiline"
      echo EOF
    } >> "$GITHUB_OUTPUT"
  else
    echo "$prop=$value" >>"$GITHUB_OUTPUT"
  fi
}

_set_github_outputs() {  
  local parsedProperties="$1"
  local lineBreakMark="$2"

  echo "$parsedProperties" | while read -r propAndValue;
  do
     prop="${propAndValue%%=*}"
     value="${propAndValue#*=}"
    _set_github_output "$prop" "$value" "$lineBreakMark"
  done
}

set -e

_lineBreakMark="#LF#"

_properties=$(_yaml_to_properties "$INPUT_YAML_FILE_PATH")
_escaped_multiline_properties=$(echo "${_properties//\\n/$_lineBreakMark}")
_parsed_properties=$(_replace_dots "$_escaped_multiline_properties" "_")

echo "Parsed properties: $_parsed_properties"

_set_github_outputs "$_parsed_properties" "$_lineBreakMark"

# Use workflow commands to do things like set debug messages
#echo "::notice file=entrypoint.sh,line=30::$_properties"

# Write outputs to the $GITHUB_OUTPUT file
echo "time=$(date)" >>"$GITHUB_OUTPUT"

exit 0
