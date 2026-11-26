const http = require('node:http');
const { Readable } = require('node:stream');
const base = new URL(process.env.UPSTREAM_BASE_URL);
if (!['https:', 'http:'].includes(base.protocol)) throw new Error('invalid model endpoint');
const basePath = base.pathname.replace(/\/+$/, '');
http.createServer(async (req, res) => {
  if (req.method === 'GET' && req.url === '/__health') {
    res.end('ok');
    return;
  }
  if (req.headers.authorization !== `Bearer ${process.env.PROXY_TOKEN}` ||
    req.method !== 'POST' || req.url !== '/v1/chat/completions') {
    res.writeHead(403).end();
    return;
  }
  const target = new URL(base);
  target.pathname = `${basePath}/chat/completions`;
  const headers = new Headers(req.headers);
  for (const key of ['host', 'content-length', 'connection', 'authorization']) headers.delete(key);
  headers.set('authorization', `Bearer ${process.env.UPSTREAM_API_KEY}`);
  try {
    const upstream = await fetch(target, {
      method: req.method, headers, body: req, duplex: 'half',
    });
    res.writeHead(upstream.status, { 'content-type': upstream.headers.get('content-type') || 'application/json' });
    if (upstream.body) Readable.fromWeb(upstream.body).pipe(res);
    else res.end();
  } catch {
    res.writeHead(502).end();
  }
}).listen(8080, '0.0.0.0');
