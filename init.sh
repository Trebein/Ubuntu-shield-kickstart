#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Пожалуйста, запустите скрипт с правами root."
  exit 1
fi

echo "Начинаем базовую настройку и защиту сервера..."

echo "[1/5] Обновление системы и установка утилит (nano, curl, ufw)..."
apt update && apt upgrade -y
apt install -y nano curl ufw

echo "[2/5] Создание безопасного пользователя..."
NEW_USER="admin_$(openssl rand -hex 3)"
NEW_PASS=$(openssl rand -base64 12)
NEW_PORT=$(shuf -i 10000-60000 -n 1)
SERVER_IP=$(curl -s ifconfig.me)

useradd -m -s /bin/bash "$NEW_USER"
echo "$NEW_USER:$NEW_PASS" | chpasswd
usermod -aG sudo "$NEW_USER"

echo "[3/5] Настройка SSH (Новый порт: $NEW_PORT)..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sed -i -E "s/^#?Port [0-9]+/Port $NEW_PORT/" /etc/ssh/sshd_config
sed -i -E "s/^#?PermitRootLogin (yes|prohibit-password)/PermitRootLogin no/" /etc/ssh/sshd_config

echo "[4/5] Настройка фаервола (UFW)..."
# Включаем ufw, если он был выключен (force, чтобы не спрашивал 'y')
ufw --force enable >/dev/null 2>&1
ufw allow $NEW_PORT/tcp >/dev/null 2>&1
ufw delete allow 22/tcp >/dev/null 2>&1
ufw delete allow OpenSSH >/dev/null 2>&1

echo "[5/5] Применение настроек..."
systemctl restart sshd

echo ""
echo "========================================================="
echo "СЕРВЕР УСПЕШНО ОБНОВЛЕН И ЗАЩИЩЕН!"
echo "ОБЯЗАТЕЛЬНО СКОПИРУЙТЕ ЭТИ ДАННЫЕ ПРЯМО СЕЙЧАС"
echo "---------------------------------------------------------"
echo "IP сервера:     $SERVER_IP"
echo "Пользователь:   $NEW_USER"
echo "Пароль:         $NEW_PASS"
echo "Новый SSH порт: $NEW_PORT"
echo "---------------------------------------------------------"
echo "Готовая команда для подключения из терминала:"
echo "ssh $NEW_USER@$SERVER_IP -p $NEW_PORT"
echo "========================================================="
