#!/bin/bash

# Menampilkan ASCII art untuk "Saandy"
echo "  ██████ ▄▄▄     ▄▄▄      ███▄    █▓█████▓██   ██▓"
echo "▒██    ▒▒████▄  ▒████▄    ██ ▀█   █▒██▀ ██▒██  ██▒"
echo "░ ▓██▄  ▒██  ▀█▄▒██  ▀█▄ ▓██  ▀█ ██░██   █▌▒██ ██░"
echo "  ▒   ██░██▄▄▄▄█░██▄▄▄▄██▓██▒  ▐▌██░▓█▄   ▌░ ▐██▓░"
echo "▒██████▒▒▓█   ▓██▓█   ▓██▒██░   ▓██░▒████▓ ░ ██▒▓░"
echo "▒ ▒▓▒ ▒ ░▒▒   ▓▒█▒▒   ▓▒█░ ▒░   ▒ ▒ ▒▒▓  ▒  ██▒▒▒ "
echo "░ ░▒  ░ ░ ▒   ▒▒ ░▒   ▒▒ ░ ░░   ░ ▒░░ ▒  ▒▓██ ░▒░ "
echo "░  ░  ░   ░   ▒   ░   ▒     ░   ░ ░ ░ ░  ░▒ ▒ ░░  "
echo "      ░       ░  ░    ░  ░        ░   ░   ░ ░     "
echo "                                    ░     ░ ░     "
echo

# Meminta input dari pengguna
read -p "Masukkan Link Pipe Tool Binary: " PIPE
read -p "Masukkan Link Node Binary: " BINARY

# Mengecek apakah URL diisi
if [[ -z "$PIPE" || -z "$BINARY" ]]; then
    echo "Error: Link Pipe Tool dan Node Binary harus diisi!"
    exit 1
fi

# Membuat direktori jika belum ada
sudo mkdir -p /opt/dcdn

# Mengunduh file biner
sudo curl -L "$PIPE" -o /opt/dcdn/pipe-tool
if [[ $? -ne 0 ]]; then
    echo "Error: Gagal mengunduh pipe-tool dari $PIPE"
    exit 1
fi

sudo curl -L "$BINARY" -o /opt/dcdn/dcdnd
if [[ $? -ne 0 ]]; then
    echo "Error: Gagal mengunduh dcdnd dari $BINARY"
    exit 1
fi

# Memberikan izin eksekusi pada file biner
sudo chmod +x /opt/dcdn/pipe-tool
sudo chmod +x /opt/dcdn/dcdnd

# Membuat file service untuk systemd
sudo tee /etc/systemd/system/dcdnd.service > /dev/null << 'EOF'
[Unit]
Description=DCDN Node Service
After=network.target
Wants=network-online.target

[Service]
ExecStart=/opt/dcdn/dcdnd \
                --grpc-server-url=0.0.0.0:8002 \
                --http-server-url=0.0.0.0:8003 \
                --node-registry-url="https://rpc.pipedev.network" \
                --cache-max-capacity-mb=1024 \
                --credentials-dir=/root/.permissionless \
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
EOF

# Generate token registrasi menggunakan pipe-tool
echo "Membuat token registrasi..."
/opt/dcdn/pipe-tool generate-registration-token --node-registry-url="https://rpc.pipedev.network"
if [[ $? -ne 0 ]]; then
    echo "Error: Gagal membuat token registrasi."
    exit 1
fi

# Login menggunakan pipe-tool dan menampilkan QR code
echo "Silakan pindai QR code yang ditampilkan untuk melanjutkan login."
/opt/dcdn/pipe-tool login --node-registry-url="https://rpc.pipedev.network"
if [[ $? -ne 0 ]]; then
    echo "Error: Gagal login ke registry."
    exit 1
fi

# Verifikasi login berhasil
echo "Finalizing login..."
while true; do
    LOGIN_SUCCESS=$( /opt/dcdn/pipe-tool list-nodes --node-registry-url="https://rpc.pipedev.network" 2>&1 )
    if [[ "$LOGIN_SUCCESS" =~ "User registered successfully" || "$LOGIN_SUCCESS" =~ "Logged in successfully" ]]; then
        echo "Login berhasil!"
        break
    else
        echo "Menunggu login selesai... (Coba lagi dalam 5 detik)"
        sleep 5
    fi
done

# Generate wallet menggunakan pipe-tool
echo "Membuat wallet baru..."
/opt/dcdn/pipe-tool generate-wallet --node-registry-url="https://rpc.pipedev.network"
if [[ $? -ne 0 ]]; then
    echo "Error: Gagal membuat wallet."
    exit 1
fi
echo "Wallet berhasil dibuat."

# Menautkan dompet menggunakan pipe-tool
echo "Menautkan dompet..."
/opt/dcdn/pipe-tool link-wallet --node-registry-url="https://rpc.pipedev.network"
if [[ $? -ne 0 ]]; then
    echo "Error: Gagal menautkan dompet."
    exit 1
fi
echo "Dompet berhasil ditautkan."

# Reload systemd, enable, dan mulai service
sudo systemctl daemon-reload
sudo systemctl enable dcdnd
sudo systemctl start dcdnd

# Restart layanan untuk memastikan semua pengaturan diterapkan
sudo systemctl restart dcdnd

# Menampilkan daftar node yang terdaftar
echo "Menampilkan daftar node yang terdaftar..."
/opt/dcdn/pipe-tool list-nodes --node-registry-url="https://rpc.pipedev.network"
