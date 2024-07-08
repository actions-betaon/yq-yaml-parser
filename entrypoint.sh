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


_escape_backslashes() {
  local input="$1"
  
  lineMark="#LN#"
  slashMark="#SL#"
  
  output=$(echo "$input" | sed "s/\\\\n/$lineMark/g")
  output=$(echo "$output" | sed "s/\\\\/$slashMark/g")   
  output=$(echo "$output" | sed "s/$slashMark/\\\\\\\\/g") 
  output=$(echo "$output" | sed "s/$lineMark/\\\\n/g")
  echo "$output"
}

_escape_backslashes_old() {
  local input="$1"  
  distinct_words=$(echo "$input" | awk '{ for (i=1; i<=NF; i++) words[$i] } END { for (w in words) print w }')
    
  while IFS= read -r word; do
    savedWord="$word"  
    wordLfMarked=$(echo "$word" | sed "s/\\\\n/"#LF#"/g")
    wordLfSlashMarked=$(echo "$wordLfMarked" | sed "s/\\\\/"#SL#"/g")	
    if [[ "$wordLfSlashMarked" == *"#SL##LF#"* ]]; then
      newWord=$(echo "$wordLfSlashMarked" | sed "s/"#SL#"/"#SL##SL#"/g") 
      newWord=$(echo "$newWord" | sed "s/"#SL#"/\\\\/g") 
      newWord=$(echo "$newWord" | sed "s/"#LF#"/\\\\n/g") 
      savedWord="$word"
      savedWordLineMarked=${savedWord//\\n/#LN#}
      savedWordLineMarkedEscaped=${wordLineMarked//\\/\\\\}
      replaceWord=${savedWord//\\/\\\\}	  
      input=${input//"$word"/"$newWord"}
	  #echo "$input"
    fi
  done < <(echo "$distinct_words")
  
  echo "$input"
}

_escape_backslashes_when_line_followed() {
  local input="$1"
  local totalWords=$(echo $input | wc -w)
  local count=0

  for word in $input; do
    count=$((count + 1))

    if [[ "$word" == *'\\\n'* ]]; then
      wordLineMarked=${word//\\n/#LN#}
      wordLineMarkedEscaped=${wordLineMarked//\\/\\\\}
	    echo -n "${wordLineMarkedEscaped//#LN#/\\n}"
    else      
      echo -n "$word"
    fi

    if [[ $count -lt $totalWords ]]; then
      echo -n " "
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
     #propertyValue="${propertyLine#*=}"
     echo "$propertyLine"     
     echo "$propertyValue"
    _set_github_output "$propertyName" "$propertyValue"
  done
}

set -e


 printf "%b\n" "E:\\\n*"
 printf "%b\n" "E:\\\\n*"
 printf "%b\n" "E:\\\\\n*"
 printf "%b\n" "E:\\\\\\n*"
 printf "%b\n" "E:\\\\\\\n*"
 printf "%b\n" "E:\\\\\\\\n*"
 printf "%b\n" "E:\\\\\\\\\n*"

_propertyNameDotReplace="_"
_yqProperties=$(_yaml_to_properties "$INPUT_YAML_FILE_PATH")

_set_github_outputs "$_yqProperties" "$_propertyNameDotReplace"

# Use workflow commands to do things like set debug messages
#echo "::notice file=entrypoint.sh,line=59::$_properties"

# Write outputs to the $GITHUB_OUTPUT file
echo "time=$(date)" >>"$GITHUB_OUTPUT"

exit 0
