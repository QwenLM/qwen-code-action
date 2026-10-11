"""Exercise the action's shell step with multiline CLI output."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ACTION = Path(__file__).resolve().parents[1] / "action.yml"


def run_step():
    lines = ACTION.read_text(encoding="utf-8").splitlines()
    start = lines.index("    - name: 'Run Qwen Code'")
    script_start = lines.index("      run: |-", start) + 1
    script_end = lines.index("      env:", script_start)
    return "\n".join(line[8:] for line in lines[script_start:script_end]) + "\n"


def read_outputs(path):
    """Parse the multiline GITHUB_OUTPUT format used by the Actions runner."""
    lines = path.read_bytes().decode("utf-8").split("\n")
    if lines[-1] == "":
        lines.pop()
    outputs = {}
    index = 0
    while index < len(lines):
        header = lines[index]
        if "<<" not in header:
            raise ValueError(f"Invalid output command: {header!r}")
        name, delimiter = header.split("<<", 1)
        index += 1
        content = []
        while index < len(lines) and lines[index] != delimiter:
            content.append(lines[index])
            index += 1
        if index == len(lines):
            raise ValueError(f"Missing output delimiter: {delimiter!r}")
        outputs[name] = "\n".join(content)
        index += 1
    return outputs


class OutputDelimiterTest(unittest.TestCase):
    def test_response_and_error_lines_can_equal_eof(self):
        self.assertIsNotNone(shutil.which("bash"))
        self.assertIsNotNone(shutil.which("jq"))

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            binary = root / "bin"
            binary.mkdir()
            qwen = binary / "qwen"
            qwen.write_text(
                "#!/usr/bin/env python3\n"
                "import json, os, sys\n"
                "text = os.environ['QWEN_TEST_RESPONSE']\n"
                "raw = os.environ.get('QWEN_TEST_RAW_STDOUT')\n"
                "if raw is None:\n"
                "    print(json.dumps([{'type': 'assistant', 'message': "
                "{'content': [{'type': 'text', 'text': text}]}}, "
                "{'type': 'result', 'result': text}]))\n"
                "else:\n"
                "    sys.stdout.write(raw)\n"
                "sys.stderr.write(os.environ['QWEN_TEST_STDERR'])\n",
                encoding="utf-8",
            )
            qwen.chmod(0o755)

            for response, stderr, raw_stdout in (
                ("A\nMORE\nB", "", None),
                ("A\nEOF\nB", "", None),
                ("A\nEOF\nEOF_\nB", "", None),
                ("A\r\nEOF\r\nB", "", None),
                ("A", "warning without newline", None),
                ("A", "note\nEOF\nother", None),
                ("A", "", "raw output\n\n"),
                ("A", "", "raw output without newline"),
            ):
                with self.subTest(response=response, stderr=stderr, raw_stdout=raw_stdout):
                    output = root / "github-output"
                    output.write_text("", encoding="utf-8")
                    env = os.environ.copy()
                    env.update(
                        PATH=f"{binary}:{env['PATH']}",
                        RUNNER_TEMP=directory,
                        GITHUB_OUTPUT=str(output),
                        QWEN_TEST_RESPONSE=response,
                        QWEN_TEST_STDERR=stderr,
                        DEBUG="false",
                        PROMPT="test",
                    )
                    if raw_stdout is not None:
                        env["QWEN_TEST_RAW_STDOUT"] = raw_stdout
                    result = subprocess.run(
                        ["bash", "-c", run_step()],
                        cwd=directory,
                        env=env,
                        text=True,
                        capture_output=True,
                        check=False,
                    )
                    self.assertEqual(result.returncode, 0, result.stderr)
                    fields = read_outputs(output)
                    self.assertEqual(
                        fields["qwen_response"],
                        raw_stdout if raw_stdout is not None else response,
                    )
                    self.assertEqual(fields["qwen_errors"], stderr)


if __name__ == "__main__":
    unittest.main()
