#!/bin/bash
# Instalador do PS5GPU-BC250 — sistemas tradicionais (Debian/Ubuntu, Fedora,
# Arch, etc). Copia o binario que ja vem no repositorio para /usr/bin,
# configura a execucao com root e cria o autostart.

set -euo pipefail

# Usa o diretorio do SCRIPT, nao o diretorio atual: assim da para rodar de
# qualquer lugar ("sudo bash /caminho/PS5GPU-BC250/install.sh").
DIR_ATUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BIN_NOME="ps5gpu-gui"
BIN_ORIGEM="$DIR_ATUAL/$BIN_NOME"
BIN_DESTINO="/usr/bin/$BIN_NOME"
WRAPPER="/usr/local/bin/ps5gpu-gui-autostart"
PROC_NOME="$(basename "$BIN_NOME")"


# ---------------------------------------------------------------------------
# Descobrir o usuário logado.
#
# Sob `sudo` o $HOME passa a ser /root, então usar $HOME criava o autostart em
# /root/.config/autostart — onde o desktop nunca lê, e o programa não abria
# sozinho. O home do usuário tem de vir do passwd.
# Bajo `pkexec` não existe SUDO_USER, mas existe PKEXEC_UID.
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

LOG_DESTINO="/var/log/ps5gpu-zen2booster.log"
AUTOSTART_DIR="$USER_HOME/.config/autostart"

echo "--- Iniciando Instalação de $BIN_NOME ---"
echo "    usuário: $USUARIO ($USER_HOME)"

# 1. Verifica se o binário existe ao lado do script
if [ ! -f "$BIN_ORIGEM" ]; then
    echo "❌ Erro: '$BIN_NOME' não foi encontrado em: $DIR_ATUAL"
    echo "   Certifique-se de que o script e o binário estão na mesma pasta."
    exit 1
fi

# 2. Copia para o sistema e dá permissão
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
echo "✅ Binário copiado para $BIN_DESTINO"

# 3. Wrapper de autostart.
#
#    O autostart precisa de root (a SMU exige) e roda sem terminal para pedir
#    senha, então usamos sudo sem senha. A regra do sudoers casa o comando
#    LITERAL: se o autostart chamasse
#        sudo env PS5GPU_LOG_FILE=... /usr/bin/ps5gpu-gui
#    o sudo veria "/usr/bin/env", que não está na regra, e pediria senha —
#    quebrando o autostart silenciosamente. Por isso o alvo do sudo é este
#    wrapper, que só exporta a variável e execa o binário.
sudo mkdir -p "$(dirname "$WRAPPER")"
sudo tee "$WRAPPER" > /dev/null <<EOF
#!/bin/bash
# Gerado pelo instalador do PS5GPU. Alvo do "sudo sem senha" do autostart.
export PS5GPU_LOG_FILE="$LOG_DESTINO"
exec "$BIN_DESTINO" "\$@"
EOF
sudo chmod 755 "$WRAPPER"
echo "✅ Wrapper de autostart em $WRAPPER"

# 4. Regra de sudo sem senha (binário + wrapper do autostart)
echo "$USUARIO ALL=(ALL) NOPASSWD: $BIN_DESTINO, $WRAPPER" \
    | sudo tee /etc/sudoers.d/ps5gpu-gui-nopasswd > /dev/null
sudo chmod 440 /etc/sudoers.d/ps5gpu-gui-nopasswd
echo "✅ Regra de Sudo (sem senha) configurada para $USUARIO"

# 5. Log em arquivo (o log da janela morre com ela)
sudo touch "$LOG_DESTINO"
sudo chmod 666 "$LOG_DESTINO"
echo "✅ Log da interface em $LOG_DESTINO"

# 6. Autostart (delay de 5s para a sessão gráfica e a GPU subirem)
sudo mkdir -p "$AUTOSTART_DIR"
sudo tee "$AUTOSTART_DIR/ps5gpu.desktop" > /dev/null <<EOF
[Desktop Entry]
Type=Application
Name=PS5 GPU GUI
Comment=PS5GPU — controle de GPU e CPU (Zen 2 Booster) para BC-250
Exec=sh -c "sleep 5 && sudo $WRAPPER"
Terminal=false
X-GNOME-Autostart-enabled=true
X-KDE-autostart-enabled=true
Categories=Settings;HardwareSettings;
EOF
sudo chown -R "$USUARIO:$USUARIO" "$AUTOSTART_DIR"
echo "✅ Autostart criado em $AUTOSTART_DIR/ps5gpu.desktop"

# 7. Limpa instalações antigas que ficaram no lugar errado
sudo rm -f /root/.config/autostart/ps5gpu.desktop /root/.config/autostart/ps5gpu-gui.desktop 2>/dev/null || true
if [ -f /usr/local/bin/$BIN_NOME ]; then
    sudo rm -f "/usr/local/bin/$BIN_NOME"
    echo "✅ Removida cópia antiga em /usr/local/bin"
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
echo "🚀 Instalação concluída com sucesso!"
echo "O programa iniciará sozinho nos próximos logins."
echo
echo "Para abrir agora:      sudo $BIN_DESTINO"
echo "Para ver o log:        tail -f $LOG_DESTINO"
echo "Para o ajuste de CPU no boot, marque 'Aplicar na inicialização' na aba"
echo "Zen 2 Booster, ou rode: sudo $BIN_DESTINO --install-boot"
