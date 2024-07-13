#!/bin/ash -l
# shellcheck shell=dash

_yaml_keys_names_outputs_values_default() {
	local file="$1"
	local dotReplacement="$2"

	properties=$(yq -o p --properties-separator "=" '... comments = ""' "$file")

	echo "$properties" | while read -r propertyLine; do
		keyName="${propertyLine%%=*}"
		keyNameOutput=$(_replace_dots "$keyName" "$dotReplacement")
		keyNameOutputValue="${propertyLine#*=}"
		echo "$keyNameOutput=$keyNameOutputValue"
	done
}

_yaml_keys_names_outputs_values_filter() {
	local keysNamesOutputsValues="$1"
	local keysNamesOutputsFilter="$2"

	echo "$keysNamesOutputsValues" | while read -r keyNameOutputValueLine; do
		keyNameOutput="${keyNameOutputValueLine%%=*}"
		if echo "$keysNamesOutputsFilter" | grep -Fxq -- "$keyNameOutput"; then
			echo "$keyNameOutputValueLine"
		fi
	done
}

_yaml_keys_names_outputs_values_rename() {
	local keysNamesOutputsValues="$1"
	local keysNamesOutputsRename="$2"

	echo "$keysNamesOutputsValues" | while read -r keyNameOutputValueLine; do
		keyNameOutputSearch="${keyNameOutputValueLine%%=*}"

		keyNameOutputRenameValue=$(_yaml_keys_names_outputs_values_rename_value "$keyNameOutputSearch" "$keysNamesOutputsRename")
		if [ -n "$keyNameOutputRenameValue" ]; then
			keyNameOutputValue="${keyNameOutputValueLine#*=}"
			echo "$keyNameOutputRenameValue=$keyNameOutputValue"
		else
			echo "$keyNameOutputValueLine"
		fi
	done
}

_yaml_keys_names_outputs_values_rename_value() {
	local keyNameOutputSearch="$1"
	local keysNamesOutputsRename="$2"

	echo "$keysNamesOutputsRename" | while read -r keyNameOutputRenameLine; do
		keyNameOutputRename="${keyNameOutputRenameLine%%=*}"

		if [ "$keyNameOutputRename" = "$keyNameOutputSearch" ]; then
			keyNameOutputRenameValue="${keyNameOutputRenameLine#*=}"
			echo "$keyNameOutputRenameValue"
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

_set_github_output() {
	local keyNameOutput="$1"
	local keyNameOutputValue="$2"

	keyNameOutputValueGitHubOutput=$(printf '%s' "${keyNameOutputValue}" | sed -e 's/\\n/\n/g')
	keyNameOutputValueGitHubOutputLineCount=$(echo "$keyNameOutputValueGitHubOutput" | wc -l)
	if [ "$keyNameOutputValueGitHubOutputLineCount" -gt 1 ]; then
		{
			echo "$keyNameOutput<<EOF"
			printf '%s\n' "$keyNameOutputValueGitHubOutput"
			echo "EOF"
		} >>"$GITHUB_OUTPUT"
	else
		echo "$keyNameOutput=$keyNameOutputValueGitHubOutput" >>"$GITHUB_OUTPUT"
	fi
}

_set_github_outputs() {
	local yamlFile="$1"
	local filteringKeys="$2"
	local renamingOutputs="$3"
	local dotReplacement="$4"

	keysNamesOutputsValues=$(_yaml_keys_names_outputs_values "$yamlFile" "$filteringKeys" "$renamingOutputs" "$dotReplacement")

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
