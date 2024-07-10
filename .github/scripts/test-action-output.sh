#!/bin/bash

test_name=$1
expected_result=$2
output_result=$3

echo "Expected Result:"
echo "$expected_result"
echo ""
echo "Output Result:"
echo "$output_result"
echo ""

if [[ "$output_result" == "$expected_result" ]]; then
	echo "Test Passed: $test_name"
	echo "### :white_check_mark: Test Passed: $test_name" >>"$GITHUB_STEP_SUMMARY"
else
	echo "Test Failed: $test_name"
	echo "### :x: Test Failed: $test_name" >>"$GITHUB_STEP_SUMMARY"

	expected_result_summary=$(printf "%s" "${expected_result//\\/\\\\}" | sed 's/ /·/g')
	output_result_summary=$(printf "%s" "${output_result//\\/\\\\}" | sed 's/ /·/g')

	{
		echo "Expected Result:"
		echo "$expected_result_summary"
		echo ""
		echo "Output Result:"
		echo "$output_result_summary"
	} >>"$GITHUB_STEP_SUMMARY"

	exit 1
fi
