#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

WORKFLOWS_DIR="${REPO_ROOT}/.github/workflows"
COMMANDS_DIR="${REPO_ROOT}/.github/commands"
EXAMPLES_DIR="${REPO_ROOT}/examples/workflows"

# Generate workflow YAML files
for workflow_file in "${WORKFLOWS_DIR}"/*.yml; do
  workflow_name="$(basename "${workflow_file}")"
  example_dir=""
  example_filename=""

  # Add case for each file that should exist in /examples/
  case "${workflow_name}" in
    "qwen-invoke.yml")
      example_dir="${EXAMPLES_DIR}/qwen-assistant"
      example_filename="qwen-invoke.yml"
      ;; 
    "qwen-triage.yml")
      example_dir="${EXAMPLES_DIR}/issue-triage"
      example_filename="qwen-triage.yml"
      ;; 
    "qwen-scheduled-triage.yml")
      example_dir="${EXAMPLES_DIR}/issue-triage"
      example_filename="qwen-scheduled-triage.yml"
      ;; 
    "qwen-review.yml")
      example_dir="${EXAMPLES_DIR}/pr-review"
      example_filename="qwen-review.yml"
      ;; 
    *)
      echo "Skipping ${workflow_name}"
      continue
      ;; 
  esac

  example_file="${example_dir}/${example_filename}"
  echo "Generating ${example_file}"

  # Update lines that are different in the /examples/, such as the version of the action
  sed \
    -e "s|uses: 'QwenLM/qwen-code-action@main'|uses: 'QwenLM/qwen-code-action@v1'|g" \
    "${workflow_file}" > "${example_file}"
done

# Copy TOML command files to examples directories
echo ""
echo "Copying TOML command files..."

for toml_file in "${COMMANDS_DIR}"/*.toml; do
  toml_name="$(basename "${toml_file}")"
  example_dir=""

  # Map each TOML file to its example directory
  case "${toml_name}" in
    "qwen-invoke.toml")
      example_dir="${EXAMPLES_DIR}/qwen-assistant"
      ;;
    "qwen-triage.toml")
      example_dir="${EXAMPLES_DIR}/issue-triage"
      ;;
    "qwen-scheduled-triage.toml")
      example_dir="${EXAMPLES_DIR}/issue-triage"
      ;;
    "qwen-review.toml")
      example_dir="${EXAMPLES_DIR}/pr-review"
      ;;
    "qwen-issue-fixer.toml")
      # Skip this one as it's not part of the standard examples yet
      echo "Skipping ${toml_name} (no example directory)"
      continue
      ;;
    *)
      echo "Skipping ${toml_name}"
      continue
      ;;
  esac

  example_toml="${example_dir}/${toml_name}"
  echo "Copying ${toml_name} to ${example_dir}"
  cp "${toml_file}" "${example_toml}"
done

echo ""
echo "Done! All workflow and command files generated."
