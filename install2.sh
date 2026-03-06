#!/bin/bash

# 1. Identifica os caminhos (Adaptado para sistemas imutáveis)
DIR_ATUAL=$(pwd)
BIN_NOME="ps5gpu-gui"
BIN_ORIGEM="$DIR_ATUAL/$BIN_NOME"
# No Bazzite/SteamOS, /usr/local/bin é o caminho correto e editável
BIN_DESTINO="/usr/local/bin/$BIN_NOME"
USUARIO=$(logname)

echo "--- Iniciando Instalação para Sistema Imutável ---"

# 2. Verifica se o binário existe na pasta atual
if [ ! -f "$BIN_ORIGEM" ]; then
    echo "❌ Erro: O arquivo '$BIN_NOME' não foi encontrado em: $DIR_ATUAL"
    exit 1
fi

# 3. Copia para o destino persistente e dá permissão
# Usamos /usr/local/bin porque /usr/bin é somente-leitura nessas distros
sudo cp "$BIN_ORIGEM" "$BIN_DESTINO"
sudo chmod +x "$BIN_DESTINO"
echo "✅ Binário copiado para $BIN_DESTINO (Caminho persistente)"

# 4. Configura sudo sem senha (O /etc costuma ser editável em distros imutáveis)
echo "$USUARIO ALL=(ALL) NOPASSWD: $BIN_DESTINO" | sudo tee /etc/sudoers.d/ps5gpu-gui-nopasswd > /dev/null
echo "✅ Regra de Sudo configurada para $USUARIO"

# 5. Cria o Autostart na Home do usuário (Sempre editável)
mkdir -p /home/$USUARIO/.config/autostart
cat <<EOF > /home/$USUARIO/.config/autostart/ps5gpu.desktop
[Desktop Entry]
Type=Application
Name=PS5 GPU GUI
Exec=sh -c "sleep 8 && sudo $BIN_DESTINO"
Terminal=false
X-GNOME-Autostart-enabled=true
Categories=Settings;HardwareSettings;
EOF

# Ajusta o dono do arquivo criado pelo sudo
chown $USUARIO:$USUARIO /home/$USUARIO/.config/autostart/ps5gpu.desktop

echo "-------------------------------------------"
echo "🚀 Instalação concluída no Bazzite/Imutável!"
echo "Nota: O delay foi aumentado para 8s para garantir o carregamento do driver."
