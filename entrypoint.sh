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

# _escape_backslashes() {
#   local inputString="$1"
#   echo "${inputString//\\\\/\\\\\\\\}"
# }

_escape_backslashes() {
  local inputString="$1"  
  for word in $inputString; do    
    if [[ $word == *'\\\n'* ]]; then      
      echo -n "${word//\\/\\\\} "
    else      
      echo -n "$word "
    fi
  done  
}

_set_github_output() {
  local propertyName="$1"
  local propertyValue="$2"  
  
  propertyValueWithoutLineEscape=$(printf "%s" "${propertyValue}" | sed 's/\\n//g')
  if [ "$propertyValue" != "$propertyValueWithoutLineEscape" ]; then    
    {
      echo "$propertyName<<EOF"
      printf "%b\n" "$propertyValue"
      echo "EOF"
    } >> "$GITHUB_OUTPUT"
  else
    echo "$propertyName=$propertyValue" >> "$GITHUB_OUTPUT"
  fi
}

_set_github_outputs() {
  local properties="$1"
  local propertyNameDotReplace="$2"  

  echo "$properties" | while read -r propertyLine;
  do  
     propertyName=$(_replace_dots "${propertyLine%%=*}" "$propertyNameDotReplace")
     propertyValue=$(_escape_backslashes "${propertyLine#*=}")
     echo "$propertyLine"
     echo "$propertyValue"     

    _set_github_output "$propertyName" "$propertyValue"
  done
}

set -e

_propertyNameDotReplace="_"
_yqProperties=$(_yaml_to_properties "$INPUT_YAML_FILE_PATH")

_set_github_outputs "$_yqProperties" "$_propertyNameDotReplace"

# Use workflow commands to do things like set debug messages
#echo "::notice file=entrypoint.sh,line=59::$_properties"

# Write outputs to the $GITHUB_OUTPUT file
echo "time=$(date)" >>"$GITHUB_OUTPUT"

exit 0
