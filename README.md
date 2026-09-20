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

O CachyOS Cleaner é um aplicativo gráfico para análise e limpeza de caches e arquivos temporários no Linux, com foco em CachyOS/Arch. A ferramenta não apaga nada automaticamente: ela analisa os diretórios configurados, mostra o espaço ocupado, e só remove o que o usuário selecionar e confirmar.

## 🧹 O que o programa limpa?

O programa atualmente concentra a limpeza em caches e arquivos temporários previamente definidos no código, por exemplo:

- Thumbnails
- Cache do Zen Browser
- Cache do Vivaldi
- Cache do Google Chrome
- Cache do Mozilla
- Cache do Brave
- Cache do node-gyp
- Cache do VS Code (C/C++)
- Cache do Tracker3
- Cache do pip

## 🗂️ Categorias

Alguns caches podem ser grandes ou conter arquivos que o usuário pode querer manter. Esses itens são apresentados separadamente na interface, para que o usuário decida se deseja removê-los. Atualmente:

- `~/.cache/codex-runtimes`
- `~/.cache/nvidia`

## 🔴 Protegidos

Alguns diretórios importantes são apenas identificados pelo programa e **não** são apagados pela limpeza automática, pois podem conter jogos, IDEs, runtimes, aplicativos ou outros dados que não devem ser removidos como se fossem simples caches. Atualmente:

- `~/.local/share/Steam` — pode conter jogos, Proton, compatdata, shader cache, runtimes, configurações e downloads.
- `~/.local/share/JetBrains/Toolbox` — pode conter instalações de CLion, IntelliJ IDEA, PyCharm, WebStorm e outros produtos JetBrains. A remoção deve ser feita pelo próprio gerenciador do Toolbox, não por uma limpeza genérica.
- `/var/lib/flatpak` — o Flatpak possui ferramentas próprias para gerenciar aplicativos, runtimes e dependências; não é recomendado apagar esse diretório para liberar espaço.

## 🛡️ Segurança

O CachyOS Cleaner foi desenvolvido com uma abordagem conservadora. Antes de qualquer exclusão:

1. O programa analisa os diretórios configurados.
2. Calcula o espaço ocupado.
3. Apresenta os itens encontrados na interface.
4. O usuário escolhe o que deseja limpar.
5. O programa solicita confirmação.
6. Somente os itens selecionados são processados.

O programa também **evita seguir links simbólicos** durante a análise e a limpeza, o que reduz o risco de a limpeza atravessar para outro diretório ou filesystem através de um symlink.

## 🖥️ Interface

A interface gráfica é construída com **Python**, **PySide6** e **Qt**. Ela apresenta os diretórios encontrados de forma organizada e permite selecionar os itens que serão limpos, com o objetivo de tornar a manutenção do sistema mais simples sem exigir vários comandos no terminal.

## 📦 Estrutura do projeto

```
cachyos-cleaner-pyside6/
├── src/
│   └── cachyos_cleaner.py
│
├── CachyOS-Cleaner.desktop
├── build-appimage.sh
├── README.md
│
├── .build-python/          # ambiente Python usado durante a compilação
│
└── AppDir/
    ├── AppRun
    └── usr/
        ├── bin/
        ├── lib/
        └── share/
```

`.build-python/` e `AppDir/` são usados durante o processo de compilação e podem ser recriados pelo script `build-appimage.sh`.

## 🔨 Compilação

O projeto possui um script automatizado, `./build-appimage.sh`, que executa as seguintes etapas:

1. Cria o ambiente Python.
2. Instala/atualiza o PySide6.
3. Identifica a versão do Python.
4. Copia o Python para o AppDir.
5. Copia a biblioteca padrão do Python.
6. Copia os pacotes instalados.
7. Copia a libpython.
8. Coleta as bibliotecas compartilhadas necessárias.
9. Configura o AppRun.
10. Cria o arquivo `.desktop`.
11. Cria o ícone.
12. Gera o filesystem SquashFS.
13. Combina o runtime do AppImage com o SquashFS.
14. Gera o AppImage final.

O resultado é o arquivo `CachyOS-Cleaner-x86_64.AppImage`.

### Dependências para compilar

No CachyOS/Arch:

```bash
sudo pacman -S python python-pip python-virtualenv squashfs-tools curl
```

Também são utilizados pelo processo de build: `python3`, `pip`, `venv`, `mksquashfs`, `curl` ou `wget`, e `ldd`.

> O projeto **não** depende do `appimagetool`. A imagem é construída diretamente com o runtime do AppImage e o `mksquashfs`.

## 🚀 Compilando

```bash
cd ~/Downloads/cachyos-cleaner-pyside6
chmod +x build-appimage.sh
./build-appimage.sh
```

Ao final deverá existir o arquivo `CachyOS-Cleaner-x86_64.AppImage`.

## ▶️ Executando

```bash
chmod +x CachyOS-Cleaner-x86_64.AppImage
./CachyOS-Cleaner-x86_64.AppImage
```

## 🔧 Executando sem FUSE

Alguns sistemas Linux não possuem suporte para montar AppImages diretamente. Nesse caso, tente:

```bash
./CachyOS-Cleaner-x86_64.AppImage --appimage-extract-and-run
```

