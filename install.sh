#!/bin/bash

# 1. Identifica a pasta onde o script está sendo executado
DIR_ATUAL=$(pwd)
BIN_NOME="ps5gpu-gui"
BIN_ORIGEM="$DIR_ATUAL/$BIN_NOME"
BIN_DESTINO="/usr/bin/$BIN_NOME"
USUARIO=$(logname)

echo "--- Iniciando Instalação de $BIN_NOME ---"

# 2. Verifica se o binário realmente existe na pasta atual
if [ ! -f "$BIN_ORIGEM" ]; then
    echo "❌ Erro: O arquivo '$BIN_NOME' não foi encontrado em: $DIR_ATUAL"
    echo "Certifique-se de que o script e o binário estão na mesma pasta."
    exit 1
fi

# 3. Copia para o sistema e dá permissão
sudo cp "$BIN_ORIGEM" "$BIN_DESTINO"
sudo chmod +x "$BIN_DESTINO"
echo "✅ Binário copiado para $BIN_DESTINO"

# 4. Configura sudo sem senha para este binário
echo "$USUARIO ALL=(ALL) NOPASSWD: $BIN_DESTINO" | sudo tee /etc/sudoers.d/ps5gpu-gui-nopasswd > /dev/null
echo "✅ Regra de Sudo (sem senha) configurada para $USUARIO"

# 5. Cria o Autostart (com delay de 5s para carregar a interface)
mkdir -p /home/$USUARIO/.config/autostart
cat <<EOF > /home/$USUARIO/.config/autostart/ps5gpu.desktop
[Desktop Entry]
Type=Application
Name=PS5 GPU GUI
Exec=sh -c "sleep 5 && sudo $BIN_DESTINO"
Terminal=false
X-GNOME-Autostart-enabled=true
Categories=Settings;HardwareSettings;
EOF

# Ajusta o dono do arquivo de autostart (já que o sudo cria como root)
chown $USUARIO:$USUARIO /home/$USUARIO/.config/autostart/ps5gpu.desktop

echo "-------------------------------------------"
echo "🚀 Instalação concluída com sucesso!"
echo "O programa iniciará sozinho nos próximos logins."
