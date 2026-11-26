#!/usr/bin/env bash
set -euo pipefail

[ "${UNTRUSTED_INPUT:-false}" = true ] || { echo 'Isolated mode is not enabled.' >&2; exit 1; }
case "${GH_WORKFLOW_NAME:-}" in qwen-review|qwen-invoke) ;; *) echo 'Only review and invoke support untrusted_input.' >&2; exit 1 ;; esac
[ "${APPROVAL_MODE}" = default ] || { echo 'Isolated mode requires default approval.' >&2; exit 1; }
[ -z "${EXTRA_ARGS:-}" ] || { echo 'Isolated mode owns its MCP configuration.' >&2; exit 1; }
[ -n "${OPENAI_API_KEY:-}" ] && [ -n "${GITHUB_TOKEN:-}" ] || { echo 'Both model and GitHub credentials are required.' >&2; exit 1; }
[[ "${ISSUE_NUMBER:-}" =~ ^[0-9]+$ ]] || { echo 'Invalid issue or pull request number.' >&2; exit 1; }
NODE_IMAGE="node:22-bookworm-slim@sha256:4b150b48b4116e2a22f2c39cc27025fbf4f153e2078fd3b14d159fdb5c7279da"
MCP_IMAGE="ghcr.io/github/github-mcp-server@sha256:6aa543f565bc98d96106fdd80a0abdc0c7147c8ca7f4663a814ceecef1ccc6d3"

cli_path="$(realpath "$(command -v qwen)")"
package_dir="$(dirname "${cli_path}")"
while [ ! -f "${package_dir}/package.json" ]; do
  [ "${package_dir}" != / ] || { echo 'Cannot locate the Qwen package.' >&2; exit 1; }
  package_dir="$(dirname "${package_dir}")"
