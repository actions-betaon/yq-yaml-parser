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
  local propAndValue="$(printf '%b\n' "$1")"

  echo "$propAndValue"

  #propAndValueUnescaped="$(printf '%b\n' "$propAndValue")"
  #prop="${propAndValue%%=*}"
  #value="${propAndValue#*=}"
  #value="${propAndValueUnescaped//$prop/""}"
  #echo "$propAndValue"
  #echo "$prop"
  #echo "${propAndValue}"
  #echo "$(printf '%b\n' "$propAndValue")"
  #echo "$(printf '%b\n' "$value")"
  if echo $value | grep -iq "\\n"; then
    value_multiline=$(echo "${value//#EOL#/$'\n'}")
    {
      echo "$prop<<EOF"
      echo "$value_multiline"
      echo EOF
    } >> "$GITHUB_OUTPUT"
  else
    echo ""
  fi
}

set -e

_properties=$(_yaml_to_properties "$INPUT_YAML_FILE_PATH")
#_properties_print="$(printf '%b\n' "$_properties")"
_parsed_properties=$(_replace_dots "$_properties" "_")
#_escaped_multiline_properties=$(echo "${_parsed_properties//\\n/#EOL#}")

#properties_ec=$(echo "$(printf '%b\n' "$_properties")")
echo "$(printf '%b\n' "$_parsed_properties")"
#echo "$(printf '%b\n' "$_properties")"
#echo -e "$_properties_print"

# echo $_parsed_properties | while read -r propAndValue;
# do
#   #echo "$propAndValue" >>"$GITHUB_OUTPUT"
#   _set_github_output "$propAndValue"
# done

# Use workflow commands to do things like set debug messages
#echo "::notice file=entrypoint.sh,line=30::$_properties"

# Write outputs to the $GITHUB_OUTPUT file
echo "time=$(date)" >>"$GITHUB_OUTPUT"

exit 0
