# Best Practices

This guide provides best practices for using the Qwen Code GitHub Action, with a focus on repository security and operational excellence.

- [Best Practices](#best-practices)
  - [Repository Security](#repository-security)
    - [Branch and Tag Protection](#branch-and-tag-protection)
    - [Restrict PR Approvers](#restrict-pr-approvers)
  - [Workflow Configuration](#workflow-configuration)
    - [Use Secrets for Sensitive Data](#use-secrets-for-sensitive-data)
    - [Pin Action Versions](#pin-action-versions)
    - [Untrusted Input and Tool Approval](#untrusted-input-and-tool-approval)
  - [Creating Custom Workflows](#creating-custom-workflows)

## Repository Security

A secure repository is the foundation for any reliable and safe automation. We strongly recommend implementing the following security measures.

### Branch and Tag Protection

Protecting your branches and tags is critical to preventing unauthorized changes. You can use [repository rulesets] to configure protection for your branches and tags.

We recommend the following at a minimum for your `main` branch:

- **Require a pull request before merging**
- **Require a minimum number of approvals**
- **Dismiss stale approvals**
- **Require status checks to pass before merging**

For more information, see the GitHub documentation on [managing branch protections].

### Restrict PR Approvers

To prevent fraudulent or accidental approvals, you can restrict who can approve pull requests.

- **CODEOWNERS**: Use a [`CODEOWNERS` file] to define individuals or teams that are responsible for code in your repository.
- **Code review limits**: [Limit code review approvals] to specific users or teams.

## Workflow Configuration

### Use Secrets for Sensitive Data

Never hardcode secrets (e.g., API keys, tokens) in your workflows. Use [GitHub Secrets] to store sensitive information.

### Pin Action Versions

To ensure the stability and security of your workflows, pin the Qwen Code action to a specific version.

```yaml
uses: QwenLM/qwen-code-action@v0
```

### Untrusted Input and Tool Approval

The action's `approval_mode` input controls how tool calls are approved:

- `yolo` (the default, kept for backward compatibility) auto-approves **every** tool call, including shell commands and file writes. This is appropriate only when the entire prompt and every input the agent reads are trusted.
- `default` denies any tool call that is not read-only or explicitly allowed by `permissions.allow`. Use this mode whenever the agent processes untrusted input — issue titles and bodies, pull request diffs, comment text, or files from a fork.

An LLM agent cannot reliably distinguish instructions from data. A malicious issue body can attempt to instruct the agent to read secrets from its environment and publish them through comments, job summaries, or artifacts ("prompt injection"). Defend in depth:

- **Gate triggers by author.** Only run agent workflows automatically for `OWNER`/`MEMBER`/`COLLABORATOR` content; require an explicit maintainer command for everyone else.
- **Keep secrets out of the agent's reach.** The action routes model API calls through a per-run loopback proxy so the agent process only sees a placeholder token, and redacts the API key from uploaded artifacts. A loopback proxy is not an OS-user boundary, so the bundled review and invoke workflows use `untrusted_input: true`: the agent then runs in a private Docker network without the Docker socket, host credentials, or outbound network access. Do not pass additional secrets into the agent step's environment.
- **Minimize tools.** Give the agent only the tools it needs, prefer structured text output parsed by the caller over shell access, and never allow tools like `printenv` on untrusted paths.
- **Feed prompt context via `@{...}`, not `!{echo ...}`.** In `default` approval mode the CLI hard-denies shell tools for the whole session, and that denial also blocks `!{...}` shell injections inside custom command prompts. The action materializes the standard context variables (issue title/body, labels, repository, etc.) into `.qwen/action-context/<VAR>.md`; reference them in command TOML as `@{.qwen/action-context/<VAR>.md}`, which is read through the tool-free file injector.
- **Do not check out untrusted code into the agent workspace.** Fetch PR diffs through the GitHub API and check out the trusted base ref with `persist-credentials: false`. By default the action clears `.qwen/settings.json`, `.qwen/commands/custom`, `.qwen/skills`, `.agents/skills`, `.mcp.json`, `.env`, and `.qwenignore` so a checkout cannot supply agent configuration. Callers on a trusted workspace may opt into `preserve_workspace_config: true` to keep their existing agent configuration.
- **Pass MCP servers via `extra_args: --mcp-config <file>`, not workspace settings.** In `default` approval mode the CLI holds workspace-declared MCP servers behind an interactive approval gate that CI cannot answer; caller-supplied `--mcp-config` servers are exempt. When using `untrusted_input`, the action owns this option: its MCP sidecar restricts repository/API access, and callers must not put a token-bearing MCP config in the workspace.
- **Enforce review policy in code, not prompts.** The bundled review MCP sidecar constrains submissions to the current pull request and always changes the submitted event to `COMMENT`; it never relies on withdrawing an APPROVE after the fact. Also make sure the GitHub App used by the workflows is **not** configured as a required reviewer or in any ruleset that lets its approval satisfy branch protection — its reviews are advisory and must never gate merges.

## Creating Custom Workflows

When creating your own workflows, we recommend starting with the [examples provided in this repository](../examples/workflows/). These examples demonstrate how to use the `qwen-code-action` for various use cases, such as pull request reviews, issue triage, and more.

Ensure the new workflows you create follow the principle of least privilege. Only grant the permissions necessary to perform the required tasks.

[repository rulesets]: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
[managing branch protections]: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
[`codeowners` file]: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
[limit code review approvals]: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/managing-repository-settings/managing-pull-request-reviews-in-your-repository#enabling-code-review-limits
[github secrets]: https://docs.github.com/en/actions/security-guides/encrypted-secrets
