#!/bin/bash

test_name=$1
expected=$2
output=$3
sortCompare=$4

expected_result=$expected 
expected_result_lines=$(echo "$expected_result" | wc -l)

output_result=$output
output_result_lines=$(echo "$output_result" | wc -l)

if [[ "$sortCompare" == "true" ]]; then
	expected_result=$(echo "$expected_result" | sort)
	output_result=$(echo "$output_result" | sort)
fi

echo "Expected Lines: $expected_result_lines"
echo "Expected Values:"
echo "$expected_result"
echo ""
echo "Output Lines: $output_result_lines"
echo "Output Values:"
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
		echo "Expected Lines: $expected_result_count"
		echo "Expected Values:"
		echo "$expected_result_summary"
		echo ""
		echo "Output Lines: $output_result_count"
		echo "Output Values:"
		echo "$output_result_summary"
	} >>"$GITHUB_STEP_SUMMARY"

	exit 1
fi
