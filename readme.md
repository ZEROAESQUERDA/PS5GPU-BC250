# PS5GPU-BC250

### BC-250 GPU Controller based on Oberon Governor

🌎 **Languages / Idiomas / Языки**

* 🇧🇷 [Português](#português)
* 🇺🇸 [English](#english)
* 🇷🇺 [Русский](#русский)

---

# Português

## Controlador da GPU BC-250

Nova implementação baseada no **Governor Oberon**.

Todos os agradecimentos ao criador do governor original.

O objetivo deste projeto é fornecer uma forma **simples e intuitiva** de controlar o clock, tensão e comportamento térmico da GPU BC-250.

O controlador já vem **compilado e pronto para uso**, sendo necessário apenas executar o script de instalação.

---

## Instalação

Clone o repositório:

```
git clone https://github.com/ZEROAESQUERDA/PS5GPU-BC250.git
cd PS5GPU-BC250
```

### Sistemas tradicionais

```
sudo bash install.sh
```

### Sistemas imutáveis (Bazzite, Bluefin)

```
sudo bash install2.sh
```

Se a instalação ocorrer com sucesso, será exibida uma mensagem no terminal.

Depois disso **reinicie o computador**.

A interface do controlador da GPU será aberta automaticamente ao iniciar o sistema.

---

## Interface

A interface possui **3 idiomas**:

* Português
* Inglês
* Russo

### Status da GPU

No topo da interface é exibido o **status atual da GPU**.

### Controle manual

Ao ativar o modo manual, o controle da GPU passa a ser feito totalmente pelo usuário:

* Clock
* Tensão

### Controle de temperatura

**Temperatura de controle**

Temperatura em que o sistema reduzirá clock e tensão para controle térmico.

**Temperatura de recuperação**

Temperatura em que o clock voltará a subir normalmente.

Esse valor deve ser **menor que o de controle**.

### Controle automático

Permite iniciar ou parar o controle automático da GPU.

Normalmente deve permanecer **ativo**.

### Tabela OPP

Permite configurar **4 estágios automáticos de desempenho da GPU**.

---

---

## Controle da CPU — Zen 2 Booster

A interface agora tambem controla a **CPU** (Zen 2 8 núcleos / 16 threads),
alem da GPU. Tudo roda dentro do proprio binario: **nao precisa de Python,
nem de `stress`, nem de nenhum programa extra**.

A CPU nao e exposta como um CPU comum no BC-250: o controle passa pela
**SMU** (via o espaco de configuracao PCI). O binario fala com ela
diretamente, e o clock e a tensao sao controlados de verdade.

### Como usar

Abra a aba **Zen 2 Booster** e escolha o modo de controle:

* **Automatico (padrao)** — ajusta clock, tensao e temperatura conforme o
  numero de nucleos ativos. E o modo indicado para jogar.
* **Manual** — usa os valores do painel *Ajuste SMU* (frequencia, escala
  F-VID, temperatura) para todos os nucleos.
* **Avancado (por nucleo)** — configuracao individual de C0 a C7: ativo,
  clock maximo, VID maximo, temperatura e limite minimo.

### Perfis de boost

No modo **Automatico** o programa escolhe um de cinco patamares conforme a
carga:

| Núcleos ativos | Clock | VID | Temp. máx. |
|---|---|---|---|
| 1 | 3850 MHz | 1190 mV | 90 °C |
| 2 | 3800 MHz | 1160 mV | 90 °C |
| 4 | 3700 MHz | 1090 mV | 90 °C |
| 6 | 3600 MHz | 1050 mV | 90 °C |
| 8 | 3500 MHz | 1030 mV | 90 °C |

Todos os valores sao editaveis. O ajuste acontece em **cerca de 1 segundo**
depois que a carga muda.

> A medicao real neste aparelho: ir de 3850 para 3500 MHz deixa o
> desempenho **10,0%** menor e a tensao cai de **1168 mV para 999 mV** — ou
> seja, os perfis valem a pena.

### Agilidade da troca

No painel *Sensores e limites* ha o campo **Agilidade da troca** (100 a
2000 ms, padrao 500 ms). Menor = reage mais rapido e troca mais vezes.
Maior = mais estavel. Se o log mostrar trocas demais, suba para 800–1000 ms.

### Detectar overclock estavel

O botao **Detectar OC estavel** faz um teste de verdade, com carga gerada
internamente (sem o pacote `stress`): aplica o clock, mede a tensao real,
aumenta o undervolt se preciso, verifica se ha *throttling* e sobe o clock
enquanto estiver estavel. Pode ser interrompido com **Parar**.

### Aplicar na inicializacao

**Nao e preciso apertar nada ao abrir.** A interface aplica sozinha o
configuracao guardada: no modo Automatico ela comeca no perfil mais seguro
(8 nucleos) e vai refinando conforme a carga.

Para a configuracao valer **depois de um reboot**, marque a caixa
**Aplicar na inicializacao** (no painel *Linux CPU*). Isso grava o estado em
`/etc/ps5gpu-zen2booster.conf` e habilita o servico
`ps5gpu-zen2booster.service`, que aplica tudo no boot, sem abrir a janela.

Para conferir ou desfazer:

```
systemctl status ps5gpu-zen2booster.service
sudo ps5gpu-gui --install-boot      # instala
sudo ps5gpu-gui --uninstall-boot    # remove
```

### Quando o root é necessário

A SMU e os arquivos de `sysfs` exigem privilegios. **A interface precisa ser
aberta como root** (os instaladores ja configuram isso). Sem root ela abre
normal, mostra as leituras e avisa que o controle esta indisponivel — e tenta
de novo sozinho a cada 5 segundos.

### Limite importante do modo Avancado

A curva de tensao da SMU e **global** (um valor so para o pacote inteiro).
Se voce colocar VIDs diferentes por nucleo, o programa aplica a tensao mais
conservadora para que nenhum nucleo passe do seu alvo, e avisa no log.
Apenas o **clock** e realmente individual por nucleo.

---

## Comandos básicos

Mostrar interface gráfica

```
sudo ps5gpu-gui
```

Verificar se o controlador está rodando

```
pgrep -fl ps5gpu-gui
```

---

## Observações

Remova ou desative **outros controladores de GPU** para evitar conflitos.

---

## Desinstalação

### Sistemas tradicionais

```
sudo rm /usr/bin/ps5gpu-gui
sudo rm /etc/sudoers.d/ps5gpu-gui-nopasswd
rm ~/.config/autostart/ps5gpu.desktop
```

### Sistemas imutáveis

```
sudo rm /usr/local/bin/ps5gpu-gui
sudo rm /etc/sudoers.d/ps5gpu-gui-nopasswd
rm ~/.config/autostart/ps5gpu.desktop
```

---

## FAQ

### Por que não há controle de 350-2230 MHz+?

A maioria dos sistemas não possui essa tabela de frequência por padrão.

Adicionar poderia causar instabilidade.

Uma versão futura pode incluir isso.

---

### Problemas no Bazzite?

O desenvolvimento foi testado principalmente em **CachyOS**.

Sistemas como **Bazzite no modo Deck** podem precisar de ajustes.

---

## Metas

* Controle de **CPU + GPU na mesma interface** — entregue pela aba Zen 2 Booster
* Plugin para **modo Steam Deck (Bazzite)**

---

# English

## BC-250 GPU Controller

New implementation based on the **Oberon Governor**.

Thanks to the creator of the original governor.

This project aims to provide a **simple and intuitive way** to control GPU clock, voltage and thermal behavior for the BC-250 GPU.

The controller comes **precompiled and ready to use**.

---

## Installation

Clone the repository

```
git clone https://github.com/ZEROAESQUERDA/PS5GPU-BC250.git
cd PS5GPU-BC250
```

### Traditional systems

```
sudo bash install.sh
```

### Immutable systems (Bazzite / Bluefin)

```
sudo bash install2.sh
```

Reboot your computer after installation.

The GPU controller interface will start automatically.

---

## Interface

The interface supports **three languages**

* Portuguese
* English
* Russian

Features include:

* GPU status monitoring
* Manual control mode
* Thermal control system
* Automatic GPU management
* OPP performance table

---

---

## CPU control — Zen 2 Booster

The interface now also controls the **CPU** (Zen 2, 8 cores / 16 threads), on
top of the GPU. Everything runs inside the binary itself: **no Python, no
`stress`, no extra programs**.

The CPU is not exposed as a regular CPU on the BC-250: control goes through
the **SMU** (via the PCI config space). The binary talks to it directly, and
clock and voltage are really controlled.

### How to use

Open the **Zen 2 Booster** tab and pick the control mode:

* **Automatic (default)** — adjusts clock, voltage and temperature from the
  number of active cores. This is the mode to use for gaming.
* **Manual** — uses the *SMU tuning* values (frequency, F-VID scale,
  temperature) for all cores.
* **Advanced (per core)** — per-core setup for C0 to C7: enabled, max clock,
  max VID, temperature and minimum limit.

### Boost profiles

In **Automatic** mode the program picks one of five steps based on load:

| Active cores | Clock | VID | Max temp |
|---|---|---|---|
| 1 | 3850 MHz | 1190 mV | 90 °C |
| 2 | 3800 MHz | 1160 mV | 90 °C |
| 4 | 3700 MHz | 1090 mV | 90 °C |
| 6 | 3600 MHz | 1050 mV | 90 °C |
| 8 | 3500 MHz | 1030 mV | 90 °C |

Every value is editable. The change happens about **1 second** after the load
changes.

> Measured on this unit: going from 3850 to 3500 MHz makes performance
> **10.0%** lower and voltage drops from **1168 mV to 999 mV** — the profiles
> are worth using.

### Response agility

The *Sensors and limits* panel has a **Response agility** field (100 to
2000 ms, default 500 ms). Lower reacts faster and switches more often; higher
is steadier. If the log shows too many switches, raise it to 800–1000 ms.

### Detect stable overclock

The **Detect stable OC** button runs a real test with internally generated
load (no `stress` package needed): it applies the clock, measures the real
voltage, increases undervolt if needed, checks for throttling and raises the
clock while stable. Press **Stop** to interrupt it.

### Apply at boot

**You do not need to press anything on open.** The interface applies the
saved configuration by itself: in Automatic mode it starts from the safest
profile (8 cores) and refines as load changes.

To make the configuration survive a **reboot**, tick **Apply at boot** (in
the *Linux CPU* panel). It writes the state to
`/etc/ps5gpu-zen2booster.conf` and enables the
`ps5gpu-zen2booster.service` service, which applies everything at boot with
no window.

To check or undo:

```
systemctl status ps5gpu-zen2booster.service
sudo ps5gpu-gui --install-boot      # install
sudo ps5gpu-gui --uninstall-boot    # remove
```

### When root is needed

The SMU and the `sysfs` files require privileges. **The interface must be
opened as root** (the installers already set this up). Without root it opens
normally, shows the readings and warns that control is unavailable — then
retries on its own every 5 seconds.

### Important limit of Advanced mode

The SMU voltage curve is **global** (one single value for the whole
package). If you set different VIDs per core, the program applies the most
conservative scale so no core exceeds its target, and warns in the log. Only
the **clock** is truly per core.

---

## Basic commands

Open GUI

```
sudo ps5gpu-gui
```

Check if controller is running

```
pgrep -fl ps5gpu-gui
```

---

## Uninstall

Traditional systems

```
sudo rm /usr/bin/ps5gpu-gui
sudo rm /etc/sudoers.d/ps5gpu-gui-nopasswd
rm ~/.config/autostart/ps5gpu.desktop
```

Immutable systems

```
sudo rm /usr/local/bin/ps5gpu-gui
sudo rm /etc/sudoers.d/ps5gpu-gui-nopasswd
rm ~/.config/autostart/ps5gpu.desktop
```

---

# Русский

## Контроллер GPU для BC-250

Новая реализация на основе **Oberon Governor**.

Цель проекта — предоставить **простое и удобное управление GPU**:

* частота
* напряжение
* температурный контроль

Контроллер уже **скомпилирован и готов к использованию**.

---

## Установка

Клонируйте репозиторий

```
git clone https://github.com/ZEROAESQUERDA/PS5GPU-BC250.git
cd PS5GPU-BC250
```

Обычные системы

```
sudo bash install.sh
```

Неизменяемые системы (Bazzite)

```
sudo bash install2.sh
```

После установки **перезагрузите систему**.

---

---

## Управление CPU — Zen 2 Booster

Теперь интерфейс управляет не только GPU, но и **CPU** (Zen 2, 8 ядер / 16
потоков). Всё работает внутри самого бинарника: **не нужен ни Python, ни
`stress`, ни какие-либо сторонние программы**.

На BC-250 CPU не выглядит как обычный CPU: управление идёт через **SMU**
(через конфигурационное пространство PCI). Бинарник обращается к ней
напрямую, и частота с напряжением действительно управляются.

### Как пользоваться

Откройте вкладку **Zen 2 Booster** и выберите режим управления:

* **Автоматический (по умолчанию)** — подбирает частоту, напряжение и
  температуру по числу активных ядер. Это режим для игр.
* **Вручную** — использует значения панели *Настройка SMU* (частота, шкала
  F-VID, температура) для всех ядер.
* **Продвинутый (по ядрам)** — настройка каждого ядра C0…C7: включено,
  максимальная частота, максимальный VID, температура и минимальный предел.

### Профили boost

В режиме **Автоматический** программа выбирает один из пяти уровней по
нагрузке:

| Активных ядер | Частота | VID | Макс. t° |
|---|---|---|---|
| 1 | 3850 МГц | 1190 мВ | 90 °C |
| 2 | 3800 МГц | 1160 мВ | 90 °C |
| 4 | 3700 МГц | 1090 мВ | 90 °C |
| 6 | 3600 МГц | 1050 мВ | 90 °C |
| 8 | 3500 МГц | 1030 мВ | 90 °C |

Все значения редактируются. Переключение происходит примерно за **1
секунду** после изменения нагрузки.

> Замерено на этом аппарате: переход с 3850 на 3500 МГц снижает
> производительность на **10,0 %**, а напряжение падает с **1168 мВ до
> 999 мВ** — профили действительно работают.

### Агильность отклика

В панели *Датчики и лимиты* есть поле **Агильность отклика** (100–2000 мс,
по умолчанию 500 мс). Меньше — быстрее реакция и больше переключений.
Больше — стабильнее. Если в журнале слишком много переключений, поставьте
800–1000 мс.

### Поиск стабильного разгона

Кнопка **Найти стабильный OC** проводит настоящий тест с нагрузкой,
создаваемой внутри программы (пакет `stress` не нужен): применяет частоту,
измеряет реальное напряжение, добавляет андерволт при необходимости,
проверяет троттлинг и повышает частоту, пока стабильно. Можно прервать
кнопкой **Стоп**.

### Применять при загрузке

**Ничего нажимать при открытии не нужно.** Интерфейс сам применяет
сохранённую конфигурацию: в автоматическом режиме стартует с самого
безопасного профиля (8 ядер) и дальше подстраивается по нагрузке.

Чтобы конфигурация сохранялась **после перезагрузки**, поставьте галочку
**Применять при загрузке** (панель *Linux CPU*). Состояние записывается в
`/etc/ps5gpu-zen2booster.conf` и включается служба
`ps5gpu-zen2booster.service`, которая применяет всё при старте без окна.

Проверка и отмена:

```
systemctl status ps5gpu-zen2booster.service
sudo ps5gpu-gui --install-boot      # установить
sudo ps5gpu-gui --uninstall-boot    # удалить
```

### Когда нужен root

SMU и файлы `sysfs` требуют привилегий. **Интерфейс нужно открывать от
root** (установщики это уже настраивают). Без root он откроется, покажет
показания и предупредит, что управление недоступно, а затем будет
пробовать снова каждые 5 секунд.

### Важное ограничение продвинутого режима

Кривая напряжения SMU **глобальная** (одно значение на весь пакет). Если
задать разные VID для разных ядер, программа применит самый
консервативный масштаб, чтобы ни одно ядро не превысило свой предел, и
предупредит в журнале. По-настоящему индивидуальна только **частота**.

---

## Основные команды

Открыть интерфейс

```
sudo ps5gpu-gui
```

Проверить процесс

```
pgrep -fl ps5gpu-gui
```

---

## Цели проекта

* объединить управление **CPU и GPU**
* создать **плагин для Steam Deck / Bazzite**

---

⭐ Contributions and feedback are welcome.
