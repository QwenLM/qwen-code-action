# Authentication

This guide covers how to authenticate the Qwen Code CLI action in your GitHub Actions workflows.

- [Authentication](#authentication)
  - [Qwen Code API Authentication](#qwen-code-api-authentication)
    - [Prerequisites](#prerequisites)
    - [Setup](#setup)
    - [Example](#example)
  - [GitHub Authentication](#github-authentication)
    - [Method 1: Using the Default GITHUB_TOKEN](#method-1-using-the-default-github_token)
    - [Method 2: Using a GitHub App (Recommended)](#method-2-using-a-github-app-recommended)
  - [Additional Resources](#additional-resources)

## Qwen Code API Authentication

The Qwen Code CLI Action uses OpenAI-compatible API authentication through Alibaba Cloud's DashScope platform.

### Prerequisites

- A Qwen API key from [DashScope](https://dashscope.console.aliyun.com/).

### Setup

1. **Create an API Key**: Go to DashScope console and create a new API key.
2. **Add to GitHub Secrets**: In your GitHub repository, go to **Settings > Secrets and variables > Actions** and add a new repository secret with the name `QWEN_API_KEY` and paste your key as the value.
3. **(Optional) Configure Base URL and Model**: If you want to use a different endpoint or model, add repository variables:
    - `QWEN_BASE_URL`: Custom API endpoint (default: `https://dashscope.aliyuncs.com/compatible-mode/v1`)
    - `QWEN_MODEL`: Model name (default: `qwen-coder-plus-latest`)

### Example

```yaml
- uses: 'QwenLM/qwen-code-action@v1'
  with:
    prompt: |-
      Explain this code
    openai_api_key: '${{ secrets.QWEN_API_KEY }}'
    openai_base_url: '${{ vars.QWEN_BASE_URL }}' # Optional
    openai_model: '${{ vars.QWEN_MODEL }}' # Optional
```

## GitHub Authentication

This action requires a GitHub token to interact with the GitHub API. You can authenticate in two ways:

### Method 1: Using the Default GITHUB_TOKEN

For simpler scenarios, the action can authenticate using the default `GITHUB_TOKEN` that GitHub automatically creates for each workflow run.

**Limitations:**

- Limited permissions - you may need to grant additional permissions in your workflow file
- Job-scoped - access limited to the repository where the workflow runs

```yaml
permissions:
  contents: 'read'
  issues: 'write'
  pull-requests: 'write'
```

### Method 2: Using a GitHub App (Recommended)

For optimal security and control, create a custom GitHub App with fine-grained permissions.

1. Create a new GitHub App at Settings > Developer settings > GitHub Apps
2. Configure permissions (Contents, Issues, Pull requests: Read & write)
3. Generate a private key and note the App ID
4. Install the app in your repository
5. Add `APP_ID` (variable) and `APP_PRIVATE_KEY` (secret) to your repository

For details, see the [GitHub documentation](https://docs.github.com/en/apps/sharing-github-apps/registering-a-github-app-from-a-manifest).

## Additional Resources

- [DashScope Documentation](https://help.aliyun.com/zh/dashscope/)
- [Qwen Code CLI](https://github.com/QwenLM/qwen-code-cli)
- [GitHub Actions Security](https://docs.github.com/en/actions/security-guides)
