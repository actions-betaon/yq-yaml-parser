# YAML parser action

[![GitHub Super-Linter](https://github.com/actions-betaon/yq-yaml-parser/actions/workflows/linter.yml/badge.svg)](https://github.com/super-linter/super-linter)
![CI Docker](https://github.com/actions-betaon/yq-yaml-parser/actions/workflows/ci-docker.yml/badge.svg)
![CI Test](https://github.com/actions-betaon/yq-yaml-parser/actions/workflows/ci-test.yml/badge.svg)

This action reads values from a YAML file setting as action outputs.

## Usage

Here's an example of how to use this action in a workflow file:

```yaml
name: Example Workflow

on:
  workflow_dispatch:
    inputs:
      yaml-file-path:
        description: "Path to the yaml file to parser"
        required: true
        type: string
      yaml-filtering-keys:
        description: "Read using specific keys"
        required: false
        type: string
      yaml-renaming-outputs:
        description: "Used to rename the default output name"
        required: false
        type: string        

jobs:
  yq-yaml-parser:
    name: Yq yaml parser
    runs-on: ubuntu-latest

    steps:      
      - name: Yaml to outputs
        id: yaml-to-outputs
        uses: actions-betaon/yq-yaml-parser@v1.0.0
        with:
          file-path: '${{ inputs.yaml-file-path }}'
          filtering-keys: '${{ inputs.yaml-filtering-keys }}'
          renaming-outputs: '${{ inputs.yaml-renaming-outputs }}'
```

## Inputs

| Input       | Description                     | Required |
| ----------- | ------------------------------- | ----------- |
| `file-path` | Path to the YAML file to parse as output | true |
| `filtering-keys` | The YAML key names list to filter as read | false |
| `renaming-outputs` | The YAML rename "keyname=output" output list | false |

## Outputs

### Given

```yaml
sample:  
  key-1: value 1
  key-2: |
    value 2 with
    2 lines
  key-3:
    - nested value 1
    - nested value 2
```

### Output as

```text
sample_key-1=value 1
sample_key-2<<EOF 
value 2 with
2 lines
EOF
sample_key-3_0=nested value 1
sample_key-3_1=nested value 2
```
