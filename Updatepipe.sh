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

# Meminta input URL untuk Pipe tool dan DCDND binary
read -p "Masukkan PIPE-URL: " PIPE_URL
read -p "Masukkan DCDND-URL: " DCDND_URL

# 2. Mengunduh binary Pipe tool dari URL
echo "Mengunduh pipe-tool dari $PIPE_URL..."
sudo curl -L "$PIPE_URL" -o /opt/dcdn/pipe-tool

# 3. Mengunduh binary Node dari URL
echo "Mengunduh dcdnd dari $DCDND_URL..."
sudo curl -L "$DCDND_URL" -o /opt/dcdn/dcdnd

# 4. Memberikan izin eksekusi pada kedua binary
echo "Memberikan izin eksekusi pada pipe-tool dan dcdnd..."
sudo chmod +x /opt/dcdn/pipe-tool
sudo chmod +x /opt/dcdn/dcdnd

# 5. Menginformasikan bahwa proses selesai
echo "Proses selesai! Pipe-tool dan dcdnd telah berhasil diunduh dan diberikan izin eksekusi."

# 6. Reload systemd dan mulai layanan dcdnd
echo "Memuat ulang konfigurasi systemd..."
sudo systemctl daemon-reload

# 7. Mengaktifkan layanan agar berjalan otomatis saat boot
echo "Mengaktifkan layanan dcdnd..."
sudo systemctl enable dcdnd

# 8. Memulai layanan dcdnd
echo "Memulai layanan dcdnd..."
sudo systemctl start dcdnd

# 9. Menginformasikan bahwa layanan dcdnd telah dimulai
echo "Layanan dcdnd telah berhasil dimulai."

# 10. Memeriksa status node
echo "Memeriksa status node..."
/opt/dcdn/pipe-tool list-nodes --node-registry-url="https://rpc.pipedev.network"
