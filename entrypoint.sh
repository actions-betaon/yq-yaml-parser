#!/bin/ash -l
# shellcheck shell=dash

_boolean_eval() {
	local boolean="$1"
	if [ "$boolean" = true ]; then
		echo true
	else
		echo false
	fi
}

_boolean_invert() {
	local boolean=$(_boolean_eval "$1")
	if [ "$boolean" = true ]; then
		echo false
	else
		echo true
	fi
}

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
_yaml_keys_names_outputs_values_filter_grep() {
	local keysNamesOutputsValues="$1"
	local keysNamesOutputsFilter="$2"

	echo "$keysNamesOutputsValues" | while IFS= read -r keyNameOutputValueLine; do
		keyNameOutput="${keyNameOutputValueLine%%=*}"
		echo "$keysNamesOutputsFilter" | while IFS= read -r regex; do
			if echo "$keyNameOutput" | grep -Eq -- "$regex"; then
				echo "$keyNameOutputValueLine"
				break 2
			fi
		done
	done
}

_yaml_keys_names_outputs_values_filter_wk() {
	local keysNamesOutputsValues="$1"
	local keysNamesOutputsFilter="$2"

	echo "$keysNamesOutputsValues" | while read -r keyNameOutputValueLine; do
		keyNameOutput="${keyNameOutputValueLine%%=*}"
		if echo "$keysNamesOutputsFilter" | grep -Fxq -- "$keyNameOutput"; then
			echo "$keyNameOutputValueLine"
		fi
	done
}

_yaml_keys_names_outputs_values_filter() {
	local keysNamesOutputsValues="$1"
	local keysNamesOutputsFilter="$2"

	keysNamesOutputsFilterInclude=$(echo "$keysNamesOutputsFilter" | grep -v '^[!+\-]' | grep '^.')
	keysNamesOutputsFilterExclude=$(echo "$keysNamesOutputsFilter" | grep '^!' | cut -d'!' -f2 | grep '^.')
	keysNamesOutputsFilterRegexInclude=$(echo "$keysNamesOutputsFilter" | grep '^+' | cut -d'+' -f2 | grep '^.')
	keysNamesOutputsFilterRegexExclude=$(echo "$keysNamesOutputsFilter" | grep '^-' | cut -d'-' -f2 | grep '^.')

	keysNamesOutputsValuesFiltered="$keysNamesOutputsValues"

	if [ -n "$keysNamesOutputsFilterInclude" ]; then
		keysNamesOutputsValuesFiltered=$(_yaml_keys_names_outputs_values_filter_apply "$keysNamesOutputsValues" "$keysNamesOutputsFilterInclude" false)
	fi

	if [ -n "$keysNamesOutputsFilterExclude" ]; then
		keysNamesOutputsValuesFiltered=$(_yaml_keys_names_outputs_values_filter_apply "$keysNamesOutputsValues" "$keysNamesOutputsFilterExclude" true)
	fi

	if [ -n "$keysNamesOutputsFilterRegexInclude" ]; then
		keysNamesOutputsValuesFiltered=$(_yaml_keys_names_outputs_values_filter_apply_regex "$keysNamesOutputsValues" "$keysNamesOutputsFilterRegexInclude" false)
	fi

	if [ -n "$keysNamesOutputsFilterRegexExclude" ]; then
		keysNamesOutputsValuesFiltered=$(_yaml_keys_names_outputs_values_filter_apply_regex "$keysNamesOutputsValues" "$keysNamesOutputsFilterRegexExclude" true)
	fi

	echo "$keysNamesOutputsValuesFiltered"
}

_yaml_keys_names_outputs_values_filter_apply() {
	local keysNamesOutputsValues="$1"
	local keysNamesOutputsFilterValues="$2"
	local keysNamesOutputsFilterExclude="$3"

	while IFS= read -r keyNameOutputValueLine; do
		keyNameOutput="${keyNameOutputValueLine%%=*}"

		applyToResult="$keysNamesOutputsFilterExclude"
		if echo "$keysNamesOutputsFilterValues" | grep -Fxq -- "$keyNameOutput"; then
			applyToResult=$(_boolean_invert "$applyToResult")
		fi

		if [ "$applyToResult" = true ]; then
			echo "$keyNameOutputValueLine"
		fi
	done < <(echo "$keysNamesOutputsValues")
}

_yaml_keys_names_outputs_values_filter_apply_regex() {
	local keysNamesOutputsValues="$1"
	local keysNamesOutputsFilterRegexValues="$2"
	local keysNamesOutputsFilterRegexExclude="$3"

	while IFS= read -r keyNameOutputValueLine; do
		keyNameOutput="${keyNameOutputValueLine%%=*}"

		applyToResult="$keysNamesOutputsFilterRegexExclude"
		while IFS= read -r regex; do

			if echo "$keyNameOutput" | grep -Eq "$regex"; then
				applyToResult=$(_boolean_invert "$applyToResult")
				break
			fi

		done < <(echo "$keysNamesOutputsFilterRegexValues")

		if [ "$applyToResult" = true ]; then
			echo "$keyNameOutputValueLine"
		fi
	done < <(echo "$keysNamesOutputsValues")
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
