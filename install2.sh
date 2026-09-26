#!/bin/bash
# Instalador do PS5GPU-BC250 — sistemas IMUTÁVEIS (Bazzite, Bluefin,
# Silverblue, Fedora Atomic). Nesse caso /usr é somente-leitura, então o
# binário vai para /usr/local/bin.

set -euo pipefail

# Usa o diretório do SCRIPT (não o atual), para poder rodar de qualquer lugar.
DIR_ATUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BIN_NOME="ps5gpu-gui"
BIN_ORIGEM="$DIR_ATUAL/$BIN_NOME"
# Em distros imutáveis /usr/local/bin é o caminho persistente e editável.
BIN_DESTINO="/usr/local/bin/$BIN_NOME"
WRAPPER="/usr/local/bin/ps5gpu-gui-autostart"

# ---------------------------------------------------------------------------
# Descobrir o usuário logado. Sob `sudo` o $HOME vira /root (o que criava o
# autostart no lugar errado); sob `pkexec` não há SUDO_USER, mas há PKEXEC_UID.
# ---------------------------------------------------------------------------
USUARIO="${SUDO_USER:-}"
if [ -z "$USUARIO" ] && [ -n "${PKEXEC_UID:-}" ]; then
    USUARIO="$(getent passwd "$PKEXEC_UID" | cut -d: -f1)"
fi
if [ -z "$USUARIO" ] || [ "$USUARIO" = root ]; then
    USUARIO="${USER:-}"
fi
if [ -z "$USUARIO" ] || [ "$USUARIO" = root ]; then
    USUARIO="$(logname 2>/dev/null || echo root)"
fi
USER_HOME="$(getent passwd "$USUARIO" | cut -d: -f6)"
[ -z "$USER_HOME" ] && USER_HOME="/home/$USUARIO"

LOG_DESTINO="$USER_HOME/.cache/ps5gpu-zen2booster.log"
AUTOSTART_DIR="$USER_HOME/.config/autostart"

echo "--- Iniciando Instalação para Sistema Imutável ---"
echo "    usuário: $USUARIO ($USER_HOME)"

# 1. Verifica se o binário existe ao lado do script
if [ ! -f "$BIN_ORIGEM" ]; then
    echo "❌ Erro: '$BIN_NOME' não foi encontrado em: $DIR_ATUAL"
    exit 1
fi

# 2. Copia para o destino persistente e dá permissão
sudo cp "$BIN_ORIGEM" "$BIN_DESTINO"
sudo chmod +x "$BIN_DESTINO"
echo "✅ Binário copiado para $BIN_DESTINO (caminho persistente)"

# 3. Wrapper de autostart. A regra do sudoers casa o comando literal, então o
#    alvo do "sudo sem senha" precisa ser este wrapper — e não
#    "sudo env VAR=... /usr/local/bin/ps5gpu-gui", que pediria senha.
sudo tee "$WRAPPER" > /dev/null <<EOF
#!/bin/bash
# Gerado pelo instalador do PS5GPU. Alvo do "sudo sem senha" do autostart.
export PS5GPU_LOG_FILE="$LOG_DESTINO"
exec "$BIN_DESTINO" "\$@"
EOF
sudo chmod 755 "$WRAPPER"
echo "✅ Wrapper de autostart em $WRAPPER"

# 4. Regra de sudo sem senha (o /etc costuma ser editável em distros imutáveis)
echo "$USUARIO ALL=(ALL) NOPASSWD: $BIN_DESTINO, $WRAPPER" \
    | sudo tee /etc/sudoers.d/ps5gpu-gui-nopasswd > /dev/null
sudo chmod 440 /etc/sudoers.d/ps5gpu-gui-nopasswd
echo "✅ Regra de Sudo configurada para $USUARIO"

# 5. Log em arquivo, dentro do home (o /var pode não ser gravável)
mkdir -p "$(dirname "$LOG_DESTINO")"
touch "$LOG_DESTINO"
echo "✅ Log da interface em $LOG_DESTINO"

# 6. Autostart. O delay é maior (8s) para o driver da GPU e a sessão
#    gráfica terminarem de subir.
mkdir -p "$AUTOSTART_DIR"
cat <<EOF > "$AUTOSTART_DIR/ps5gpu.desktop"
[Desktop Entry]
Type=Application
Name=PS5 GPU GUI
Comment=PS5GPU — controle de GPU e CPU (Zen 2 Booster) para BC-250
Exec=sh -c "sleep 8 && sudo $WRAPPER"
Terminal=false
X-GNOME-Autostart-enabled=true
X-KDE-autostart-enabled=true
Categories=Settings;HardwareSettings;
EOF
echo "✅ Autostart criado em $AUTOSTART_DIR/ps5gpu.desktop"

# 7. Limpa instalações antigas no lugar errado
sudo rm -f /root/.config/autostart/ps5gpu.desktop /root/.config/autostart/ps5gpu-gui.desktop 2>/dev/null || true
if [ -f /usr/bin/$BIN_NOME ]; then
    sudo rm -f "/usr/bin/$BIN_NOME" 2>/dev/null \
        && echo "✅ Removida cópia antiga em /usr/bin" || true
fi

echo "-------------------------------------------"
echo "🚀 Instalação concluída no Bazzite/Imutável!"
echo "Nota: o delay é de 8s para garantir o carregamento do driver."
echo
echo "Para abrir agora:      sudo $BIN_DESTINO"
echo "Para ver o log:        tail -f $LOG_DESTINO"
echo "O ajuste de CPU no boot depende de conseguir escrever em /etc;"
echo "se não for possível, a interface aplica a configuração ao abrir."
