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

_property_value_to_multiline() {
    local propertyValue="$1"
    local lineMark="#LN#"
    local propertyValueMultiLine=${propertyValue//\\n/$lineMark}
    propertyValueMultiLine=${propertyValueMultiLine//\\/$'\\\\'}
    propertyValueMultiLine=${propertyValueMultiLine//$lineMark/$'\n'}
    propertyValueMultiLine=${propertyValueMultiLine%$'\n'}
    echo "$propertyValueMultiLine"
}

_set_github_output() {
  local propertyName="$1"
  local propertyValue="$2"
  
  if [[ "$propertyValue" =~ '\\n' ]]; then
    propertyValueMultiLine=$(_property_value_to_multiline "$propertyValue")
    {
      echo "$propertyName<<EOF"
      printf "%b\n" "$propertyValueMultiLine"     
      echo "EOF"
    } >> "$GITHUB_OUTPUT"
  else
    echo "$propertyName=$propertyValue" >> "$GITHUB_OUTPUT"
  fi
}

_set_github_outputs() {
  local properties="$1"
  local propertyNameDotReplace="$2"  

  while read -r propertyLine;
  do  
     propertyName=$(_replace_dots "${propertyLine%%=*}" "$propertyNameDotReplace")     
     propertyValue="${propertyLine#*=}"     
    _set_github_output "$propertyName" "$propertyValue"
  done < <(echo "$properties")
}

set -e

_propertyNameDotReplace="_"
_yqProperties=$(_yaml_to_properties "$INPUT_YAML_FILE_PATH")

_set_github_outputs "$_yqProperties" "$_propertyNameDotReplace"

exit 0