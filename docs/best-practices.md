# Best Practices

This guide provides best practices for using the Qwen Code GitHub Action, with a focus on repository security and operational excellence.

- [Best Practices](#best-practices)
  - [Repository Security](#repository-security)
    - [Branch and Tag Protection](#branch-and-tag-protection)
    - [Restrict PR Approvers](#restrict-pr-approvers)
  - [Workflow Configuration](#workflow-configuration)
    - [Use Secrets for Sensitive Data](#use-secrets-for-sensitive-data)
    - [Pin Action Versions](#pin-action-versions)
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

## Creating Custom Workflows

When creating your own workflows, we recommend starting with the [examples provided in this repository](../examples/workflows/). These examples demonstrate how to use the `qwen-code-action` for various use cases, such as pull request reviews, issue triage, and more.

Ensure the new workflows you create follow the principle of least privilege. Only grant the permissions necessary to perform the required tasks.

[repository rulesets]: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
[managing branch protections]: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
[`codeowners` file]: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
[limit code review approvals]: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/managing-repository-settings/managing-pull-request-reviews-in-your-repository#enabling-code-review-limits
[github secrets]: https://docs.github.com/en/actions/security-guides/encrypted-secrets
