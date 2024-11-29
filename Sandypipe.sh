#!/bin/bash

# Menampilkan ASCII Art untuk "Saandy"
echo "
  ██████ ▄▄▄     ▄▄▄      ███▄    █▓█████▓██   ██▓
▒██    ▒▒████▄  ▒████▄    ██ ▀█   █▒██▀ ██▒██  ██▒
░ ▓██▄  ▒██  ▀█▄▒██  ▀█▄ ▓██  ▀█ ██░██   █▌▒██ ██░
  ▒   ██░██▄▄▄▄█░██▄▄▄▄██▓██▒  ▐▌██░▓█▄   ▌░ ▐██▓░
▒██████▒▒▓█   ▓██▓█   ▓██▒██░   ▓██░▒████▓ ░ ██▒▓░
▒ ▒▓▒ ▒ ░▒▒   ▓▒█▒▒   ▓▒█░ ▒░   ▒ ▒ ▒▒▓  ▒  ██▒▒▒ 
░ ░▒  ░ ░ ▒   ▒▒ ░▒   ▒▒ ░ ░░   ░ ▒░░ ▒  ▒▓██ ░▒░ 
░  ░  ░   ░   ▒   ░   ▒     ░   ░ ░ ░ ░  ░▒ ▒ ░░  
      ░       ░  ░    ░  ░        ░   ░   ░ ░     
                                    ░     ░ ░     
"

# Meminta input URL
read -p "Masukkan PIPE-URL: " PIPE_URL
read -p "Masukkan DCDND-URL: " DCDND_URL

# 1. Membuat direktori
sudo mkdir -p /opt/dcdn

# 2. Mengunduh binary Pipe tool dari URL
sudo curl -L "$PIPE_URL" -o /opt/dcdn/pipe-tool

# 3. Mengunduh binary Node dari URL
sudo curl -L "$DCDND_URL" -o /opt/dcdn/dcdnd

# 4. Membuat binary dapat dieksekusi
sudo chmod +x /opt/dcdn/pipe-tool
sudo chmod +x /opt/dcdn/dcdnd

# 5. Login untuk menghasilkan token akses
echo "Silakan login untuk menghasilkan token akses. Ikuti instruksi di bawah ini:"
/opt/dcdn/pipe-tool login --node-registry-url="https://rpc.pipedev.network"
echo "Login selesai. Silakan lanjut ke langkah berikutnya."

# 6. Menghasilkan token pendaftaran
/opt/dcdn/pipe-tool generate-registration-token --node-registry-url="https://rpc.pipedev.network"

# 7. Membuat file service
sudo bash -c 'cat > /etc/systemd/system/dcdnd.service << EOF
[Unit]
Description=DCDN Node Service
After=network.target
Wants=network-online.target

[Service]
ExecStart=/opt/dcdn/dcdnd \\
                --grpc-server-url=0.0.0.0:8002 \\
                --http-server-url=0.0.0.0:8003 \\
                --node-registry-url="https://rpc.pipedev.network" \\
                --cache-max-capacity-mb=1024 \\
                --credentials-dir=/root/.permissionless \\
                --allow-origin=*

Restart=always
RestartSec=5
LimitNOFILE=65536
LimitNPROC=4096

StandardOutput=journal
StandardError=journal
SyslogIdentifier=dcdn-node

WorkingDirectory=/opt/dcdn

[Install]
WantedBy=multi-user.target
EOF'

# 8. Memulai Node
sudo systemctl daemon-reload
sudo systemctl enable dcdnd
sudo systemctl start dcdnd

# 9. Menghasilkan dan mendaftar dompet
echo "Menghasilkan dan mendaftar dompet..."
/opt/dcdn/pipe-tool generate-wallet --node-registry-url="https://rpc.pipedev.network"
echo "Simpan frasa dompet dan file keypair.json untuk cadangan."
/opt/dcdn/pipe-tool link-wallet --node-registry-url="https://rpc.pipedev.network"

# 10. Memeriksa status node
echo "Memeriksa status node..."
/opt/dcdn/pipe-tool list-nodes --node-registry-url="https://rpc.pipedev.network"

echo "Skrip selesai."
