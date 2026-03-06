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

* Controle de **CPU + GPU na mesma interface**
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
