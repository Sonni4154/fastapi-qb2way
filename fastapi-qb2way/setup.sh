#!/usr/bin/env bash
set -euo pipefail

# ─── 0. PRE-REQUISITE ─────────────────────────────────────────────────────────────
# Before you run this, export your real GitHub repo URL:
#   export REPO_URL="https://github.com/Sonni4154/fastapi-qb2way.git"
#
# And if you prefer HTTPS+PAT over SSH, also do:
#   export GITHUB_PAT="ghp_XXXXXXXXXXXXXXXXXXXXXXXXXXXX"
#
# If you want SSH instead, add your SSH key to GitHub and skip the GITHUB_PAT export.
: "${REPO_URL:?Error: REPO_URL environment variable not set.
Please run:
  export REPO_URL=\"https://github.com/YourUser/fastapi-qb2way.git\""
TARGET_DIR="/opt/fastapi-qb2way"

# ─── 1. Install system deps ───────────────────────────────────────────────────────
echo ">> Installing core packages…"
sudo apt-get update
sudo apt-get install -y \
    python3 python3-venv python3-pip \
    postgresql postgresql-contrib libpq-dev \
    git curl

# ─── 2. Clone your repo ───────────────────────────────────────────────────────────
echo ">> Cloning $REPO_URL into $TARGET_DIR"
if [[ -n "${GITHUB_PAT:-}" ]]; then
  echo "   • Using HTTPS + PAT"
  CLONE_URL="${REPO_URL/\/\//\/\/${GITHUB_PAT}@}"
else
  echo "   • Using direct URL (SSH or public HTTPS)"
  CLONE_URL="$REPO_URL"
fi

sudo rm -rf "$TARGET_DIR"
sudo mkdir -p "$(dirname "$TARGET_DIR")"
sudo chown "$(id -u):$(id -g)" "$(dirname "$TARGET_DIR")"
git clone "$CLONE_URL" "$TARGET_DIR"

# ─── 3. Set up virtualenv & requirements ────────────────────────────────────────
echo ">> Setting up Python virtualenv…"
cd "$TARGET_DIR"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install --no-cache-dir -r requirements.txt

# ─── 4. Create .env ─────────────────────────────────────────────────────────────
echo ">> Writing .env file…"
cat > .env <<EOF
DATABASE_URL=postgresql+psycopg2://appuser:changeme@localhost:5432/appdb
#!/usr/bin/env bash
set -euo pipefail

# ─── 0. PRE-REQUISITE ─────────────────────────────────────────────────────────────
# Before you run this, export your real GitHub repo URL:
#   export REPO_URL="https://github.com/Sonni4154/fastapi-qb2way.git"
#
# And if you prefer HTTPS+PAT over SSH, also do:
#   export GITHUB_PAT="ghp_XXXXXXXXXXXXXXXXXXXXXXXXXXXX"
#
# If you want SSH instead, add your SSH key to GitHub and skip the GITHUB_PAT export.
: "${REPO_URL:?Error: REPO_URL environment variable not set.
Please run:
  export REPO_URL=\"https://github.com/YourUser/fastapi-qb2way.git\""
TARGET_DIR="/opt/fastapi-qb2way"

# ─── 1. Install system deps ───────────────────────────────────────────────────────
echo ">> Installing core packages…"
sudo apt-get update
sudo apt-get install -y \
    python3 python3-venv python3-pip \
    postgresql postgresql-contrib libpq-dev \
    git curl

# ─── 2. Clone your repo ───────────────────────────────────────────────────────────
echo ">> Cloning $REPO_URL into $TARGET_DIR"
if [[ -n "${GITHUB_PAT:-}" ]]; then
  echo "   • Using HTTPS + PAT"
  CLONE_URL="${REPO_URL/\/\//\/\/${GITHUB_PAT}@}"
else
  echo "   • Using direct URL (SSH or public HTTPS)"
  CLONE_URL="$REPO_URL"
fi

sudo rm -rf "$TARGET_DIR"
sudo mkdir -p "$(dirname "$TARGET_DIR")"
sudo chown "$(id -u):$(id -g)" "$(dirname "$TARGET_DIR")"
git clone "$CLONE_URL" "$TARGET_DIR"

# ─── 3. Set up virtualenv & requirements ────────────────────────────────────────
echo ">> Setting up Python virtualenv…"
cd "$TARGET_DIR"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install --no-cache-dir -r requirements.txt

# ─── 4. Create .env ─────────────────────────────────────────────────────────────
echo ">> Writing .env file…"
cat > .env <<EOF
DATABASE_URL=postgresql+psycopg2://appuser:changeme@localhost:5432/appdb
QB_CLIENT_ID=your_qb_client_id
QB_CLIENT_SECRET=your_qb_client_secret
QB_REALM_ID=your_qb_realm_id
QB_REDIRECT_URI=https://your-domain.com/auth/quickbooks/callback
EOF

# ─── 5. systemd service ─────────────────────────────────────────────────────────
echo ">> Creating systemd service…"
SERVICE_FILE="/etc/systemd/system/fastapi-qb.service"
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=FastAPI QuickBooks 2-Way Sync
After=network.target postgresql.service

[Service]
Type=simple
User=$(id -un)
WorkingDirectory=${TARGET_DIR}
EnvironmentFile=${TARGET_DIR}/.env
ExecStart=${TARGET_DIR}/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# ─── 6. Enable & start ─────────────────────────────────────────────────────────
echo ">> Enabling and starting service…"
sudo systemctl daemon-reload
sudo systemctl enable fastapi-qb.service
sudo systemctl start fastapi-qb.service

echo "✅  All done—FastAPI is running on port 8000."

EOF

# ─── 5. systemd service ─────────────────────────────────────────────────────────
echo ">> Creating systemd service…"
SERVICE_FILE="/etc/systemd/system/fastapi-qb.service"
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=FastAPI QuickBooks 2-Way Sync
After=network.target postgresql.service

[Service]
Type=simple
User=$(id -un)
WorkingDirectory=${TARGET_DIR}
EnvironmentFile=${TARGET_DIR}/.env
ExecStart=${TARGET_DIR}/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# ─── 6. Enable & start ─────────────────────────────────────────────────────────
echo ">> Enabling and starting service…"
sudo systemctl daemon-reload
sudo systemctl enable fastapi-qb.service
sudo systemctl start fastapi-qb.service

echo "✅  All done—FastAPI is running on port 8000."
