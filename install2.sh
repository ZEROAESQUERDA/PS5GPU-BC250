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
PROC_NOME="$(basename "$BIN_NOME")"


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
# ---------------------------------------------------------------------------
# Se o programa estiver rodando, o destino fica "ocupado" e o cp falha com
# "Text file busy" (em pt-BR: "Área de texto ocupada"). Numa reinstalação isso
# sempre acontece, porque o autostart deixou o programa aberto. Então paramos
# antes de copiar e religamos no final (com o wrapper, que já tem o log).
# ---------------------------------------------------------------------------
RODAVA=0
if pgrep -x "$PROC_NOME" > /dev/null 2>&1; then
    RODAVA=1
    echo "ℹ️  O programa está em execução; será reiniciado para atualizar."
    pkill -x "$PROC_NOME" 2> /dev/null || true
    for _ in $(seq 1 20); do
        pgrep -x "$PROC_NOME" > /dev/null 2>&1 || break
        sleep 0.5
    done
    if pgrep -x "$PROC_NOME" > /dev/null 2>&1; then
        echo "   não encerrou no pedido normal; forçando…"
        pkill -9 -x "$PROC_NOME" 2> /dev/null || true
        sleep 1
    fi
    if pgrep -x "$PROC_NOME" > /dev/null 2>&1; then
        echo "❌ Erro: não consegui encerrar '$PROC_NOME'."
        echo "   Feche o programa (sudo pkill -9 -x $PROC_NOME) e tente de novo."
        exit 1
    fi
    echo "✅ Programa anterior encerrado"
fi

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

# ---------------------------------------------------------------------------
# Remove atalhos e launchers do PROJETO ANTIGO.
#
# Eles abriam uma janela de terminal (konsole) com o debug do programa e sem
# root -- logo, sem controle de CPU. Pior: essa instancia sem root ficava com
# o socket de instancia unica e a instancia COM root do autostart saia em
# silencio, entao o usuario via a janela, mas os controles de CPU cinza.
# ---------------------------------------------------------------------------
for _antigo in \
    "$USER_HOME/.local/share/applications/ps5gpu-gui.desktop" \
    "$USER_HOME/.local/share/applications/ps5gpudriver-gui.desktop" \
    "/usr/share/applications/ps5gpu-gui.desktop" \
    "/usr/share/applications/ps5gpudriver-gui.desktop" \
    "/usr/bin/ps5gpu-gui-launcher" \
    "/usr/local/bin/ps5gpu-gui-launcher" \
    "/usr/bin/ps5gpudriver-gui"; do
    if [ -e "$_antigo" ]; then
        rm -f "$_antigo"
        echo "✅ Removido resquício antigo: $_antigo"
    fi
done

sudo tee "/usr/share/applications/ps5gpu-gui.desktop" > /dev/null <<EOF
[Desktop Entry]
Type=Application
Name=PS5GPU
Comment=Controle de GPU e CPU (Zen 2 Booster) para AMD BC-250
Exec=pkexec $BIN_DESTINO
Icon=ps5gpu-gui
Terminal=false
Categories=Utility;System;
EOF

# 7. Limpa instalações antigas no lugar errado
sudo rm -f /root/.config/autostart/ps5gpu.desktop /root/.config/autostart/ps5gpu-gui.desktop 2>/dev/null || true
if [ -f /usr/bin/$BIN_NOME ]; then
    sudo rm -f "/usr/bin/$BIN_NOME" 2>/dev/null \
        && echo "✅ Removida cópia antiga em /usr/bin" || true
fi

# Religa o programa, se ele estava rodando antes da instalação.
# Só tentou se houver sessão gráfica alcançável: sem DISPLAY/WAYLAND/DBus o Qt
# aborta ao tentar abrir a janela, e um crash durante a instalação é pior do
# que o programa ficar fechado (o autostart abre no próximo login de qualquer
# forma).
if [ "$RODAVA" = 1 ]; then
    TEM_SESSAO=0
    if [ -n "${WAYLAND_DISPLAY:-}" ] && [ -S "${XDG_RUNTIME_DIR:-/nao-existe}/$WAYLAND_DISPLAY" ]; then
        TEM_SESSAO=1
    elif [ -z "${WAYLAND_DISPLAY:-}" ] && [ -n "${DISPLAY:-}" ]; then
        TEM_SESSAO=1
    fi

    if [ "$TEM_SESSAO" = 1 ]; then
        setsid env \
            HOME="$USER_HOME" \
            DISPLAY="${DISPLAY:-}" \
            WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}" \
            XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-}" \
            XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-}" \
            XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-}" \
            DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-}" \
            "$WRAPPER" > /dev/null 2>&1 &
        sleep 3
        if pgrep -x "$PROC_NOME" > /dev/null 2>&1; then
            echo "✅ Programa reiniciado com a versão nova"
        else
            echo "⚠️  Não reiniciou sozinho. Abra com: sudo $BIN_DESTINO"
        fi
    else
        echo "ℹ️  Sem sessão gráfica neste terminal; o programa não foi reaberto."
        echo "   Abra com: sudo $BIN_DESTINO   (ou aguarde o próximo login)"
    fi
fi

echo "-------------------------------------------"
echo "🚀 Instalação concluída no Bazzite/Imutável!"
echo "Nota: o delay é de 8s para garantir o carregamento do driver."
echo
echo "Para abrir agora:      sudo $BIN_DESTINO"
echo "Para ver o log:        tail -f $LOG_DESTINO"
echo "O ajuste de CPU no boot depende de conseguir escrever em /etc;"
echo "se não for possível, a interface aplica a configuração ao abrir."
