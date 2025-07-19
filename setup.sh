#!/usr/bin/env bash
set -euo pipefail

# ── 1. System packages & Python install ───────────────────────────────────────
sudo apt-get update
sudo apt-get install -y \
    python3 python3-venv python3-pip \
    postgresql postgresql-contrib libpq-dev \
    git curl

# ── 2. Create PostgreSQL user & database ─────────────────────────────────────
DB_USER="sonny"
DB_PASS="changeme"
DB_NAME="syncdb"

sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | grep -q 1 || \
	  sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';"

sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};"

# ── 3. Clone application repo ─────────────────────────────────────────────────
TARGET_DIR="/opt/fastapi-qb2way"
REPO_URL="https://github.com/Sonni4154/fastapi-qb2way"

sudo rm -rf "$TARGET_DIR"
sudo mkdir -p "$(dirname "$TARGET_DIR")"
sudo chown "$(id -u):$(id -g)" "$(dirname "$TARGET_DIR")"

#if [[ -z "${GITHUB_PAT:-}" ]]; then
git clone "$REPO_URL" "$TARGET_DIR"
#else
#  git clone "https://${GITHUB_PAT}@github.com/Sonni4154/fastapi-qb2way.git" "$TARGET_DIR"
#fi

# ── 4. Setup Python virtualenv & install dependencies ────────────────────────
cd "$TARGET_DIR"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install --no-cache-dir -r requirements.txt

# ── 5. Prepare environment file ──────────────────────────────────────────────
cat > .env <<EOF
DATABASE_URL=postgresql+psycopg2://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}
QB_CLIENT_ID=ABcxWWL62bJFQd43vWFkko728BJLReocAxJKfeeemZtXfVAO1S
QB_CLIENT_SECRET=oKxdGvpLfvdbL4xxi9WYAPVlZDkGAnezwqwL1rmO
QB_REALM_ID=9130354674010826
QB_REDIRECT_URI=https://hook.wemakemarin.com/quickbooks/webhook
EOF

# ── 6. Create systemd service for FastAPI ───────────────────────────────────
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

# ── 7. Enable and start the service ──────────────────────────────────────────
sudo systemctl daemon-reload
sudo systemctl enable fastapi-qb.service
sudo systemctl start fastapi-qb.service

echo "✅ Setup complete. FastAPI app running on port 8000."