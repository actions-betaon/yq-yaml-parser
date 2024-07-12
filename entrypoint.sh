#!/bin/ash -l
# shellcheck shell=dash

_yaml_keys_names_outputs_values_default() {
	local file="$1"
	local dotReplacement="$2"

	properties=$(yq -o p --properties-separator "=" '... comments = ""' "$file")

	keysNamesOutputsValues=""
	echo "$properties" | while read -r propertyLine; do
		keyName="${propertyLine%%=*}"
		keyNameOutput=$(_replace_dots "$keyName" "$dotReplacement")
		keyNameOutputValue="${propertyLine#*=}"
		echo "${keysNamesOutputsValues:+$keysNamesOutputsValues$'\n'}$keyNameOutput=$keyNameOutputValue"
	done
}

_yaml_keys_names_outputs_values_filter() {
	local keysNamesOutputsValues="$1"
	local keysNamesOutputsFilter="$2"

	keysNamesOutputsFiltered=""
	echo "$keysNamesOutputsValues" | while read -r keyNameOutputLine; do
		keyNameOutput="${keyNameOutputLine%%=*}"
		if echo "$keysNamesOutputsFilter" | grep -Fxq -- "$keyNameOutput"; then
			echo "${keysNamesOutputsFiltered:+$keysNamesOutputsFiltered$'\n'}$keyNameOutputLine"
		fi
	done
}

_yaml_keys_names_outputs_values_rename() {
	local keysNamesOutputsValues="$1"
	local keysNamesOutputsRename="$2"
	local dotReplacement="$3"

	keysNamesOutputsRenamed=""
	echo "$keysNamesOutputsValues" | while read -r keyNameOutputLine; do
		keyNameOutputSearch="${keyNameOutputLine%%=*}"
		keyNameOutputValue="${keyNameOutputLine#*=}"

		keyNameOutputRenameValue=$(_yaml_keys_names_outputs_values_rename_value "$keyNameOutputSearch" "$keysNamesOutputsRename" "$dotReplacement")
		keyNameOutput=${keyNameOutputRenameValue:-$keyNameOutputSearch}
		echo "${keysNamesOutputsRenamed:+$keysNamesOutputsRenamed$'\n'}$keyNameOutput=$keyNameOutputValue"
	done
}

_yaml_keys_names_outputs_values_rename_value() {
	local keyNameOutputSearch="$1"
	local keysNamesOutputsRename="$2"
	local dotReplacement="$3"

	keysNamesOutputsRenamed=""
	echo "$keysNamesOutputsRename" | while read -r keyNameOutputRenameLine; do
		keyNameOutputRename="${keyNameOutputRenameLine%%=*}"
		keyNameOutputRenameValue="${keyNameOutputRenameLine#*=}"

		if [ "$keyNameOutputRename" = "$keyNameOutputSearch" ]; then
			keyNameOutputRenamed=$(_replace_dots "$keyNameOutputRenameValue" "$dotReplacement")
			echo "$keyNameOutputRenamed"
			break
		fi
	done
}

_yaml_keys_names_outputs_values() {
	local file="$1"
	local filteringKeys="$2"
	local renamingOutptus="$3"
	local dotReplacement="$4"

	keysNamesValuesOutputsResult=$(_yaml_keys_names_outputs_values_default "$file" "$dotReplacement")

	if [ -n "$filteringKeys" ]; then
		keysNamesValuesOutputsResult=$(_yaml_keys_names_outputs_values_filter "$keysNamesValuesOutputsResult" "$filteringKeys")
	fi

	if [ -n "$renamingOutptus" ]; then
		keysNamesValuesOutputsResult=$(_yaml_keys_names_outputs_values_rename "$keysNamesValuesOutputsResult" "$renamingOutptus" "$dotReplacement")
	fi

	echo "$keysNamesValuesOutputsResult"
}

_replace_dots() {
	local string="$1"
	local replacement="$2"
	echo "${string}" | sed "s/\./${replacement}/g"
}

_key_name_output_value_to_multiline() {
	local keyNameOutputValue="$1"
	local lineMark="#LN#"
    
	keyNameOutputValueMultiline=$(echo "$keyNameOutputValue" | sed "s/\\\\n/$lineMark/g")
	keyNameOutputValueMultiline=$(echo "$keyNameOutputValueMultiline" | sed 's/\\/\\\\/g')
	keyNameOutputValueMultiline=$(echo "$keyNameOutputValueMultiline" | sed "s/$lineMark/\n/g")
	#keyNameOutputValueMultiline=$(echo "$propertyValueMultiLine" | sed '${/^$/d;}')
	echo "$keyNameOutputValueMultiline"
}

_set_github_output() {	
	local keyNameOutput="$1"
	local keyNameOutputValue="$2"
	
	keyNameOutputValueEscapedLineCount=$(echo -e "$keyNameOutputValue" | wc -l)
	
	if [ $keyNameOutputValueEscapedLineCount -gt 1 ]; then
		keyNameOutputValueMultiline=$(_key_name_output_value_to_multiline "$keyNameOutputValue")
		{
			echo "$keyNameOutput<<EOF"
			echo -e "$keyNameOutputValueMultiline"
			echo "EOF"
		} >>"$GITHUB_OUTPUT"
	else
		echo "$keyNameOutput=$keyNameOutputValue" >>"$GITHUB_OUTPUT"
	fi
}

_set_github_outputs() {
	local yamlFile="$1"
	local filteringKeys="$2"
	local renamingOutputs="$3"
	local dotReplacement="$4"

	keysNamesOutputsValues=$(_yaml_keys_names_outputs_values "$yamlFile" "$filteringKeys" "$renamingOutputs" "$dotReplacement")
	echo "Keys names outputs:"
	echo "$keysNamesOutputsValues"

	echo "$keysNamesOutputsValues" | while read -r keyNameOutputValueLine; do
		keyNameOutput="${keyNameOutputValueLine%%=*}"
		keyNameOutputValue="${keyNameOutputValueLine#*=}"
		_set_github_output "$keyNameOutput" "$keyNameOutputValue"
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
