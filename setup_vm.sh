#!/bin/bash
# Script para ejecutar DENTRO de la VM Ubuntu de AWS (EC2).
# Uso:  bash setup_vm.sh
set -e
DH_USER="${1:-cadrojasl}"

# 1. Instalar Docker (https://docs.docker.com/engine/install/ubuntu/)
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 2. Habilitar al usuario 'ubuntu' para ejecutar contenedores
sudo usermod -aG docker ubuntu

# 3. Descargar y ejecutar el contenedor (puerto 80 de la VM -> 5000 del contenedor)
sudo docker run -d --restart unless-stopped --name stock-market -p 80:5000 "$DH_USER/stock-market:2.0"

echo "Listo. Abre http://<Public IPv4 DNS de la instancia> en el navegador."
