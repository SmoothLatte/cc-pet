#!/usr/bin/env node
const net = require('net');
const path = require('path');
const os = require('os');
const fs = require('fs');

const SOCKET = path.join(os.homedir(), '.cc-pet', 'pet.sock');

try { fs.statSync(SOCKET); } catch { process.exit(0); }

let data = '';
process.stdin.on('data', chunk => data += chunk);
process.stdin.on('end', () => {
  try {
    const payload = JSON.parse(data);
    const event = {
      event: process.env.CLAUDE_CODE_HOOK_EVENT_NAME || 'unknown',
      session_id: payload.session_id,
      cwd: payload.cwd,
      timestamp: Math.floor(Date.now() / 1000),
      ...(payload.tool_name && { tool: payload.tool_name }),
      ...(payload.tool_input && { tool_input: payload.tool_input }),
    };
    const client = net.createConnection(SOCKET, () => {
      client.end(JSON.stringify(event) + '\n');
    });
    client.on('error', () => {});
    setTimeout(() => process.exit(0), 3000);
  } catch { process.exit(0); }
});
