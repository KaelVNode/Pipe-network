#!/bin/bash

# Meminta input link binary pipe-tool dan dcdnd
read -p "Masukan Link Pipe tool Binary: " PIPE
read -p "Masukan Link Node Binary: " BINARY

# Membuat direktori /opt/dcdn jika belum ada
sudo mkdir -p /opt/dcdn

# Mengunduh binary pipe-tool dan dcdnd
echo "Mengunduh pipe-tool..."
sudo curl -L "$PIPE" -o /opt/dcdn/pipe-tool || { echo "Gagal mengunduh pipe-tool"; exit 1; }

echo "Mengunduh dcdnd..."
sudo curl -L "$BINARY" -o /opt/dcdn/dcdnd || { echo "Gagal mengunduh dcdnd"; exit 1; }

# Memberikan izin eksekusi pada binary
echo "Memberikan izin eksekusi pada binary..."
sudo chmod +x /opt/dcdn/pipe-tool
sudo chmod +x /opt/dcdn/dcdnd

# Membuat file service systemd untuk dcdnd
echo "Membuat file service systemd untuk dcdnd..."
sudo tee /etc/systemd/system/dcdnd.service > /dev/null << 'EOF'
[Unit]
Description=DCDN Node Service
After=network.target
Wants=network-online.target

[Service]
# Path ke executable dan argumen
ExecStart=/opt/dcdn/dcdnd \
                --grpc-server-url=0.0.0.0:8002 \
                --http-server-url=0.0.0.0:8003 \
                --node-registry-url="https://rpc.pipedev.network" \
                --cache-max-capacity-mb=1024 \
                --credentials-dir=/root/.permissionless \
                --allow-origin=*

# Kebijakan restart
Restart=always
RestartSec=5

# Batasan resource dan file descriptor
LimitNOFILE=65536
LimitNPROC=4096

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dcdn-node

# Direktori kerja
WorkingDirectory=/opt/dcdn

[Install]
WantedBy=multi-user.target
EOF

# Menjalankan perintah pipe-tool untuk menghasilkan token registrasi
echo "Menghasilkan token registrasi..."
/opt/dcdn/pipe-tool generate-registration-token --node-registry-url="https://rpc.pipedev.network" || { echo "Gagal menghasilkan token registrasi"; exit 1; }

# Memuat ulang systemd dan mengaktifkan service dcdnd
echo "Memuat ulang systemd dan mengaktifkan service dcdnd..."
sudo systemctl daemon-reload
sudo systemctl enable dcdnd
sudo systemctl start dcdnd

# Melakukan login dengan pipe-tool
echo "Login dengan pipe-tool..."
/opt/dcdn/pipe-tool login --node-registry-url="https://rpc.pipedev.network" || { echo "Login gagal"; exit 1; }

# Menautkan wallet dengan pipe-tool
echo "Menautkan wallet dengan pipe-tool..."
/opt/dcdn/pipe-tool link-wallet --node-registry-url="https://rpc.pipedev.network" || { echo "Gagal menautkan wallet"; exit 1; }

# Merestart service dcdnd setelah menautkan wallet
echo "Merestart service dcdnd..."
sudo systemctl restart dcdnd

# Menampilkan daftar node yang terhubung
echo "Daftar node yang terhubung..."
/opt/dcdn/pipe-tool list-nodes --node-registry-url="https://rpc.pipedev.network"
