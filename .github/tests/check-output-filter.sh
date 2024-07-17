#!/bin/bash

test_name=$1
expected=$2
output=$3

expected_result=$(echo "$expected" | sort)
expected_result_count=$(echo "$expected_result" | wc -l)

output_result=$(echo "$output" | sort)
output_result_count=$(echo "$output_result" | wc -l)

echo "Expected Count: $expected_result_count"
echo "Expected Result:"
echo "$expected_result"
echo ""
echo "Output Count: $output_result_count"
echo "Output Result:"
echo "$output_result"
echo ""

if [[ "$output_result" == "$expected_result" ]] && [[ "$output_result_count" -eq "$expected_result_count" ]]; then
	echo "Test Passed: $test_name"
	echo "### :white_check_mark: Test Passed: $test_name" >>"$GITHUB_STEP_SUMMARY"
else
	echo "Test Failed: $test_name"
	echo "### :x: Test Failed: $test_name" >>"$GITHUB_STEP_SUMMARY"

	expected_result_summary=$(printf "%s" "${expected_result//\\/\\\\}" | sed 's/ /·/g')
	output_result_summary=$(printf "%s" "${output_result//\\/\\\\}" | sed 's/ /·/g')

	{
		echo "Expected Count: $expected_result_count"
		echo "Expected Result:"
		echo "$expected_result_summary"
		echo ""
		echo "Output Count: $output_result_count"
		echo "Output Result:"
		echo "$output_result_summary"
	} >>"$GITHUB_STEP_SUMMARY"

	exit 1
fi
