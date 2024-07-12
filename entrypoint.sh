#!/bin/ash -l
# shellcheck shell=dash

_yaml_keys_names() {
	local file="$1"

	properties=$(yq -o p --properties-separator '=' '... comments = ""' "$file")

	keysNames=""
	while read -r propertyLine; do
		keyName="${propertyLine%%=*}"
		if [ -n "$keysNames" ]; then
			keysNames="$keysNames"$'\n'
		fi
		keysNames="$keysNames$keyName"
	done < <(echo "$properties")
	echo "$keysNames"
}

_yaml_keys_names_outputs_default() {
	local file="$1"
	local dotReplacement="$2"

	keysNames=$(_yaml_keys_names "$file")

	keysNamesOutputs=""
	while read -r keyNameLine; do
		keyName="$keyNameLine"
		keyNameOutput=$(_replace_dots "$keyName" "$dotReplacement")

		if [ -n "$keysNamesOutputs" ]; then
			keysNamesOutputs="$keysNamesOutputs"$'\n'
		fi
		keysNamesOutputs="$keysNamesOutputs$keyName=$keyNameOutput"
	done < <(echo "$keysNames")
	echo "$keysNamesOutputs"
}

_yaml_keys_names_outputs_filter() {
	local keysNamesOutputs="$1"
	local keysNamesOutputsFilter="$2"

	keysNamesOutputsFiltered=""
	while read -r keyNameOutputLine; do
		keyName="${keyNameOutputLine%%=*}"
		keyNameOutput="${keyNameOutputLine#*=}"

		if echo "$keysNamesOutputsFilter" | grep -qx "$keyNameOutput"; then
			if [ -n "$keysNamesOutputsFiltered" ]; then
				keysNamesOutputsFiltered="$keysNamesOutputsFiltered"$'\n'
			fi
			keysNamesOutputsFiltered="$keysNamesOutputsFiltered$keyNameOutputLine"
		fi
	done < <(echo "$keysNamesOutputs")
	echo "$keysNamesOutputsFiltered"
}

_yaml_keys_names_outputs_rename() {
	local keysNamesOutputs="$1"
	local keysNamesOutputsRename="$2"
	local dotReplacement="$3"

	keysNamesOutputsRenamed=""
	while read -r keyNameOutputLine; do
		keyName="${keyNameOutputLine%%=*}"
		keyNameOutput="${keyNameOutputLine#*=}"

		keyNameOutputRenamed=$(echo "$keysNamesOutputsRename" | grep "^${keyNameOutput}=" | cut -d'=' -f2-)
		keyNameOutputRenamed=$(_replace_dots "$keyNameOutputRenamed" "$dotReplacement")

		keyNameOutput=${keyNameOutputRenamed:-$keyNameOutput}

		if [ -n "$keysNamesOutputsRenamed" ]; then
			keysNamesOutputsRenamed="$keysNamesOutputsRenamed"$'\n'
		fi
		keysNamesOutputsRenamed="$keysNamesOutputsRenamed$keyName=$keyNameOutput"
	done < <(echo "$keysNamesOutputs")
	echo "$keysNamesOutputsRenamed"
}

_yaml_keys_names_outputs() {
	local file="$1"
	local filteringKeys="$2"
	local renamingOutptus="$3"
	local dotReplacement="$4"

	keysNamesOutputsDefault=$(_yaml_keys_names_outputs_default "$file" "$dotReplacement")
	keysNamesOutputsFilter=$(_yaml_keys_names_outputs_filter "$keysNamesOutputsDefault" "$filteringKeys")
	keysNamesOutputs=$(_yaml_keys_names_outputs_rename "$keysNamesOutputsFilter" "$renamingOutptus" "$dotReplacement")
	echo "$keysNamesOutputs"
}

_yaml_key_value() {
	local file="$1"
	local keyName="$2"
	yq ".$keyName" "$file"
}

_replace_dots() {
	local string="$1"
	local replacement="$2"
	echo "${string}" | sed "s/\./${replacement}/g"
}

_key_value_to_multiline() {
	local keyValue="$1"
	local lineMark="#LN#"

	keyValueMultiLine=$(echo "$keyValue" | sed "s/\\\\n/$lineMark/g")
	keyValueMultiLine=$(echo "$keyValueMultiLine" | sed 's/\\/\\\\/g')
	keyValueMultiLine=$(echo "$keyValueMultiLine" | sed "s/$lineMark/\n/g")
	keyValueMultiLine=$(echo "$keyValueMultiLine" | sed '${/^$/d;}')
	echo "$keyValueMultiLine"
}

_set_github_output() {
	local yamlFile="$1"
	local keyName="$2"
	local keyNameOutput="$3"

	KeyValue=$(_yaml_key_value "$yamlFile" "$keyName")

	if echo "$KeyValue" | grep -q '\\n'; then
		keyValueMultiLine=$(_key_value_to_multiline "$KeyValue")
		{
			echo "$keyNameOutput<<EOF"
			printf "%b\n" "$keyValueMultiLine"
			echo "EOF"
		} >>"$GITHUB_OUTPUT"
	else
		echo "$keyNameOutput=$KeyValue" >>"$GITHUB_OUTPUT"
	fi
}

_set_github_outputs() {
	local yamlFile="$1"
	local filteringKeys="$2"
	local renamingOutputs="$3"
	local dotReplacement="$4"

	keysNamesOutputs=$(_yaml_keys_names_outputs "$yamlFile" "$filteringKeys" "$renamingOutputs" "$dotReplacement")

	echo "$keysNamesOutputs" | while read -r keyNameOutputLine; do
		keyName="${keyNameOutputLine%%=*}"
		keyNameOutput="${keyNameOutputLine#*=}"
		_set_github_output "$yamlFile" "$keyName" "$keyNameOutput"
	done
}

set -e

_dotReplacement="_"

_set_github_outputs \
	"$INPUT_YAML_FILE_PATH" \
	"$INPUT_YAML_FILTERING_KEYS" \
	"$INPUT_YAML_RENAMING_OUTPUTS" \
	"$_dotReplacement"

exit 0
