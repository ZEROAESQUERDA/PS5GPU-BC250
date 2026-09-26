#!/bin/bash
# Instalador do PS5GPU-BC250 — sistemas tradicionais (Debian/Ubuntu, Fedora,
# Arch, etc). Copia o binario que ja vem no repositorio para /usr/bin,
# configura a execucao com root e cria o autostart.

set -euo pipefail

# IMPORTANTE: usa o diretorio do SCRIPT, nao o diretorio atual. Assim da para
# rodar de qualquer lugar ("sudo bash /caminho/PS5GPU-BC250/install.sh").
DIR_ATUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BIN_NOME="ps5gpu-gui"
BIN_ORIGEM="$DIR_ATUAL/$BIN_NOME"
BIN_DESTINO="/usr/bin/$BIN_NOME"
LOG_DESTINO="/var/log/ps5gpu-zen2booster.log"
USUARIO="${SUDO_USER:-${USER:-$(logname 2>/dev/null || echo root)}}"
AUTOSTART_DIR="$HOME/.config/autostart"

echo "--- Iniciando Instalação de $BIN_NOME ---"

# 1. Verifica se o binario existe ao lado do script
if [ ! -f "$BIN_ORIGEM" ]; then
    echo "❌ Erro: '$BIN_NOME' não foi encontrado em: $DIR_ATUAL"
    echo "   Certifique-se de que o script e o binário estão na mesma pasta."
    exit 1
fi

# 2. Copia para o sistema e dá permissão
sudo cp "$BIN_ORIGEM" "$BIN_DESTINO"
sudo chmod +x "$BIN_DESTINO"
echo "✅ Binário copiado para $BIN_DESTINO"

# 3. Regra de sudo sem senha para este binário
#    A SMU e o sysfs exigem root, e o autostart roda em background sem
#    terminal para pedir a senha.
echo "$USUARIO ALL=(ALL) NOPASSWD: $BIN_DESTINO" \
    | sudo tee /etc/sudoers.d/ps5gpu-gui-nopasswd > /dev/null
sudo chmod 440 /etc/sudoers.d/ps5gpu-gui-nopasswd
echo "✅ Regra de Sudo (sem senha) configurada para $USUARIO"

# 4. Log em arquivo (o log da janela morre com ela)
sudo touch "$LOG_DESTINO"
sudo chmod 666 "$LOG_DESTINO"
echo "✅ Log da interface em $LOG_DESTINO"

# 5. Autostart (delay de 5s para a sessão gráfica e a GPU subirem)
mkdir -p "$AUTOSTART_DIR"
cat <<EOF > "$AUTOSTART_DIR/ps5gpu.desktop"
[Desktop Entry]
Type=Application
Name=PS5 GPU GUI
Comment=PS5GPU — controle de GPU e CPU (Zen 2 Booster) para BC-250
Exec=sh -c "sleep 5 && sudo env PS5GPU_LOG_FILE=$LOG_DESTINO $BIN_DESTINO"
Terminal=false
X-GNOME-Autostart-enabled=true
Categories=Settings;HardwareSettings;
EOF
chown -R "$USUARIO:$USUARIO" "$AUTOSTART_DIR" 2>/dev/null || true
echo "✅ Autostart criado em $AUTOSTART_DIR/ps5gpu.desktop"

# 6. Limpa uma instalação antiga feita em /usr/local
if [ -f /usr/local/bin/$BIN_NOME ]; then
    sudo rm -f /usr/local/bin/$BIN_NOME
    echo "✅ Removida cópia antiga em /usr/local/bin"
fi

echo "-------------------------------------------"
echo "🚀 Instalação concluída com sucesso!"
echo "O programa iniciará sozinho nos próximos logins."
echo
echo "Para abrir agora:            sudo $BIN_DESTINO"
echo "Para o ajuste de CPU no boot, marque 'Aplicar na inicialização'"
echo "na aba Zen 2 Booster, ou rode:"
echo "  sudo $BIN_DESTINO --install-boot"