done
cli_entry="/opt/qwen/${cli_path#"${package_dir}/"}"
docker pull "${NODE_IMAGE}" >/dev/null
docker pull "${MCP_IMAGE}" >/dev/null
SUFFIX="${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}-$$"
PRIVATE_NETWORK="qwen-private-${SUFFIX}"
UPSTREAM_NETWORK="qwen-upstream-${SUFFIX}"
MODEL="qwen-model-${SUFFIX}"
GATEWAY="qwen-gateway-${SUFFIX}"
AGENT="qwen-agent-${SUFFIX}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME="$(mktemp -d "${RUNNER_TEMP}/qwen-isolation.XXXXXXXXXX")"
chmod 700 "${RUNTIME}"
MCP_SCRIPT="${RUNTIME}/isolated-mcp.cjs"
MODEL_SCRIPT="${RUNTIME}/isolated-model.cjs"
GATEWAY_TOKEN="$(od -An -N32 -tx1 /dev/urandom | tr -d ' \n')"
cp "${ROOT}/scripts/isolated-github-mcp.cjs" "${MCP_SCRIPT}"
cp "${ROOT}/scripts/isolated-model-proxy.cjs" "${MODEL_SCRIPT}"
BASE_SHA="$(git -C "${GITHUB_WORKSPACE}" rev-parse HEAD)"
TEMP_STDOUT="$(mktemp -p "${RUNTIME}" qwen-out.XXXXXXXXXX)"
TEMP_STDERR="$(mktemp -p "${RUNTIME}" qwen-err.XXXXXXXXXX)"
FAILED=false
cleanup() {
  docker rm -f "${AGENT}" "${GATEWAY}" "${MODEL}" >/dev/null 2>&1 || true
  docker network rm "${PRIVATE_NETWORK}" "${UPSTREAM_NETWORK}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker network create --internal "${PRIVATE_NETWORK}" >/dev/null
docker network create "${UPSTREAM_NETWORK}" >/dev/null

# The agent shares no network namespace, Docker socket, or host process with
# credential holders. Only the sidecars can reach the outbound network.
docker create --name "${MODEL}" --network "${PRIVATE_NETWORK}" --network-alias model \
  --env UPSTREAM_API_KEY="${OPENAI_API_KEY}" --env UPSTREAM_BASE_URL="${OPENAI_BASE_URL}" \
  --env PROXY_TOKEN=isolated-placeholder \
  --entrypoint node "${NODE_IMAGE}" /model.cjs >/dev/null
docker cp "${MODEL_SCRIPT}" "${MODEL}:/model.cjs"
docker start "${MODEL}" >/dev/null
docker network connect "${UPSTREAM_NETWORK}" "${MODEL}"

docker build \
  -t "qwen-action-mcp:${SUFFIX}" -f - "${ROOT}/scripts/" <<'DOCKERFILE'
FROM ghcr.io/github/github-mcp-server@sha256:6aa543f565bc98d96106fdd80a0abdc0c7147c8ca7f4663a814ceecef1ccc6d3 AS mcp
FROM node:22-bookworm-slim@sha256:4b150b48b4116e2a22f2c39cc27025fbf4f153e2078fd3b14d159fdb5c7279da
WORKDIR /qwen-sidecar
COPY --from=mcp /server/github-mcp-server /server/github-mcp-server
ADD https://registry.npmjs.org/@modelcontextprotocol/sdk/-/sdk-1.26.0.tgz /tmp/sdk.tgz
RUN echo "6394663e7729883b535c36cb2acc082734eabb687204ac5336c80aa8a7250db848820d7082d7f57d1bafc604e745f727c6dbef81b20472a50ecd9ac9ea24917a /tmp/sdk.tgz" | sha512sum -c - && npm install --ignore-scripts --no-audit --no-fund /tmp/sdk.tgz
COPY isolated-github-mcp.cjs /qwen-sidecar/gateway.cjs
ENTRYPOINT ["node", "/qwen-sidecar/gateway.cjs"]
DOCKERFILE

docker create --name "${GATEWAY}" --network "${PRIVATE_NETWORK}" --network-alias gateway \
  --env GITHUB_TOKEN="${GITHUB_TOKEN}" --env GITHUB_MCP_BIN=/server/github-mcp-server --env GATEWAY_TOKEN="${GATEWAY_TOKEN}" \
  --env GITHUB_REPOSITORY --env REVIEW_ONLY --env ISSUE_NUMBER --env BASE_SHA="${BASE_SHA}" \
  "qwen-action-mcp:${SUFFIX}" >/dev/null
docker cp "${MCP_SCRIPT}" "${GATEWAY}:/qwen-sidecar/gateway.cjs"
docker start "${GATEWAY}" >/dev/null
docker network connect "${UPSTREAM_NETWORK}" "${GATEWAY}"

for ((attempt = 0; attempt < 30; attempt += 1)); do
  [[ "$(docker logs "${GATEWAY}" 2>&1)" == *'GitHub MCP Server running on stdio'* ]] && break
  sleep 1
done
for service in "${MODEL}" "${GATEWAY}"; do
  state="$(docker inspect "${service}" --format '{{.State.Status}}')"
  [ "${state}" = running ] || { docker logs "${service}" >&2; echo "${service} failed to start." >&2; exit 1; }
done

mkdir -p "${RUNTIME}/mcp"
MCP_CONFIG="$(printf '{"mcpServers":{"github":{"httpUrl":"http://gateway:8080/mcp","headers":{"Authorization":"Bearer %s"}}}}' "${GATEWAY_TOKEN}")"
docker build -t "qwen-action-agent:${SUFFIX}" -f - "${package_dir}" <<'DOCKERFILE'
FROM node:22-bookworm-slim@sha256:4b150b48b4116e2a22f2c39cc27025fbf4f153e2078fd3b14d159fdb5c7279da
COPY . /opt/qwen
ENTRYPOINT ["node"]
DOCKERFILE

docker run --name "${AGENT}" --network "${PRIVATE_NETWORK}" \
  --user "$(id -u):$(id -g)" --cap-drop ALL --security-opt no-new-privileges --pids-limit 512 \
  --read-only --tmpfs /tmp:rw,exec,nosuid,size=512m \
  --volume "${GITHUB_WORKSPACE}:${GITHUB_WORKSPACE}" --workdir "${GITHUB_WORKSPACE}" \
  --volume "${RUNTIME}/mcp:/tmp/mcp:ro" \
  --env HOME=/tmp --env OPENAI_AUTH_TYPE=openai \
  --env QWEN_TELEMETRY_ENABLED=false --env ENABLE_WEB_SEARCH=false \
  --env OPENAI_API_KEY=isolated-placeholder --env OPENAI_BASE_URL=http://model:8080/v1 \
  --env OPENAI_MODEL --env GITHUB_REPOSITORY --env GITHUB_WORKSPACE \
  --env HTTP_PROXY= --env HTTPS_PROXY= --env http_proxy= --env https_proxy= \
  --env DEBUG="${DEBUG:-}" \
  --env ACTIONS_ID_TOKEN_REQUEST_TOKEN= --env ACTIONS_RUNTIME_TOKEN= \
  "qwen-action-agent:${SUFFIX}" "${cli_entry}" --approval-mode default \
  --mcp-config "${MCP_CONFIG}" --prompt "${PROMPT}" --channel=CI --output-format json \
  > "${TEMP_STDOUT}" 2> "${TEMP_STDERR}" || FAILED=true
