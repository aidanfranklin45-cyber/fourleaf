import { spawn } from 'node:child_process';
import fs from 'node:fs';
import net from 'node:net';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, '..');

// 1. Load .env.fourleaf
const envPath = path.join(rootDir, '.env.fourleaf');
const envVars = { ...process.env, COREPACK_ENABLE_DOWNLOAD_PROMPT: '0' };

if (fs.existsSync(envPath)) {
  const lines = fs.readFileSync(envPath, 'utf8').split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed && !trimmed.startsWith('#') && trimmed.includes('=')) {
      const idx = trimmed.indexOf('=');
      const key = trimmed.slice(0, idx).trim();
      const val = trimmed.slice(idx + 1).trim();
      envVars[key] = val;
    }
  }
}

// Force 127.0.0.1 for local Redis and localhost for local Gateway
envVars.REDIS_URL = 'redis://127.0.0.1:6379';
envVars.GATEWAY_URL = 'http://localhost:8080';

const processes = [];

function startProcess(name, cmd, args, extraEnv = {}, cwd = rootDir) {
  console.log(`[FourLeaf] Starting ${name}...`);
  const child = spawn(cmd, args, {
    cwd,
    env: { ...envVars, ...extraEnv },
    shell: true,
    stdio: 'inherit'
  });

  child.on('error', (err) => {
    console.error(`[${name}] Error:`, err.message);
  });

  child.on('exit', (code, signal) => {
    console.log(`[${name}] Exited with code ${code ?? signal}`);
  });

  processes.push(child);
  return child;
}

function isPortOpen(port, host = '127.0.0.1') {
  return new Promise((resolve) => {
    const socket = new net.Socket();
    socket.setTimeout(800);
    socket.on('connect', () => {
      socket.destroy();
      resolve(true);
    });
    socket.on('timeout', () => {
      socket.destroy();
      resolve(false);
    });
    socket.on('error', () => {
      socket.destroy();
      resolve(false);
    });
    socket.connect(port, host);
  });
}

async function waitForPort(port, host = '127.0.0.1', timeoutMs = 25000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    if (await isPortOpen(port, host)) return true;
    await new Promise((r) => setTimeout(r, 500));
  }
  return false;
}

async function main() {
  // 2. Ensure Redis is running
  const redisPortOpen = await isPortOpen(6379);
  if (!redisPortOpen) {
    const redisBin =
      'C:\\Users\\Aidan\\AppData\\Local\\Microsoft\\WinGet\\Packages\\taizod1024.redis-windows-fork_Microsoft.Winget.Source_8wekyb3d8bbwe\\Redis-8.10.1-Windows-x64-msys2\\redis-server.exe';
    if (fs.existsSync(redisBin)) {
      console.log('[FourLeaf] Starting Redis server on port 6379...');
      const redisChild = spawn(redisBin, [], {
        cwd: path.dirname(redisBin),
        stdio: 'ignore'
      });
      processes.push(redisChild);
    } else {
      console.warn(
        '[FourLeaf] Warning: redis-server.exe not found at default path'
      );
    }

    const ready = await waitForPort(6379);
    if (!ready) {
      console.error(
        '[FourLeaf] Error: Timed out waiting for Redis on port 6379.'
      );
    } else {
      console.log('[FourLeaf] Redis is live on port 6379.');
    }
  } else {
    console.log('[FourLeaf] Redis is already active on port 6379.');
  }

  // 3. Start Authenticator
  startProcess(
    'Authenticator',
    'yarn',
    ['workspace', '@microrealestate/authenticator', 'run', 'start'],
    {
      PORT: '8000',
      EMAILER_URL: 'http://localhost:8400/emailer'
    }
  );

  // 4. Start Core API
  startProcess(
    'Core-API',
    'yarn',
    ['workspace', '@microrealestate/api', 'run', 'start'],
    {
      PORT: '8200',
      EMAILER_URL: 'http://localhost:8400/emailer',
      PDFGENERATOR_URL: 'http://localhost:8300/pdfgenerator'
    }
  );

  // Wait for Authenticator to be live before opening frontends
  await waitForPort(8000);
  console.log('[FourLeaf] Authenticator is live on port 8000.');

  // 5. Start Landlord UI
  startProcess('Landlord-UI', 'yarn', [
    'workspace',
    '@microrealestate/landlord',
    'run',
    'next',
    'dev',
    '-p',
    '8180'
  ]);

  // 6. Start Gateway
  startProcess(
    'Gateway',
    'yarn',
    ['workspace', '@microrealestate/gateway', 'run', 'start'],
    {
      PORT: '8080',
      AUTHENTICATOR_URL: 'http://localhost:8000',
      API_URL: 'http://localhost:8200/api/v2',
      LANDLORD_FRONTEND_URL: 'http://localhost:8180',
      TENANT_FRONTEND_URL: 'http://localhost:8190',
      PDFGENERATOR_URL: 'http://localhost:8300/pdfgenerator',
      EMAILER_URL: 'http://localhost:8400/emailer',
      TENANTAPI_URL: 'http://localhost:8250/tenantapi'
    }
  );

  await waitForPort(8080);
  console.log('\n==========================================================');
  console.log('  FourLeaf Stack is Live at http://localhost:8080/landlord');
  console.log('  Login: aidan.franklin45@gmail.com / Password123!');
  console.log('  Press Ctrl+C to stop all services.');
  console.log('==========================================================\n');

  spawn('cmd.exe', ['/c', 'start', 'http://localhost:8080/landlord'], {
    shell: true
  });
}

function cleanup() {
  console.log('\n[FourLeaf] Shutting down all services...');
  for (const proc of processes) {
    try {
      proc.kill('SIGTERM');
    } catch {}
  }
  process.exit(0);
}

process.on('SIGINT', cleanup);
process.on('SIGTERM', cleanup);

main().catch((err) => {
  console.error('[FourLeaf] Fatal error:', err);
  cleanup();
});
