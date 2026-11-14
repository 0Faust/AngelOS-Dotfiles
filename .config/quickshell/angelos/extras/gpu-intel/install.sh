#!/usr/bin/env bash
set -euo pipefail
[[ $EUID == 0 ]] || { echo 'Run this installer with sudo.' >&2; exit 1; }
dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
pacman -S --needed --noconfirm intel-gpu-tools
install -D -m 0755 "$dir/gpu-intel-helper.py" /usr/local/lib/angelos/gpu-intel-helper.py
install -D -m 0644 "$dir/angelos-gpu-intel.service" /etc/systemd/system/angelos-gpu-intel.service
systemctl daemon-reload
systemctl enable angelos-gpu-intel.service
systemctl restart angelos-gpu-intel.service
