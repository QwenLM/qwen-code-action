# PR Review with Qwen Code

This document explains how to use the Qwen Code on GitHub to automatically review pull requests with AI-powered code analysis.

- [PR Review with Qwen Code](#pr-review-with-qwen-code)
  - [Overview](#overview)
  - [Features](#features)
  - [Setup](#setup)
    - [Prerequisites](#prerequisites)
    - [Setup Methods](#setup-methods)
  - [Dependencies](#dependencies)
  - [Usage](#usage)
    - [Supported Triggers](#supported-triggers)
  - [Interaction Flow](#interaction-flow)
    - [Automatic Reviews](#automatic-reviews)
    - [Manual Reviews](#manual-reviews)
    - [Custom Review Instructions](#custom-review-instructions)
    - [Manual Workflow Dispatch](#manual-workflow-dispatch)
  - [Review Output Format](#review-output-format)
    - [📋 Review Summary (Overall Comment)](#-review-summary-overall-comment)
    - [Specific Feedback (Inline Comments)](#specific-feedback-inline-comments)
  - [Review Areas](#review-areas)
  - [Configuration](#configuration)
    - [Workflow Customization](#workflow-customization)
    - [Review Prompt Customization](#review-prompt-customization)
  - [Examples](#examples)
    - [Basic Review Request](#basic-review-request)
    - [Security-Focused Review](#security-focused-review)
    - [Performance Review](#performance-review)
    - [Breaking Changes Check](#breaking-changes-check)
  - [Extending to Support Forks](#extending-to-support-forks)
    - [Using `pull_request_target` Event](#using-pull_request_target-event)

## Overview

The PR Review workflow uses Qwen AI to provide comprehensive code reviews for pull requests. It analyzes code quality, security, performance, and maintainability while providing constructive feedback in a structured format.

## Features

- **Automated PR Reviews**: Triggered on PR creation, updates, or manual requests
- **Comprehensive Analysis**: Covers security, performance, reliability, maintainability, and functionality
- **Priority-based Feedback**: Issues categorized by severity (Critical, High, Medium, Low)
- **Positive Highlights**: Acknowledges good practices and well-written code
- **Custom Instructions**: Support for specific review focus areas
- **Structured Output**: Consistent markdown format for easy reading
- **Failure Notifications**: Posts a comment on the PR if the review process fails.

## Setup

For detailed setup instructions, including prerequisites and authentication, please refer to the main [Getting Started](../../../README.md#quick-start) section and [Authentication documentation](../../../docs/authentication.md).

### Prerequisites

Add the following entries to your `.gitignore` file to prevent PR review artifacts from being committed:

```gitignore
# qwen code settings
.qwen/

# GitHub App credentials
gha-creds-*.json
```

### Setup Methods

To use this workflow, you can use either of the following methods:

1. Run the `/setup-github` command in Qwen Code on your terminal to set up workflows for your repository.
2. Copy the workflow files into your repository's `.github/workflows` directory:

```bash
mkdir -p .github/workflows
curl -o .github/workflows/qwen-dispatch.yml https://raw.githubusercontent.com/QwenLM/qwen-code-action/main/examples/workflows/qwen-dispatch/qwen-dispatch.yml
curl -o .github/workflows/qwen-review.yml https://raw.githubusercontent.com/QwenLM/qwen-code-action/main/examples/workflows/pr-review/qwen-review.yml
```

> **Note:** The `qwen-dispatch.yml` workflow is designed to call multiple
> workflows. If you are only setting up `qwen-review.yml`, you should comment out or
> remove the other jobs in your copy of `qwen-dispatch.yml`.

## Dependencies

This workflow relies on the [qwen-dispatch.yml](../qwen-dispatch/qwen-dispatch.yml) workflow to route requests to the appropriate workflow.

## Usage

### Supported Triggers

The Qwen PR Review workflow is triggered by:

- **New PRs**: When a pull request is opened or reopened
- **PR Review Comments**: When a review comment contains `@qwencoder /review`
- **PR Reviews**: When a review body contains `@qwencoder /review`
- **Issue Comments**: When a comment on a PR contains `@qwencoder /review`
- **Manual Dispatch**: Via the GitHub Actions UI ("Run workflow")

## Interaction Flow

The workflow follows a clear, multi-step process to handle review requests:

```mermaid
flowchart TD
    subgraph Triggers
        A[PR Opened]
        B[PR Review Comment with '@qwencoder /review']
        C[PR Review with '@qwencoder /review']
        D[Issue Comment with '@qwencoder /review']
        E[Manual Dispatch via Actions UI]
    end

    subgraph "Qwen Code Workflow"
        F[Generate GitHub App Token]
        G[Checkout PR Code]
        H[Get PR Details & Changed Files]
        I[Run Qwen PR Review Analysis]
        J[Post Review to PR]
    end

    A --> F
    B --> F
    C --> F
    D --> F
    E --> F
    F --> G
    G --> H
    H --> I
    I --> J
```

### Automatic Reviews

The workflow automatically triggers on:

- **New PRs**: When a pull request is opened

### Manual Reviews

Trigger a review manually by commenting on a PR:

```
@qwencoder /review
```

### Custom Review Instructions

You can provide specific focus areas by adding instructions after the trigger:

```
@qwencoder /review focus on security
@qwencoder /review check performance and memory usage  
@qwencoder /review please review error handling
@qwencoder /review look for breaking changes
```

### Manual Workflow Dispatch

You can also trigger reviews through the GitHub Actions UI:

1. Go to Actions tab in your repository
2. Select "Qwen PR Review" workflow
3. Click "Run workflow"
4. Enter the PR number to review

## Review Output Format

The AI review follows a structured format, providing both a high-level summary and detailed inline feedback.

### 📋 Review Summary (Overall Comment)

After posting all inline comments, the action submits the review with a final summary comment that includes:

- **Review Summary**: A brief 2-3 sentence overview of the pull request and the overall assessment.
- **General Feedback**: High-level observations about code quality, architectural patterns, positive implementation aspects, or recurring themes that were not addressed in inline comments.

### Specific Feedback (Inline Comments)

The action provides specific, actionable feedback directly on the relevant lines of code in the pull request. Each comment includes:

- **Priority**: An emoji indicating the severity of the feedback.
  - 🔴 **Critical**: Must be fixed before merging (e.g., security vulnerabilities, breaking changes).
  - 🟠 **High**: Should be addressed (e.g., performance issues, design flaws).
  - 🟡 **Medium**: Recommended improvements (e.g., code quality, style).
  - 🟢 **Low**: Nice-to-have suggestions (e.g., documentation, minor refactoring).
  - 🔵 **Unclear**: Priority is not determined.
- **Suggestion**: A code block with a suggested change, where applicable.

**Example Inline Comment:**

> 🟢 Use camelCase for function names
>
> ```suggestion
> myFunction
> ```

## Review Areas

Qwen Code analyzes multiple dimensions of code quality:

- **Security**: Authentication, authorization, input validation, data sanitization
- **Performance**: Algorithms, database queries, caching, resource usage
- **Reliability**: Error handling, logging, testing coverage, edge cases
- **Maintainability**: Code structure, documentation, naming conventions
- **Functionality**: Logic correctness, requirements fulfillment

## Configuration

### Workflow Customization

You can customize the workflow by modifying:

- **Timeout**: Adjust `timeout-minutes` for longer reviews
- **Triggers**: Modify when the workflow runs
- **Permissions**: Adjust who can trigger manual reviews
- **Core Tools**: Add or remove available shell commands

### Review Prompt Customization

The review prompt is defined in the `qwen-review.toml` file. The action automatically copies this file from `.github/commands/` to `.qwen/commands/` during execution.

**To customize the review prompt:**

1. Copy the TOML file to your repository:

   ```bash
   mkdir -p .qwen/commands
   curl -o .qwen/commands/qwen-review.toml https://raw.githubusercontent.com/QwenLM/qwen-code-action/main/examples/workflows/pr-review/qwen-review.toml
   ```

2. Edit `.qwen/commands/qwen-review.toml` to customize:
   - Focus on specific technologies or frameworks
   - Emphasize particular coding standards
   - Include project-specific guidelines
   - Adjust review depth and focus areas

3. Commit the file to your repository:

   ```bash
   git add .qwen/commands/qwen-review.toml
   git commit -m "feat: customize PR review prompt"
   ```

The workflow will use your custom TOML file instead of the default one from the action.

For more details on workflow configuration, see the [Configuration Guide](../CONFIGURATION.md#custom-commands-toml-files).

## Examples

### Basic Review Request

```
@qwencoder /review
```

### Security-Focused Review

```
@qwencoder /review focus on security vulnerabilities and authentication
```

### Performance Review

```
@qwencoder /review check for performance issues and optimization opportunities
```

### Breaking Changes Check

```
@qwencoder /review look for potential breaking changes and API compatibility
```

## Extending to Support Forks

By default, this workflow is configured to work with pull requests from branches
within the same repository, and does not allow the `pr-review` workflow to be
triggered for pull requests from branches from forks. This is done because forks
can be created from bad actors, and enabling this workflow to run on branches
from forks could enable bad actors to access secrets.

This behavior may not be ideal for all use cases - such as private repositories.
To enable the `pr-review` workflow to run on branches in forks, there are several
approaches depending on your authentication setup and security requirements.
Please refer to the GitHub documentation links provided below for
the security and access considerations of doing so.

Depending on your security requirements and use case, you can use the following
approach:

#### Using `pull_request_target` Event

This could work for private repositories where you want to provide API access
centrally.

**Important Security Note**: Using `pull_request_target` can introduce security
vulnerabilities if not handled with extreme care. Because it runs in the context
of the base repository, it has access to secrets and other sensitive data.
Always ensure you are following security best practices, such as those outlined
in the linked resources, to prevent unauthorized access or code execution.

- **Resources**:
  - [GitHub Docs: Using pull_request_target](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#pull_request_target).
  - [Security Best Practices for pull_request_target](https://securitylab.github.com/research/github-actions-preventing-pwn-requests/).
  - [Safe Workflows for Forked Repositories](https://github.blog/2020-08-03-github-actions-improvements-for-fork-and-pull-request-workflows/).
