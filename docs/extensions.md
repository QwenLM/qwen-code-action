# Extensions

Qwen Code can be extended with additional functionality through extensions.
These extensions are installed from source from their GitHub repositories.

For more information on creating and using extensions, see [documentation].

[documentation]: https://github.com/QwenLM/qwen-code/blob/main/docs/extensions/extension.md

## Configuration

To use extensions in your GitHub workflow, provide a JSON array of GitHub
repositories to the `extensions` input of the `qwen-code-action` action.

### Example

Here is an example of how to configure a workflow to install and use extensions:

```yaml
jobs:
  main:
    runs-on: ubuntu-latest
    steps:
      - id: qwen
        uses: QwenLM/qwen-code-action@v1
        with:
          openai_api_key: ${{ secrets.QWEN_API_KEY }}
          prompt: "/security:analyze"
          extensions: |
            [
              "https://github.com/qwen-cli-extensions/security",
              "https://github.com/qwen-cli-extensions/code-review"
            ]
```
