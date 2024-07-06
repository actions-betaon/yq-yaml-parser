#!/bin/sh -l

_yaml_to_properties() {
  local yaml_file="$1"
  yq -o p --properties-separator '=' '... comments = ""' "$yaml_file"
}

_replace_dots() {
  local string="$1"
  local replacement="$2"
  echo "${string//./$replacement}"
}

_set_github_output() {  
  local propDotted="$1"
  local value="$2"
  local propDotReplacement="$3"  

  prop=$(_replace_dots "$propDotted" "$propDotReplacement")
  
  valueWithoutLF=$(echo "${value//\\n/}")  
  if [ "$value" != "$valueWithoutLF" ]; then    
    {
      echo "$prop<<EOF"
      echo -e "$value"
      echo "EOF"
    } >> "$GITHUB_OUTPUT"
  else
    echo "$prop=$value" >> "$GITHUB_OUTPUT"
  fi
}

_set_github_outputs() {  
  local parsedProperties="$1"
  local propDotReplacement="$2"  

  echo "$parsedProperties" | while read -r propAndValue;
  do
     prop="${propAndValue%%=*}"
     value="${propAndValue#*=}"
    _set_github_output "$prop" "$value" "$propDotReplacement"
  done
}

set -e

_lineBreakMark="#LF#"

_properties=$(_yaml_to_properties "$INPUT_YAML_FILE_PATH")

_set_github_outputs "$_properties" "_"

# Use workflow commands to do things like set debug messages
#echo "::notice file=entrypoint.sh,line=59::$_properties"

# Write outputs to the $GITHUB_OUTPUT file
echo "time=$(date)" >>"$GITHUB_OUTPUT"

exit 0
