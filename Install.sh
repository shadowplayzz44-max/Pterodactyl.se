#!/bin/bash

clear
echo "====================================="
echo "        Powered By Shadow"
echo "====================================="
sleep 1

# Check root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Please run as root!"
   exit 1
fi

# IPv4 check
IP=$(hostname -I | awk '{print $1}')
if [[ -z "$IP" ]]; then
    echo "❌ No IPv4 detected! Please use IPv4 VPS."
    exit 1
fi
echo "🌐 IPv4 detected: $IP"

# ============================
# Functions for main menu
# ============================

install_pterodactyl() {
    echo "🚀 Installing Pterodactyl Panel..."
    apt update -y && apt upgrade -y
    apt install -y software-properties-common curl apt-transport-https ca-certificates gnupg unzip git tar
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
    apt install -y nginx mariadb-server mariadb-client redis-server php8.2 php8.2-cli php8.2-gd php8.2-mysql php8.2-pdo php8.2-mbstring php8.2-tokenizer php8.2-bcmath php8.2-xml php8.2-curl php8.2-zip composer
    mysql_secure_installation
    cd /var/www && mkdir -p pterodactyl && cd pterodactyl
    curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
    tar -xzvf panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache/
    cp .env.example .env
    composer install --no-dev --optimize-autoloader
    php artisan key:generate --force
    cat <<EOF > /etc/nginx/sites-available/pterodactyl.conf
server {
    listen 80;
    server_name _;
    root /var/www/pterodactyl/public;
    index index.php;
    location / { try_files \$uri \$uri/ /index.php; }
    location ~ \.php\$ { include fastcgi_params; fastcgi_pass unix:/run/php/php8.2-fpm.sock; fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name; }
}
EOF
    ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/
    systemctl restart nginx
    systemctl enable nginx redis mariadb
    echo "✅ Pterodactyl installed!"
}

