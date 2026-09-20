# CachyOS Cleaner

Aplicativo gráfico para gerenciamento e limpeza de caches no Linux, desenvolvido com **Python**, **PySide6** e **Qt**, distribuído como **AppImage**.

Repositório: https://github.com/FernandoGabrielSilva/cachyos-cleaner

`Linux` • `Python` • `PySide6` • `Qt` • `AppImage`

---

## 📋 Índice

- [Sobre o projeto](#-sobre-o-projeto)
- [🧹 O que o programa limpa?](#-o-que-o-programa-limpa)
- [🗂️ Categorias](#️-categorias)
- [🔴 Protegidos](#-protegidos)
- [🛡️ Segurança](#️-segurança)
- [🖥️ Interface](#️-interface)
- [📦 Estrutura do projeto](#-estrutura-do-projeto)
- [🔨 Compilação](#-compilação)
- [🚀 Compilando](#-compilando)
- [▶️ Executando](#️-executando)
- [🔧 Executando sem FUSE](#-executando-sem-fuse)
- [📦 O que existe dentro do AppImage?](#-o-que-existe-dentro-do-appimage)
- [🐍 Tecnologias utilizadas](#-tecnologias-utilizadas)
- [🐧 Suporte a distribuições Linux](#-suporte-a-distribuições-linux)
- [🚫 O que o programa NÃO faz](#-o-que-o-programa-não-faz)
- [🔐 Links simbólicos](#-links-simbólicos)
- [🧪 Desenvolvimento](#-desenvolvimento)
- [🏗️ Processo de distribuição](#️-processo-de-distribuição)
- [🖥️ Compatibilidade](#️-compatibilidade)
- [⚠️ Considerações importantes](#️-considerações-importantes)
- [🐛 Solução de problemas](#-solução-de-problemas)
- [📋 Status do projeto](#-status-do-projeto)
- [🔮 Possíveis melhorias futuras](#-possíveis-melhorias-futuras)
- [🤝 Contribuição](#-contribuição)
- [📄 Licença](#-licença)

---

## Sobre o projeto

O CachyOS Cleaner é um aplicativo gráfico para análise e limpeza de caches, arquivos temporários, kernels antigos, logs e outros dados no Linux, com foco em CachyOS/Arch. A ferramenta não apaga nada automaticamente: ela analisa os diretórios configurados, mostra o espaço ocupado, e só remove o que o usuário selecionar e confirmar.

## 🧹 O que o programa limpa?

O programa concentra a limpeza em múltiplas categorias de caches e arquivos temporários:

### Caches de aplicativos
- Thumbnails
- Cache do Zen Browser
- Cache do Vivaldi
- Cache do Google Chrome
- Cache do Mozilla/Firefox
- Cache do Brave
- Cache do node-gyp
- Cache do VS Code (C/C++)
- Cache do Tracker3
- Cache do pip
- Cache do pnpm
- Cache do npm
- Cache do Yarn
- Cache do Dart
- Cache do Gradle
- Cache do Maven
- Cache do Cargo
- Caches do PyCharm/IntelliJ
- Cache Steam Runtime

### Caches do sistema
- Cache do pacman (`/var/cache/pacman/pkg/`)
- Cache paccache (Arch/CachyOS)
- Caches em `/var/cache/`
- Arquivos temporários (`/tmp/`, `/var/tmp/`)

### Gerenciamento de sistema
- Kernels antigos (Arch/CachyOS)
- Logs antigos (`/var/log/`)
- Arquivos grandes (varredura de `/tmp`, `/var/tmp`, `~/.cache`, `/var/cache`)

## 🗂️ Categorias

Alguns caches podem ser grandes ou conter arquivos que o usuário pode querer manter. Esses itens são apresentados separadamente na interface, para que o usuário decida se deseja removê-los. Atualmente:

- `~/.cache/codex-runtimes`
- `~/.cache/nvidia`
- `~/.cache/dart`
- `~/.cache/gradle`
- `~/.cache/maven`
- `~/.cache/cargo`
- Caches JetBrains
- Kernels antigos (Arch/CachyOS)

## 🔴 Protegidos

Alguns diretórios importantes são apenas identificados pelo programa e **não** são apagados pela limpeza automática:

- `~/.local/share/Steam` — jogos, Proton, compatdata, shader cache
- `~/.local/share/JetBrains/Toolbox` — instalações de IDEs JetBrains
- `/var/lib/flatpak` — Flatpak exige ferramentas próprias

## 🛡️ Segurança

O CachyOS Cleaner foi desenvolvido com uma abordagem conservadora. Antes de qualquer exclusão:

1. O programa analisa os diretórios configurados.
2. Calcula o espaço ocupado.
3. Apresenta os itens encontrados na interface.
4. O usuário escolhe o que deseja limpar.
5. O programa solicita confirmação.
6. Somente os itens selecionados são processados.

### Desfazer operações

Por padrão, itens enviados à **lixeira** (via `gio trash`) podem ser restaurados. Quando a lixeira não está disponível, os itens são movidos para `~/.local/share/cachyos-cleaner/undo/`, permitindo restauração manual. O histórico de limpezas (disponível no menu 📋) permite desfazer a última operação quando tecnicamente possível.

### Progresso da limpeza

Durante a limpeza, um diálogo de progresso é exibido com:
- Barra de progresso com porcentagem atual
- Nome do item sendo processado no momento
- Botão **Cancelar** que pede confirmação antes de interromper
- Indicação visual clara de que a limpeza está em andamento (a interface não trava)

Ao confirmar a limpeza, o usuário escolhe se deseja enviar os itens à **lixeira** (permite desfazer) ou **excluir permanentemente**.

### Configurações

O menu **⚙ Configurar** permite:
- **Áreas de Varredura** — ver todas as áreas escaneadas, marcar/desmarcar quais incluir na análise, adicionar áreas customizadas e remover itens
- **Exclusões** — diretórios completamente ignorados (não aparecem na interface)
- **Diretórios Ignorados** — diretórios exibidos apenas como informação, não removidos na limpeza
- **Outros** — verificação automática de atualizações e configuração de idioma

### Exclusões e diretórios ignorados

O programa permite configurar **exclusões personalizadas** (diretórios completamente ignorados) e **diretórios ignorados** (exibidos apenas como informação) no menu ⚙ Configurar.

## 🖥️ Interface

A interface gráfica é construída com **Python**, **PySide6** e **Qt**. Além da lista principal de limpeza, oferece:

- **📊 Espaço** — visualização gráfica do espaço utilizado por cada categoria (gráfico de barras interativo)
- **📋 Histórico** — histórico das limpezas realizadas com opção de desfazer
- **⚙ Configurar** — gerenciamento de exclusões, diretórios ignorados e áreas de varredura

Ao clicar em **🧹 Limpar selecionados**, uma barra de progresso é exibida mostrando:
- A porcentagem de conclusão
- O item que está sendo processado no momento
- Botão **Cancelar** com confirmação antes de interromper
- Opção de enviar à lixeira ou excluir permanentemente

## 📦 Estrutura do projeto

```
cachyos-cleaner/
├── src/
│   └── cachyos_cleaner.py
├── CachyOS-Cleaner.desktop
├── build-appimage.sh
├── README.md
├── AppDir/
│   └── (conteúdo do AppImage durante build)
└── .build-python/
    └── (ambiente Python durante build)
```

Dados persistentes (histórico, configurações): `~/.local/share/cachyos-cleaner/`

## 🔨 Compilação

O projeto possui um script automatizado, `./build-appimage.sh`:

1. Cria o ambiente Python.
2. Instala/atualiza o PySide6.
3. Identifica a versão do Python.
4. Copia o Python e bibliotecas para o AppDir.
5. Coleta dependências compartilhadas.
6. Configura o AppRun.
7. Cria Desktop Entry e ícone.
8. Gera SquashFS e AppImage final.

### Dependências para compilar

No CachyOS/Arch:

```bash
sudo pacman -S python python-pip python-virtualenv squashfs-tools curl
```

Também são utilizados: `python3`, `pip`, `venv`, `mksquashfs`, `curl` ou `wget`, e `ldd`.

> O projeto **não** depende do `appimagetool`. A imagem é construída diretamente com o runtime do AppImage e o `mksquashfs`.

## 🚀 Compilando

```bash
cd ~/Downloads/cachyos-cleaner
chmod +x build-appimage.sh
./build-appimage.sh
```

## ▶️ Executando

```bash
chmod +x CachyOS-Cleaner-x86_64.AppImage
./CachyOS-Cleaner-x86_64.AppImage
```

## 🔧 Executando sem FUSE

```bash
./CachyOS-Cleaner-x86_64.AppImage --appimage-extract-and-run
```

## 📦 O que existe dentro do AppImage?

```
CachyOS-Cleaner-x86_64.AppImage
│
├── Runtime do AppImage
│
└── SquashFS
    ├── Python
    ├── Biblioteca padrão do Python
    ├── PySide6
    ├── Shiboken6
    ├── Qt
    ├── Plugins Qt
    ├── Bibliotecas compartilhadas
    ├── CachyOS Cleaner
    ├── AppRun
    ├── Desktop Entry
    └── Ícone
```

## 🐍 Tecnologias utilizadas

- **Python** — lógica de análise, limpeza, histórico, configurações e integração com o sistema
- **PySide6** — interface gráfica baseada em Qt
- **Qt** — componentes visuais, pintura de gráficos (QPainter)
- **gio** — integração com a lixeira do sistema (trash)
- **SquashFS** — compactação do conteúdo do AppImage
- **AppImage** — distribuição como arquivo executável único

## 🐧 Suporte a outras distribuições Linux

O programa detecta automaticamente a distribuição Linux via `/etc/os-release` e ajusta seu comportamento:

### CachyOS / Arch Linux (detecção: `arch`, `cachyos`)
- Limpeza do cache paccache
- Gerenciamento de kernels (pacman -Q linux*)
- Listagem de /var/cache
- Busca de arquivos grandes
- Integração com ferramentas nativas (paccache)

### Fedora / RHEL / CentOS / Rocky (detecção: `fedora`, `rhel`, `centos`, `rocky`, `amzn`)
- Limpeza de caches de pacotes (dnf/yum)
- Gerenciamento de kernels (rpm-ostree quando aplicável)
- Logs do journald
- Arquivos temporários

### Debian / Ubuntu / Linux Mint / Pop!_OS (detecção: `debian`, `ubuntu`, `linuxmint`, `pop`)
- Limpeza de cache apt (`/var/cache/apt/archives/`)
- Gerenciamento de kernels antigos (apt autoremove)
- Logs antigos
- Arquivos temporários

### openSUSE (detecção: `opensuse`, `opensuse-tumbleweed`, `opensuse-leap`)
- Limpeza de cache zypper
- Gerenciamento de kernels
- Logs antigos
- Arquivos temporários

### Qualquer distribuição (funcionalidade universal)
- Limpeza de caches de navegadores (Chrome, Firefox, Brave, Vivaldi, etc.)
- Limpeza de caches de desenvolvimento (npm, pnpm, yarn, pip, cargo, etc.)
- Arquivos temporários do sistema
- Thumbnails
- Links simbólicos (proteção)
- Histórico de limpezas
- Exclusões personalizadas

> Os pacotes de cache específicos de cada distro exigem que o gerenciador de pacotes correspondente esteja instalado. Caches de aplicativos funcionam em qualquer distribuição.

## 🚫 O que o programa NÃO faz?

O CachyOS Cleaner não é um apagador indiscriminado. Ele não deve ser utilizado para:

- apagar aleatoriamente arquivos de `/usr`;
- apagar `/etc`;
- apagar `/boot`;
- apagar arquivos pessoais;
- apagar instalações de jogos;
- apagar IDEs;
- remover pacotes do sistema;
- remover automaticamente todo o Flatpak;
- remover automaticamente a biblioteca do Steam;
- remover automaticamente instalações do JetBrains Toolbox;
- remover kernels em uso sem confirmação.

## 🔐 Links simbólicos

A limpeza **não segue links simbólicos**, evitando acessar diretórios fora dos alvos definidos.

## 🧪 Desenvolvimento

```bash
cd cachyos-cleaner
python3 -m venv .build-python
source .build-python/bin/activate
pip install PySide6
python src/cachyos_cleaner.py
```

## 🏗️ Processo de distribuição

```
Código Python
      │
      ▼
   PySide6
      │
      ▼
 Ambiente Python
      │
      ▼
    AppDir
      │
      ├── Python
      ├── PySide6
      ├── Qt
      ├── Bibliotecas
      └── Aplicação
      │
      ▼
  mksquashfs
      │
      ▼
 SquashFS
      │
      +
      │
 AppImage Runtime
      │
      ▼
CachyOS-Cleaner-x86_64.AppImage
```

## 🖥️ Compatibilidade

- Build atual: **Linux x86_64**
- Desenvolvido e testado em **CachyOS/Arch Linux**

Por utilizar bibliotecas do sistema de build, a compatibilidade tende a ser melhor em distribuições Linux modernas com arquitetura x86_64. Funciona em qualquer distribuição Linux com Python 3 e PySide6 disponíveis (ou via AppImage).

## ⚠️ Considerações importantes

O tamanho do cache não significa que todos os arquivos devem ser apagados. Depois de uma limpeza:

- alguns aplicativos podem iniciar mais lentamente na primeira execução;
- thumbnails podem precisar ser recriados;
- navegadores podem recriar seus caches;
- ferramentas de desenvolvimento podem recriar arquivos;
- o espaço liberado pode voltar a ser utilizado posteriormente.

## 🐛 Solução de problemas

**AppImage não executa**
```bash
chmod +x CachyOS-Cleaner-x86_64.AppImage
./CachyOS-Cleaner-x86_64.AppImage
```

**Problema com FUSE**
```bash
./CachyOS-Cleaner-x86_64.AppImage --appimage-extract-and-run
```

**PySide6 não encontrado durante o desenvolvimento**
```bash
.build-python/bin/pip install --upgrade PySide6
```

**Recriar o build do zero**
```bash
rm -rf .build-python AppDir CachyOS-Cleaner.squashfs CachyOS-Cleaner-x86_64.AppImage
./build-appimage.sh
```

**Erro "No space left on device" ao construir**

O build usa `/tmp` temporariamente. Se houver espaço insuficiente, limpe extrações antigas:
```bash
rm -rf /tmp/appimage_extracted_* /tmp/squashfs_check /tmp/test.squashfs
```

**Erro ao abrir Configurações**

Feche e reabra o aplicativo. Se persistir, reinstale o AppImage.

**Itens com 0 bytes não aparecem**

Itens sem espaço são automaticamente ocultados na interface principal e nas configurações.

**Restaurar itens de uma limpeza**
```bash
# Via interface: menu Histórico → Desfazer
# Ou manualmente:
ls ~/.local/share/cachyos-cleaner/undo/
```

## 📋 Status do projeto

### Implementado

- [x] Interface gráfica PySide6
- [x] Análise de diretórios
- [x] Cálculo de espaço utilizado
- [x] Seleção de itens
- [x] Confirmação antes da limpeza
- [x] Escolha entre lixeira e exclusão permanente
- [x] Barra de progresso durante a limpeza (porcentagem + item atual)
- [x] Cancelamento da limpeza com confirmação
- [x] Categorias de segurança (Seguro, Revisar, Protegido, Grande)
- [x] Diretórios protegidos
- [x] Proteção contra links simbólicos
- [x] Limpeza do cache do pacman
- [x] Limpeza segura do cache do pnpm
- [x] Limpeza segura do cache do npm
- [x] Limpeza de caches do Yarn
- [x] Gerenciamento de kernels antigos
- [x] Limpeza de logs antigos
- [x] Gerenciamento de arquivos temporários
- [x] Análise do `/var/cache`
- [x] Análise de arquivos grandes
- [x] Visualização gráfica do espaço utilizado (gráfico de barras)
- [x] Histórico das limpezas
- [x] Possibilidade de desfazer operações (lixeira + backup)
- [x] Exclusões personalizadas
- [x] Lista de diretórios ignorados
- [x] Áreas de varredura configuráveis (marcar/desmarcar, adicionar, excluir)
- [x] Integração com ferramentas nativas do Arch/CachyOS
- [x] Detecção e suporte a múltiplas distribuições Linux
- [x] Empacotamento Python
- [x] Empacotamento PySide6
- [x] Empacotamento Qt
- [x] AppImage
- [x] Build utilizando mksquashfs
- [x] Runtime AppImage incorporado

### Em desenvolvimento / Planejado

- [ ] Tradução da interface (i18n com suporte a .po files)
- [ ] Atualização automática do aplicativo

## 🔮 Possíveis melhorias futuras

- [ ] Tradução da interface (i18n com suporte a .po files)
- [ ] Atualização automática do aplicativo
- [ ] Monitoramento em tempo real do espaço liberado durante a limpeza
- [ ] Agendamento de limpezas automáticas
- [ ] Relatórios detalhados por categoria

## 🤝 Contribuição

Contribuições são bem-vindas. Antes de adicionar uma nova rotina de limpeza, considere:

- Se os arquivos realmente podem ser recriados.
- Se a exclusão pode causar perda de dados.
- Se o diretório pode conter arquivos que não são cache.
- Se a operação deve ficar na categoria segura ou exigir revisão.
- Se links simbólicos podem causar acesso fora do diretório-alvo.
- Se a operação funciona corretamente em diferentes ambientes Linux.
- Se a operação detecta e respeita a distribuição Linux em uso.

Rotinas potencialmente destrutivas devem ser tratadas com cautela.

## 📄 Licença

Consulte o arquivo de licença incluído no projeto para verificar os termos de uso, modificação e distribuição.

---

**CachyOS Cleaner** — aplicativo gráfico para gerenciamento e limpeza de caches no Linux, desenvolvido com Python, PySide6 e Qt.
