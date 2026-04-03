import express from 'express';
import cors from 'cors';
import { writeFileSync, existsSync, readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const PORT = process.env.ONETIME_PORT || 9090;
const PROJECT_DIR = process.env.PROJECT_DIR || '/project';

// Paths for config/status exchange with host install.sh
const CONFIG_FILE = join(PROJECT_DIR, 'deploy-config.json');
const STATUS_FILE = join(PROJECT_DIR, 'deploy-status.json');

app.use(cors());
app.use(express.json({ limit: '5mb' }));

// Serve the Vue3 frontend (production build)
const distPath = join(__dirname, '..', 'dist');
if (existsSync(distPath)) {
  app.use(express.static(distPath));
}

// ─── Health check ───
app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok' });
});

// ─── Detect server public IP (reads from file written by host install.sh) ───
app.get('/api/detect-ip', (_req, res) => {
  try {
    const ipFile = join(PROJECT_DIR, 'server-ip.txt');
    if (existsSync(ipFile)) {
      const ip = readFileSync(ipFile, 'utf-8').trim();
      return res.json({ ip });
    }
    // Fallback: use request IP
    const forwarded = _req.headers['x-forwarded-for'];
    const ip = forwarded ? forwarded.split(',')[0].trim() : _req.socket.remoteAddress || '';
    res.json({ ip: ip.replace('::ffff:', '') });
  } catch {
    res.json({ ip: '' });
  }
});

// ─── Get deployment status (polled by frontend) ───
// The host install.sh writes deploy-status.json; we just read and return it.
app.get('/api/deploy/status', (_req, res) => {
  try {
    if (existsSync(STATUS_FILE)) {
      const data = JSON.parse(readFileSync(STATUS_FILE, 'utf-8'));
      return res.json(data);
    }
  } catch (err) {
    console.warn('[STATUS] Error reading status file:', err.message);
  }
  res.json({ phase: 'idle', message: '', log: [], complete: false, error: false });
});

// ─── Submit deployment configuration ───
// Saves config to a JSON file. The host install.sh watches for this file
// and runs the actual deployment with full host access (docker, certbot, git, etc.)
app.post('/api/deploy', (req, res) => {
  try {
    // Check if deployment already in progress (removed to allow retries)
    // if (existsSync(STATUS_FILE)) {
    //   const status = JSON.parse(readFileSync(STATUS_FILE, 'utf-8'));
    //   if (!status.complete && !status.error && status.phase !== 'idle') {
    //     return res.status(409).json({ error: 'Deployment already in progress' });
    //   }
    // }

    const config = req.body;

    // Validate minimum required fields
    if (!config.deployment?.githubToken) {
      return res.status(400).json({ error: 'GitHub token is required' });
    }

    // Write config for the host install.sh to pick up
    writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));
    console.log(`[DEPLOY] Config saved to ${CONFIG_FILE} (${JSON.stringify(config).length} bytes)`);

    // Write initial status so UI shows progress immediately
    const initialStatus = {
      phase: 'waiting',
      message: 'Configuration saved. Host deployment starting…',
      log: [`[${new Date().toISOString()}] Configuration submitted via web UI`],
      complete: false,
      error: false,
    };
    writeFileSync(STATUS_FILE, JSON.stringify(initialStatus, null, 2));

    res.json({ status: 'started', message: 'Configuration saved — deployment starting on host' });
  } catch (err) {
    console.error('[DEPLOY] Error:', err);
    res.status(500).json({ error: err.message });
  }
});

// SPA fallback — serve index.html for all non-API routes
app.get('*', (_req, res) => {
  const index = join(distPath, 'index.html');
  if (existsSync(index)) {
    res.sendFile(index);
  } else {
    res.status(200).send('ONETIME setup server running. Build the Vue frontend first.');
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`══════════════════════════════════════════════════`);
  console.log(`  HCOS Setup UI running on port ${PORT}`);
  console.log(`  Config file: ${CONFIG_FILE}`);
  console.log(`  Status file: ${STATUS_FILE}`);
  console.log(`══════════════════════════════════════════════════`);
});
