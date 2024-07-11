#!/bin/ash -l
# shellcheck shell=dash

_yaml_to_properties() {
	local yaml_file="$1"
	yq -o p --properties-separator '=' '... comments = ""' "$yaml_file"
}

_yaml_properties_name() {
	local yaml_file="$1"
	local yaml_properties=$(_yaml_to_properties "$yaml_file")
	local propertyNames=""
	while IFS= read -r propertyLine; do
		propertyName="${propertyLine%%=*}"
		if [ -n "$propertyNames" ]; then
			propertyNames="$propertyNames"$'\n'"$propertyName"
		else
			propertyNames="$propertyName"
		fi
	done < <(echo "$yaml_properties")
	echo "$propertyNames"
}

_yaml_property_value() {
	local yaml_file="$1"
	local propertyName="$2"	
	yq '."$propertyName"' "$yaml_file"
}

_replace_dots() {
	local string="$1"
	local replacement="$2"
	echo "${string}" | sed "s/\./${replacement}/g"
}

_property_value_to_multiline() {
	local propertyValue="$1"
	local lineMark="#LN#"

	propertyValueMultiLine=$(echo "$propertyValue" | sed "s/\\\\n/$lineMark/g")
	propertyValueMultiLine=$(echo "$propertyValueMultiLine" | sed 's/\\/\\\\/g')
	propertyValueMultiLine=$(echo "$propertyValueMultiLine" | sed "s/$lineMark/\n/g")
	propertyValueMultiLine=$(echo "$propertyValueMultiLine" | sed '${/^$/d;}')
	echo "$propertyValueMultiLine"
}

_set_github_output() {
	local propertyName="$1"
	local propertyValue="$2"

	if echo "$propertyValue" | grep -q '\\n'; then
		propertyValueMultiLine=$(_property_value_to_multiline "$propertyValue")
		{
			echo "$propertyName<<EOF"
			printf "%b\n" "$propertyValueMultiLine"
			echo "EOF"
		} >>"$GITHUB_OUTPUT"
	else
		echo "$propertyName=$propertyValue" >>"$GITHUB_OUTPUT"
	fi
}

_set_github_outputs() {
	local properties="$1"
	local propertyNameDotReplace="$2"

	echo "$properties" | while read -r propertyLine; do
		propertyName=$(_replace_dots "${propertyLine%%=*}" "$propertyNameDotReplace")
		propertyValue="${propertyLine#*=}"
		_set_github_output "$propertyName" "$propertyValue"
	done
}

set -e

_propertyNameDotReplace="_"
_yqProperties=$(_yaml_to_properties "$INPUT_YAML_FILE_PATH")

_set_github_outputs "$_yqProperties" "$_propertyNameDotReplace"

exit 0
