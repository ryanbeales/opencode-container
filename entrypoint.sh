#!/bin/bash
# entrypoint.sh (v7): High-Performance K3s Deployment Architecture
# Managed by PM2 with "sticky" ConfigMap-aware persistence.

set -e

# Default to internal ollama service if not provided
export OLLAMA_HOST="${OLLAMA_HOST:-http://ollama:11434}"
export OLLAMA_MODEL="${OLLAMA_MODEL:-gpt-oss:20b}"

# Environment Variables for model selection (for apps that use them)
export OPENCODE_MODEL="ollama/${OLLAMA_MODEL}"
export ZEN_MODEL="ollama/${OLLAMA_MODEL}"
export OPENCODE_SKIP_START=true
# Ensure HOME is correct (OpenCode apps rely on this)
export HOME="/home/opencode"
export OPENCODE_HOST="${OPENCODE_HOST:-http://localhost:41851}"

# Ensure /bin/bash is linked (Debian Bookworm default is /usr/bin/bash)
if [ ! -f /bin/bash ] && [ -f /usr/bin/bash ]; then
    ln -s /usr/bin/bash /bin/bash
fi

# Ensure home exists
mkdir -p /home/opencode

# --- Persistent Config Logic (No-Overwrite) ---

# 1. OpenCode Configuration
mkdir -p /home/opencode/.config/opencode
if [[ ! -f /home/opencode/.config/opencode/opencode.json ]]; then
  echo "info  Generating default opencode.json..."
  cat <<EOF > /home/opencode/.config/opencode/opencode.json
{
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama",
      "options": {
        "baseURL": "${OLLAMA_HOST}/v1"
      },
      "models": {
        "${OLLAMA_MODEL}": {
          "name": "${OLLAMA_MODEL}"
        }
      }
    }
  },
  "model": "ollama/${OLLAMA_MODEL}",
  "enabled_providers": ["ollama", "openai-compatible"]
}
EOF
else
  echo "info  Using existing opencode.json (skipping generation)"
fi

# 2. OpenChamber Configuration (also known as OpenNomad in some contexts)
mkdir -p /home/opencode/.config/openchamber
if [[ ! -f /home/opencode/.config/openchamber/settings.json ]]; then
  echo "info  Generating default openchamber/settings.json..."
  cat <<EOF > /home/opencode/.config/openchamber/settings.json
{
  "notifyOnSubtasks": true,
  "notifyOnCompletion": true,
  "zenModel": "ollama/${OLLAMA_MODEL}",
  "lightThemeId": "flexoki-light",
  "darkThemeId": "flexoki-dark",
  "approvedDirectories": [],
  "securityScopedBookmarks": []
}
EOF
else
  echo "info  Using existing openchamber settings (skipping generation)"
fi

# 3. Create placeholder for OpenNomad if needed
mkdir -p /home/opencode/.config/opennomad

# --- PM2 Orchestration ---
# Generate PM2 Ecosystem file based on requested services
# Default to both for backward compatibility
RUN_SERVER="${RUN_SERVER:-true}"
RUN_UI="${RUN_UI:-true}"

cat <<EOF > /home/opencode/ecosystem.config.json
{
  "apps": [
$(
  APPS=()
  if [[ "${RUN_SERVER}" == "true" ]]; then
    APPS+=("    {
      \"name\": \"opencode-server\",
      \"script\": \"opencode\",
      \"args\": \"serve --port 41851 --hostname 0.0.0.0\",
      \"interpreter\": \"none\",
      \"cwd\": \"/home/opencode\",
      \"autorestart\": true,
      \"watch\": false
    }")
  fi
  if [[ "${RUN_UI}" == "true" ]]; then
    APPS+=("    {
      \"name\": \"openchamber-ui\",
      \"script\": \"openchamber\",
      \"args\": \"--foreground --host 0.0.0.0 --ui-password ${UI_PASSWORD:-be-creative-here}\",
      \"interpreter\": \"none\",
      \"cwd\": \"/home/opencode\",
      \"autorestart\": true,
      \"watch\": false
    }")
  fi
  (IFS=$',\n'; echo "${APPS[*]}")
)
  ]
}
EOF

# Final permission sweep (skip if root-only mode requested for some paths)
[[ "${RUN_AS_ROOT}" != "true" ]] && chown -R opencode:opencode /home/opencode 2>/dev/null || true
chmod 644 /home/opencode/.config/openchamber/settings.json 2>/dev/null || true
chmod 644 /home/opencode/.config/opencode/opencode.json 2>/dev/null || true

# Change to workspace directory for all subsequent commands
cd /home/opencode

# If we are just running a one-off command, use gosu directly unless root mode
if [ "$#" -gt 0 ]; then
  if [[ "${RUN_AS_ROOT}" == "true" ]]; then
    exec "$@"
  else
    exec gosu opencode "$@"
  fi
fi

# Launch with PM2-runtime (designed for Docker PID 1 / managed signals)
echo "info  Launching PM2 orchestrator..."
if [[ "${RUN_AS_ROOT}" == "true" ]]; then
  exec pm2-runtime start /home/opencode/ecosystem.config.json
else
  exec gosu opencode pm2-runtime start /home/opencode/ecosystem.config.json
fi
