# Configuring Qwen Code Workflows

This guide covers how to customize and configure Qwen Code workflows to meet your specific needs.

- [Configuring Qwen Code Workflows](#configuring-qwen-code-workflows)
  - [How to Configure Qwen Code](#how-to-configure-qwen-code)
    - [Custom Commands (TOML Files)](#custom-commands-toml-files)
    - [Key Settings](#key-settings)
      - [Conversation Length (`model.maxSessionTurns`)](#conversation-length-modelmaxsessionturns)
      - [Allowlist Tools (`tools.core`)](#allowlist-tools-toolscore)
      - [MCP Servers (`mcpServers`)](#mcp-servers-mcpservers)
    - [Custom Context and Guidance (`QWEN.md`)](#custom-context-and-guidance-qwenmd)
  - [GitHub Actions Workflow Settings](#github-actions-workflow-settings)
    - [Setting Timeouts](#setting-timeouts)
    - [Required Permissions](#required-permissions)

## How to Configure Qwen Code

Qwen Code workflows are highly configurable. You can adjust their behavior by editing the corresponding `.yml` files in your repository.

Qwen Code supports many settings that control how it operates. For a complete list, see the [Qwen Code documentation](https://qwenlm.github.io/qwen-code-docs/en/users/configuration/settings/).

### Custom Commands (TOML Files)

The example workflows use custom commands defined in TOML files to provide specialized prompts for different tasks. These TOML files are automatically installed from the action's `.github/commands/` directory to `.qwen/commands/` when the workflow runs.

**Available custom commands:**

- `/qwen-invoke` - General-purpose AI assistant for code changes and analysis
- `/qwen-review` - Pull request code review
- `/qwen-triage` - Single issue triage
- `/qwen-scheduled-triage` - Batch issue triage

**How it works:**

1. The action copies TOML files from `.github/commands/` to `.qwen/commands/` during workflow execution
2. Workflows reference these commands using the `prompt` input (e.g., `prompt: '/qwen-invoke'`)
3. The Qwen Code loads the command's prompt from the TOML file

**Customizing commands:**

To customize the prompts for your repository:

1. Copy the TOML file(s) from `examples/workflows/<workflow-name>` to your repository's `.qwen/commands/` directory
2. Modify the `prompt` field in the TOML file to match your needs
3. Commit the TOML files to your repository

For example, to customize the PR review prompt:

```bash
mkdir -p .qwen/commands
cp examples/workflows/pr-review/qwen-review.toml .qwen/commands/
# Edit .qwen/commands/qwen-review.toml as needed
git add .qwen/commands/qwen-review.toml
git commit -m "feat: customize PR review prompt"
```

The workflow will use your custom TOML file instead of the default one from the action.

### Key Settings

#### Conversation Length (`model.maxSessionTurns`)

This setting controls the maximum number of conversational turns (messages exchanged) allowed during a workflow run.

**Default values by workflow:**

| Workflow                             | Default `model.maxSessionTurns` |
| ------------------------------------ | ------------------------------- |
| [Issue Triage](./issue-triage)       | 25                              |
| [Pull Request Review](./pr-review)   | 20                              |
| [Qwen Code Assistant](./qwen-assistant) | 50                              |

**How to override:**

Add the following to your workflow YAML file to set a custom value:

```yaml
with:
  settings: |-
    {
      "model": {
        "maxSessionTurns": 10
      }
    }
```

#### Allowlist Tools (`tools.core`)

Allows you to specify a list of [built-in tools] that should be made available to the model. You can also use this to allowlist commands for shell tool.

**Default:** All tools available for use by Qwen Code.

**How to configure:**

Add the following to your workflow YAML file to specify core tools:

```yaml
with:
  settings: |-
    {
      "tools": {
        "core": [
          "read_file",
          "run_shell_command(echo)",
          "run_shell_command(gh label list)"
        ]
      }
    }
```

#### MCP Servers (`mcpServers`)

Configures connections to one or more Model Context Protocol (MCP) servers for discovering and using custom tools. This allows you to extend Qwen Code GitHub Action with additional capabilities.

**Default:** Empty

**Example:**

```yaml
with:
  settings: |-
    {
      "mcpServers": {
        "github": {
          "command": "docker",
          "args": [
            "run",
            "-i",
            "--rm",
            "-e",
            "GITHUB_PERSONAL_ACCESS_TOKEN",
            "ghcr.io/github/github-mcp-server"
          ],
          "env": {
            "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
          }
        }
      }
    }
```

### Custom Context and Guidance (`QWEN.md`)

To provide Qwen Code with custom instructions—such as coding conventions, architectural patterns, or other guidance—add a `QWEN.md` file to the root of your repository. Qwen Code will use the content of this file to inform its responses.

## GitHub Actions Workflow Settings

### Setting Timeouts

You can control how long Qwen Code runs by using either the `timeout-minutes` field in your workflow YAML, or by specifying a timeout in the `settings` input.

### Required Permissions

Only users with the following roles can trigger the workflow:

- Repository Owner (`OWNER`)
- Repository Member (`MEMBER`)
- Repository Collaborator (`COLLABORATOR`)

[built-in tools]: https://github.com/QwenLM/qwen-code/blob/main/docs/core/tools-api.md#built-in-tools
