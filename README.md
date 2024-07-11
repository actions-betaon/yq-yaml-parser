# Hello, World! Docker Action

[![GitHub Super-Linter](https://github.com/actions-betaon/yq-yaml-parser/actions/workflows/linter.yml/badge.svg)](https://github.com/super-linter/super-linter)
![CI](https://github.com/actions-betaon/yq-yaml-parser/actions/workflows/ci.yml/badge.svg)

This action reads values from a YAML file, setting them into the `$GITHUB_OUTPUT` of the action.

To learn how this action was built, see [Creating a Docker container action](https://docs.github.com/en/actions/creating-actions/creating-a-docker-container-action).

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
```

## Inputs

| Input       | Description                     | Default |
| ----------- | ------------------------------- | ----------- |
| `file-path` | Path to the yaml file to parse as output | |

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
