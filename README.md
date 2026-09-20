# CachyOS Cleaner — PySide6 AppImage

Versão gráfica com Qt/PySide6.

## Dependências apenas para COMPILAR

No CachyOS:

```bash
sudo pacman -S python python-pip python-virtualenv appimagekit
```

Depois:

```bash
chmod +x build-appimage.sh
./build-appimage.sh
```

O script cria um ambiente Python local, instala PySide6, copia Python, bibliotecas e o aplicativo para `AppDir` e gera:

```text
CachyOS-Cleaner-x86_64.AppImage
```

## Executar

```bash
chmod +x CachyOS-Cleaner-x86_64.AppImage
./CachyOS-Cleaner-x86_64.AppImage
```

O AppImage não exige que o computador de destino tenha Python/PySide6/Tk instalados.

## Observação

O build é feito para Linux x86_64 e foi pensado para CachyOS/Arch. Como o Python é empacotado a partir do sistema de build, a melhor compatibilidade é com distribuições Linux modernas.
