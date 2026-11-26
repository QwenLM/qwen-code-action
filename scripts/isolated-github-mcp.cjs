const http = require('node:http');
const { Client } = require('@modelcontextprotocol/sdk/client/index.js');
const { StdioClientTransport } = require('@modelcontextprotocol/sdk/client/stdio.js');
const { StreamableHTTPServerTransport } = require('@modelcontextprotocol/sdk/server/streamableHttp.js');
const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} = require('@modelcontextprotocol/sdk/types.js');

const review = process.env.REVIEW_ONLY === 'true';
const [owner, repo] = process.env.GITHUB_REPOSITORY.split('/');
const number = Number(process.env.ISSUE_NUMBER);
const upstream = new Client({ name: 'isolated-github-client', version: '1.0.0' });
let toolsPromise;
async function tools() {
  toolsPromise ??= (async () => {
    const transport = new StdioClientTransport({
      command: process.env.GITHUB_MCP_BIN,
      args: ['stdio', '--toolsets', 'repos,issues,pull_requests'],
      env: {
        PATH: '/usr/local/bin:/usr/bin:/bin',
        GITHUB_PERSONAL_ACCESS_TOKEN: process.env.GITHUB_TOKEN,
        GITHUB_HOST: 'https://github.com',
        HTTPS_PROXY: process.env.HTTPS_PROXY || '',
        HTTP_PROXY: process.env.HTTP_PROXY || '',
        NO_PROXY: process.env.NO_PROXY || '',
      },
      stderr: 'inherit',
    });
    await upstream.connect(transport);
    return (await upstream.listTools()).tools;
  })();
  return toolsPromise;
}
const reviewTools = new Set(['create_pending_pull_request_review', 'add_comment_to_pending_review', 'pull_request_read', 'submit_pending_pull_request_review']);
const invokeTools = new Set(['add_issue_comment', 'get_issue', 'get_issue_comments', 'list_issues', 'search_issues', 'pull_request_read', 'list_pull_requests', 'search_pull_requests', 'get_commit', 'get_file_contents', 'list_commits', 'search_code']);
const pullRequestTools = new Set(['pull_request_read', 'add_comment_to_pending_review', 'create_pending_pull_request_review', 'submit_pending_pull_request_review']);
const searchTools = new Set(['search_code', 'search_issues', 'search_pull_requests']);
function permitted(name) { return (review ? reviewTools : invokeTools).has(name); }
function validate(name, args) {
  if (!permitted(name) || !args || Array.isArray(args)) throw new Error('tool is not permitted');
  if (name === 'add_issue_comment') {
    if (typeof args.body !== 'string' || !args.body || args.body.length > 60000 || Number(args.issue_number) !== number) {
      throw new Error('invalid issue comment');
    }
  }
  if (review && name === 'submit_pending_pull_request_review') {
    if (typeof args.body !== 'string' || args.body.length > 60000) throw new Error('invalid review body');
  }
  const safe = { ...args, owner, repo };
  if (pullRequestTools.has(name) || name === 'get_issue' || name === 'get_issue_comments') {
    if (Number(args.pullNumber ?? args.pull_number ?? args.issue_number) !== number) throw new Error('wrong issue or pull request');
    safe.pullNumber = number;
  }
  if (searchTools.has(name)) {
    safe.query = `${String(args.query || '').replace(/(^|\s)-?repo:\S+/gi, ' ')} repo:${owner}/${repo}`.trim();
    delete safe.owner;
    delete safe.repo;
  }
  if (review && name === 'submit_pending_pull_request_review') safe.event = 'COMMENT';
  if (name === 'get_file_contents') {
    safe.ref = process.env.BASE_SHA;
    delete safe.sha;
  }
  if (name === 'get_commit') safe.sha = process.env.BASE_SHA;
  if (name === 'list_commits') {
    for (const key of ['sha', 'branch', 'ref']) delete safe[key];
    safe.sha = process.env.BASE_SHA;
  }
  return safe;
}
async function createGateway() {
  const remote = await tools();
  const permittedTools = remote.filter((tool) => permitted(tool.name));
  const server = new Server({ name: 'qwen-isolated-github', version: '1.0.0' }, {
    capabilities: { tools: { listChanged: false } },
  });
  server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: permittedTools }));
  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args = {} } = request.params;
    return upstream.callTool({ name, arguments: validate(name, args) });
  });
  return server;
}
async function main() {
  await tools();
  const permittedTools = (await tools()).filter((tool) => permitted(tool.name));
  if (permittedTools.length !== (review ? reviewTools : invokeTools).size) {
    throw new Error('GitHub MCP tool set does not match the required workflow contract');
  }
  if (permittedTools.length !== (review ? reviewTools : invokeTools).size) {
    throw new Error('GitHub MCP tool set does not match the required workflow contract');
  }
  http.createServer(async (req, res) => {
    const chunks = [];
    for await (const chunk of req) chunks.push(chunk);
    if (req.method !== 'POST' || req.url !== '/mcp' || req.headers.authorization !== `Bearer ${process.env.GATEWAY_TOKEN}`) {
      res.writeHead(404).end();
      return;
    }
    let body;
    try { body = JSON.parse(Buffer.concat(chunks).toString()); }
    catch { res.writeHead(400).end(); return; }
    const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined });
    const server = await createGateway();
    await server.connect(transport);
    res.on('close', () => Promise.all([transport.close(), server.close()]).catch(() => {}));
    await transport.handleRequest(req, res, body);
  }).listen(8080, '0.0.0.0');
}
main().catch((error) => { console.error(error); process.exit(1); });