install_nebula() {
    echo "🚀 Installing Nebula Panel..."
    apt update -y && apt upgrade -y
    apt install -y software-properties-common curl apt-transport-https ca-certificates gnupg unzip git tar
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
    apt install -y nginx mariadb-server mariadb-client redis-server php8.2 php8.2-cli php8.2-gd php8.2-mysql php8.2-pdo php8.2-mbstring php8.2-tokenizer php8.2-bcmath php8.2-xml php8.2-curl php8.2-zip composer
    mysql_secure_installation
    cd /var/www && mkdir -p nebula && cd nebula
    curl -Lo nebula.tar.gz https://github.com/Nebula-Panel/panel/releases/latest/download/panel.tar.gz
    tar -xzvf nebula.tar.gz
    chmod -R 755 storage/* bootstrap/cache/
    cp .env.example .env
    composer install --no-dev --optimize-autoloader
    php artisan key:generate --force
    cat <<EOF > /etc/nginx/sites-available/nebula.conf
server {
    listen 80;
    server_name _;
    root /var/www/nebula/public;
    index index.php;
    location / { try_files \$uri \$uri/ /index.php; }
    location ~ \.php\$ { include fastcgi_params; fastcgi_pass unix:/run/php/php8.2-fpm.sock; fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name; }
}
EOF
    ln -s /etc/nginx/sites-available/nebula.conf /etc/nginx/sites-enabled/
    systemctl restart nginx
    systemctl enable nginx redis mariadb
    echo "✅ Nebula installed!"
}

install_convoy() {
    echo "🚀 Installing Convoy Panel..."
    apt update -y && apt upgrade -y
    apt install -y software-properties-common curl apt-transport-https ca-certificates gnupg unzip git tar
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
    apt install -y nginx mariadb-server mariadb-client redis-server php8.2 php8.2-cli php8.2-gd php8.2-mysql php8.2-pdo php8.2-mbstring php8.2-tokenizer php8.2-bcmath php8.2-xml php8.2-curl php8.2-zip composer
    mysql_secure_installation
    cd /var/www && mkdir -p convoy && cd convoy
    curl -Lo convoy.tar.gz https://github.com/ConvoyPanel/panel/archive/refs/heads/main.tar.gz
    tar -xzvf convoy.tar.gz --strip 1
    chmod -R 755 storage/* bootstrap/cache/
    cp .env.example .env
    composer install --no-dev --optimize-autoloader
    php artisan key:generate --force
    cat <<EOF > /etc/nginx/sites-available/convoy.conf
server {
    listen 80;
    server_name _;
    root /var/www/convoy/public;
    index index.php;
    location / { try_files \$uri \$uri/ /index.php; }
    location ~ \.php\$ { include fastcgi_params; fastcgi_pass unix:/run/php/php8.2-fpm.sock; fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name; }
}
EOF
    ln -s /etc/nginx/sites-available/convoy.conf /etc/nginx/sites-enabled/
    systemctl restart nginx
    systemctl enable nginx redis mariadb
    echo "✅ Convoy installed!"
}

install_subdomain() {
    echo "🚀 Installing Subdomain Manager..."
    apt update -y && apt install -y nginx certbot python3-certbot-nginx
    read -p "Enter Main Domain (example.com): " domain
    read -p "Enter Subdomain (panel, node, etc): " sub
    read -p "Enter Website Path (/var/www/site): " path
    mkdir -p $path
    cat <<EOF > /etc/nginx/sites-available/$sub.$domain.conf
server {
    listen 80;
    server_name $sub.$domain;
    root $path;
    index index.php index.html;
    location / { try_files \$uri \$uri/ /index.php; }
    location ~ \.php\$ { include fastcgi_params; fastcgi_pass unix:/run/php/php8.2-fpm.sock; fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name; }
}
EOF
    ln -s /etc/nginx/sites-available/$sub.$domain.conf /etc/nginx/sites-enabled/
    nginx -t && systemctl restart nginx
    certbot --nginx -d $sub.$domain --agree-tos -m admin@$domain --redirect --non-interactive
    echo "✅ Subdomain $sub.$domain created!"
}

install_discord_bot() {
    echo "🚀 Installing Discord VPS Deploy Bot..."
    apt update -y && apt install -y python3 python3-pip git
    pip install discord.py
    mkdir -p /opt/discord_bot && cd /opt/discord_bot
    cat <<BOT > discord_vps_bot.py
#!/usr/bin/env python3
import discord
from discord.ext import commands
bot = commands.Bot(command_prefix="!")
@bot.event
async def on_ready():
    print("Discord VPS Deploy Bot Online! Powered By Shadow")
@bot.command()
async def deploy(ctx):
    await ctx.send("Deploy command received! Customize deployment logic here.")
bot.run("YOUR_DISCORD_BOT_TOKEN")
BOT
    echo "✅ Discord bot installed! Edit /opt/discord_bot/discord_vps_bot.py with your bot token."
}

install_backup() {
    echo "🚀 Installing Backup Script..."
    mkdir -p /opt/panel_backup
    cat <<BK > /opt/panel_backup/backup.sh
#!/bin/bash
# Backup Script Powered By Shadow
tar -czvf /opt/panel_backup/panel_backup_\$(date +%F_%H-%M-%S).tar.gz /var/www/pterodactyl /var/www/nebula /var/www/convoy
echo "Backup completed!"
BK
    chmod +x /opt/panel_backup/backup.sh
    echo "✅ Backup script ready at /opt/panel_backup/backup.sh"
}

install_uninstall() {
    echo "🚀 Installing Uninstall Script..."
    cat <<UN > /opt/panel_uninstall.sh
#!/bin/bash
echo "⚠️ Warning! This will remove panels and configs. Powered By Shadow"
rm -rf /var/www/pterodactyl /var/www/nebula /var/www/convoy
rm -rf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-available/nebula.conf /etc/nginx/sites-available/convoy.conf
rm -rf /etc/nginx/sites-enabled/pterodactyl.conf /etc/nginx/sites-enabled/nebula.conf /etc/nginx/sites-enabled/convoy.conf
systemctl restart nginx
echo "✅ Panels removed!"
UN
    chmod +x /opt/panel_uninstall.sh
    echo "✅ Uninstall script ready at /opt/panel_uninstall.sh"
}

install_wings() {
    echo "🚀 Installing Wings / Node..."
    curl -sSL https://get.wings.sh | bash
    echo "✅ Wings installed!"
}

# ============================
# Pterodactyl Addons Sub-Menu
# ============================
addons_menu() {
    while true; do
        echo "====================================="
        echo "        Pterodactyl Addons Menu"
        echo "====================================="
        echo "1) World Manager"
        echo "2) Egg Installer"
        echo "3) Node / Wings Installer"
        echo "4) Auto Update Script"
        echo "5) Backup / Restore Addon"
        echo "6) Discord Notification"
        echo "7) Subdomain Auto Binding"
        echo "8) Back to Main Menu"
        read -p "Enter choice [1-8]: " addon_choice
        case $addon_choice in
            1) echo "Installing World Manager..." ;;
            2) echo "Installing Egg Installer..." ;;
            3) install_wings ;;
            4) echo "Installing Auto Update Script..." ;;
            5) install_backup ;;
            6) echo "Installing Discord Notification..." ;;
            7) install_subdomain ;;
            8) break ;;
            *) echo "Invalid choice!" ;;
        esac
    done
}

# ============================
# Main Menu
# ============================
while true; do
    echo "====================================="
    echo "        Powered By Shadow"
    echo "====================================="
    echo "Select an option:"
    echo "1) Pterodactyl Panel"
    echo "2) Nebula theme"
    echo "3) Convoy Panel"
    echo "4) Subdomain Manager + Auto SSL"
    echo "5) Discord VPS Deploy Bot"
    echo "6) Backup Script"
    echo "7) Uninstall Panel"
    echo "8) Wings"
    echo "9) Addons"
    echo "10) Exit"
    read -p "Enter choice [1-10]: " choice
    case $choice in
        1) install_pterodactyl ;;
        2) install_nebula ;;
        3) install_convoy ;;
        4) install_subdomain ;;
        5) install_discord_bot ;;
        6) install_backup ;;
        7) install_uninstall ;;
        8) install_wings ;;
        9) addons_menu ;;
        10) echo "Exiting... Powered By Shadow"; exit 0 ;;
        *) echo "Invalid choice!" ;;
    esac
done
