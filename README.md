# Qwen Code Action

A GitHub Action that uses Qwen Code to automate software development tasks. This action allows you to integrate AI-powered code generation and assistance directly into your CI/CD workflows.

## Features

- 🤖 AI-powered code generation and automation
- ⚙️ Customizable Qwen Code configuration
- 🔒 Secure API key management
- 📦 Flexible version control (npm, GitHub branches, specific versions)
- 📝 Configurable prompts for task-specific guidance
- 📊 Output capturing for workflow integration

## Inputs

### Required Inputs

| Input             | Description             | Required |
| ----------------- | ----------------------- | -------- |
| `OPENAI_API_KEY`  | Your Qwen Code API key  | Yes      |
| `OPENAI_BASE_URL` | Your Qwen Code base URL | Yes      |
| `OPENAI_MODEL`    | Your Qwen Code model    | Yes      |

### Optional Inputs

| Input           | Description                                                                          | Default                          |
| --------------- | ------------------------------------------------------------------------------------ | -------------------------------- |
| `prompt`        | Specific prompt to guide Qwen Code                                                   | `'You are a helpful assistant.'` |
| `settings_json` | JSON string to configure Qwen Code (written to `.qwen/settings.json`)                | -                                |
| `version`       | Version of @qwen-code/qwen-code to use (`latest`, version number, branch, or commit) | `latest`                         |

## Outputs

| Output    | Description                                    |
| --------- | ---------------------------------------------- |
| `summary` | The summarized output from Qwen Code execution |

## Usage

### Basic Example

```yaml
name: Run Qwen Code
on: [push, pull_request]

jobs:
  qwen-code:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Qwen Code
        uses: your-username/qwen-code-action@v1
        with:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
          OPENAI_BASE_URL: ${{ secrets.OPENAI_BASE_URL }}
          OPENAI_MODEL: 'qwen-code-model'
          prompt: 'Review this code and suggest improvements'
```

### Advanced Example with Configuration

```yaml
name: Advanced Qwen Code
on: [push]

jobs:
  code-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Qwen Code Analysis
        uses: your-username/qwen-code-action@v1
        id: qwen-analysis
        with:
          OPENAI_API_KEY: ${{ secrets.QWEN_API_KEY }}
          OPENAI_BASE_URL: ${{ secrets.QWEN_BASE_URL }}
          OPENAI_MODEL: 'qwen-2.5-coder'
          prompt: 'Analyze this code for security vulnerabilities and performance issues'
          settings_json: '{"max_tokens": 4000, "temperature": 0.2}'
          version: 'latest'

      - name: Use Qwen Output
        run: |
          echo "Qwen analysis completed:"
          echo "${{ steps.qwen-analysis.outputs.summary }}"
```

### Using Specific Version

```yaml
- name: Run with specific version
  uses: your-username/qwen-code-action@v1
  with:
    OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
    OPENAI_BASE_URL: ${{ secrets.OPENAI_BASE_URL }}
    OPENAI_MODEL: 'qwen-code-model'
    version: '0.1.0' # or 'main' for GitHub branch, or commit hash
```

## Secrets Setup

You need to set up the following secrets in your GitHub repository:

1. Go to your repository **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add these secrets:
   - `OPENAI_API_KEY`: Your Qwen Code API key
   - `OPENAI_BASE_URL`: Your Qwen Code base URL

## Version Options

The `version` input supports multiple formats:

- **npm version**: `'0.1.0'`, `'latest'`, `'beta'`
- **GitHub branch**: `'main'`, `'develop'`
- **Commit hash**: `'a1b2c3d'`

## Configuration

### Settings JSON

You can configure Qwen Code behavior using the `settings_json` input:

```yaml
settings_json: '{
  "max_tokens": 4000,
  "temperature": 0.7,
  "top_p": 0.9
}'
```

## Use Cases

- **Code Review**: Automatically review pull requests
- **Code Generation**: Generate code based on specifications
- **Documentation**: Generate or update documentation
- **Bug Detection**: Identify potential issues in code
- **Refactoring Suggestions**: Get AI-powered refactoring recommendations

## Branding

- **Icon**: terminal
- **Color**: blue

## License

[Add your license here]

## Support

For issues and questions:

- Create an issue in this repository
- Check the [Qwen Code documentation](https://github.com/QwenLM/qwen-code/)


**Note**: This action requires valid Qwen Code API credentials and appropriate permissions to function correctly.