Isso executa o aplicativo extraindo o conteúdo do AppImage, sem depender da montagem FUSE tradicional.

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

Dessa forma, o computador de destino não precisa ter o ambiente Python/PySide6 configurado para executar o programa.

## 🐍 Tecnologias utilizadas

- **Python** — lógica de análise de diretórios, cálculo de espaço, seleção de itens, limpeza e interação com o sistema de arquivos.
- **PySide6** — interface gráfica baseada em Qt.
- **Qt** — componentes visuais da aplicação.
- **SquashFS** — compactação do conteúdo do aplicativo dentro do AppImage.
- **AppImage** — distribuição do aplicativo como um único arquivo executável.

## 🚫 O que o programa NÃO faz?

O CachyOS Cleaner não foi desenvolvido para ser um apagador indiscriminado do sistema. Ele não deve ser utilizado para:

- apagar aleatoriamente arquivos de `/usr`;
- apagar `/etc`;
- apagar `/boot`;
- apagar arquivos pessoais;
- apagar instalações de jogos;
- apagar IDEs;
- remover pacotes do sistema;
- remover automaticamente todo o Flatpak;
- remover automaticamente a biblioteca do Steam;
- remover automaticamente instalações do JetBrains Toolbox.

Os diretórios protegidos são tratados como informação/revisão, não como alvos normais de limpeza.

## 🔐 Links simbólicos

A limpeza foi projetada para **não seguir links simbólicos**. Isso é importante porque um link dentro de um diretório de cache poderia apontar para outro local do sistema — a intenção é manter a limpeza restrita aos diretórios originalmente definidos pelo programa.

## 🧪 Desenvolvimento

```bash
cd cachyos-cleaner-pyside6

# criar o ambiente
python3 -m venv .build-python

# ativar
source .build-python/bin/activate

# instalar o PySide6
pip install PySide6

# executar diretamente
python src/cachyos_cleaner.py
```

Durante o desenvolvimento, também é possível executar diretamente:

```bash
.build-python/bin/python src/cachyos_cleaner.py
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

Por utilizar bibliotecas do sistema de build, a compatibilidade tende a ser melhor em distribuições Linux modernas com arquitetura x86_64. O AppImage não elimina dependências fundamentais do sistema operacional, como kernel Linux, hardware compatível, driver gráfico e demais componentes fundamentais do sistema.

## ⚠️ Considerações importantes

O tamanho do cache não significa necessariamente que todos os arquivos devem ser apagados — caches existem para acelerar aplicativos e reduzir trabalho repetido. Depois de uma limpeza:

- alguns aplicativos podem iniciar mais lentamente na primeira execução;
- thumbnails podem precisar ser recriados;
- navegadores podem recriar seus caches;
- ferramentas de desenvolvimento podem recriar arquivos;
- o espaço liberado pode voltar a ser utilizado posteriormente.

Por isso, o Cleaner utiliza categorias diferentes em vez de simplesmente apagar tudo.

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
rm -rf .build-python AppDir
./build-appimage.sh
```

## 📋 Status do projeto

### Implementado

- [x] Interface gráfica PySide6
- [x] Análise de diretórios
- [x] Cálculo de espaço utilizado
- [x] Seleção de itens
- [x] Confirmação antes da limpeza
- [x] Categorias de segurança
- [x] Diretórios protegidos
- [x] Proteção contra links simbólicos
- [x] Empacotamento Python
- [x] Empacotamento PySide6
- [x] Empacotamento Qt
- [x] AppImage
- [x] Build utilizando mksquashfs
- [x] Runtime AppImage incorporado

## 🔮 Possíveis melhorias futuras

- [ ] Limpeza do cache do pacman
- [ ] Limpeza segura do cache do pnpm
- [ ] Limpeza segura do cache do npm
- [ ] Limpeza de caches do Yarn
- [ ] Gerenciamento de kernels antigos
- [ ] Limpeza de logs antigos
- [ ] Gerenciamento de arquivos temporários
- [ ] Análise do `/var/cache`
- [ ] Análise de arquivos grandes
- [ ] Visualização gráfica do espaço utilizado
- [ ] Histórico das limpezas
- [ ] Possibilidade de desfazer operações quando tecnicamente possível
- [ ] Exclusões personalizadas
- [ ] Lista de diretórios ignorados
- [ ] Integração com ferramentas nativas do Arch/CachyOS
- [ ] Atualização automática do aplicativo
- [ ] Tradução da interface
- [ ] Suporte a outras distribuições Linux

## 🤝 Contribuição

Contribuições são bem-vindas. Antes de adicionar uma nova rotina de limpeza, considere:

- Se os arquivos realmente podem ser recriados.
- Se a exclusão pode causar perda de dados.
- Se o diretório pode conter arquivos que não são cache.
- Se a operação deve ficar na categoria segura ou exigir revisão.
- Se links simbólicos podem causar acesso fora do diretório-alvo.
- Se a operação funciona corretamente em diferentes ambientes Linux.

Rotinas potencialmente destrutivas devem ser tratadas com cautela.

## 📄 Licença

Consulte o arquivo de licença incluído no projeto para verificar os termos de uso, modificação e distribuição.

---

**CachyOS Cleaner** — aplicativo gráfico para gerenciamento e limpeza de caches no Linux, desenvolvido com Python, PySide6 e Qt.
