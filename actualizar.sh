#!/bin/bash

echo "📦 1. Actualizando paquetes de Ubuntu (APT)..."
sudo apt update && sudo apt full-upgrade -y
sudo apt autoremove -y && sudo apt autoclean

echo "📦 2. Actualizando paquetes Snap..."
sudo snap refresh

echo "📦 3. Actualizando paquetes Flatpak..."
flatpak update -y

echo "🖋️ 4. Actualizando Firmador..."
sudo firmador --update

echo "🤖 5. Actualizando OpenCode..."
su - cmc -c "/home/cmc/.opencode/bin/opencode upgrade"

#echo "🐍 6. Actualizando herramientas de Python (pipx / uv)..."
#su - cmc -c "pipx upgrade-all"

#echo "🦙 7. Actualizando Ollama..."
#curl -fsSL https://ollama.com/install.sh | sh

echo "⚙️ 8. Buscando actualizaciones de Firmware (Hardware)..."
sudo fwupdmgr refresh && sudo fwupdmgr update -y

echo "✅ ¡Todo el sistema y software independiente están actualizados!"
