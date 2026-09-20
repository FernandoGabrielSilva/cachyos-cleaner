#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
APPDIR="$ROOT/AppDir"
BUILD="$ROOT/.build-python"
OUTPUT="$ROOT/CachyOS-Cleaner-x86_64.AppImage"
RUNTIME="$ROOT/runtime-x86_64"
SQUASHFS="$ROOT/CachyOS-Cleaner.squashfs"

echo "[1/7] Criando ambiente Python..."

if [ ! -d "$BUILD" ]; then
    python3 -m venv --copies "$BUILD"
fi

"$BUILD/bin/python" -m pip install --upgrade pip

echo "[2/7] Instalando PySide6..."

"$BUILD/bin/pip" install --upgrade PySide6

PYVER="$("$BUILD/bin/python" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"

echo "Python detectado: $PYVER"

echo "[3/7] Limpando AppDir..."

rm -rf "$APPDIR"
mkdir -p \
    "$APPDIR/usr/bin" \
    "$APPDIR/usr/lib" \
    "$APPDIR/usr/share/applications" \
    "$APPDIR/usr/share/icons/hicolor/scalable/apps"

echo "[4/7] Copiando Python e bibliotecas..."

# Python executável
cp -L "$BUILD/bin/python3" "$APPDIR/usr/bin/python3"

# Biblioteca padrão do Python
PYTHON_STDLIB="/usr/lib/python${PYVER}"

if [ ! -d "$PYTHON_STDLIB" ]; then
    echo "ERRO: biblioteca padrão não encontrada: $PYTHON_STDLIB"
    exit 1
fi

mkdir -p "$APPDIR/usr/lib/python${PYVER}"
cp -a "$PYTHON_STDLIB/." "$APPDIR/usr/lib/python${PYVER}/"

# Site-packages do ambiente virtual
SITE_PACKAGES="$BUILD/lib/python${PYVER}/site-packages"

mkdir -p "$APPDIR/usr/lib/python${PYVER}/site-packages"
cp -a "$SITE_PACKAGES/." \
    "$APPDIR/usr/lib/python${PYVER}/site-packages/"

# libpython
LIBPYTHON="$("$BUILD/bin/python" - <<'PY'
import sysconfig
import os

libdir = sysconfig.get_config_var("LIBDIR")
libname = sysconfig.get_config_var("LDLIBRARY")

if libdir and libname:
    path = os.path.join(libdir, libname)
    if os.path.exists(path):
        print(path)
PY
)"

if [ -n "$LIBPYTHON" ] && [ -f "$LIBPYTHON" ]; then
    cp -L "$LIBPYTHON" "$APPDIR/usr/lib/"
fi

echo "[5/7] Copiando bibliotecas compartilhadas..."

# Coleta dependências ELF recursivamente.
declare -A COPIED

is_system_core() {
    local lib="$1"

    case "$(basename "$lib")" in
        ld-linux*.so*)
            return 0
            ;;
        libc.so*)
            return 0
            ;;
        libm.so*)
            return 0
            ;;
        libpthread.so*)
            return 0
            ;;
        libdl.so*)
            return 0
            ;;
        librt.so*)
            return 0
            ;;
        libresolv.so*)
            return 0
            ;;
        libutil.so*)
            return 0
            ;;
        libnsl.so*)
            return 0
            ;;
        libcrypt.so*)
            return 0
            ;;
        libgcc_s.so*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

copy_dependency() {
    local lib="$1"

    [ -f "$lib" ] || return 0

    if is_system_core "$lib"; then
        return 0
    fi

    local name
    name="$(basename "$lib")"

    if [ "${COPIED[$name]+yes}" = "yes" ]; then
        return 0
    fi

    COPIED["$name"]=1

    if [ "$lib" != "$APPDIR/usr/lib/$name" ]; then
        cp -L "$lib" "$APPDIR/usr/lib/$name" 2>/dev/null || true
    fi
}

collect_deps() {
    local file="$1"

    [ -f "$file" ] || return 0

    while read -r lib; do
        case "$lib" in
            /*)
                copy_dependency "$lib"
                ;;
        esac
    done < <(
        ldd "$file" 2>/dev/null |
        awk '
            /=>/ && $3 ~ /^\// {
                print $3
            }
            /^\// {
                print $1
            }
        '
    )
}

# Python
collect_deps "$APPDIR/usr/bin/python3"

# libpython
for lib in "$APPDIR/usr/lib"/libpython*.so*; do
    [ -f "$lib" ] && collect_deps "$lib"
done

# PySide6 / Qt
find "$APPDIR/usr/lib/python${PYVER}/site-packages" \
    -type f \
    \( -name "*.so" -o -name "*.so.*" \) \
    -print0 |
while IFS= read -r -d '' file; do
    collect_deps "$file"
done

# Recursivamente coleta dependências das bibliotecas copiadas.
for pass in 1 2 3; do
    find "$APPDIR/usr/lib" \
        -maxdepth 1 \
        -type f \
        -name "*.so*" \
        -print0 |
    while IFS= read -r -d '' file; do
        collect_deps "$file"
    done
done

echo "[6/7] Criando AppRun e arquivos do aplicativo..."

cat > "$APPDIR/AppRun" <<EOF
#!/usr/bin/env bash

HERE="\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd)"
PYVER="$PYVER"

export PYTHONHOME="\$HERE/usr"
export PYTHONNOUSERSITE=1

export PYTHONPATH="\$HERE/usr/lib/python\${PYVER}/site-packages"

export LD_LIBRARY_PATH="\$HERE/usr/lib:\$HERE/usr/lib/python\${PYVER}/site-packages/PySide6/Qt/lib:\${LD_LIBRARY_PATH:-}"

export QT_PLUGIN_PATH="\$HERE/usr/lib/python\${PYVER}/site-packages/PySide6/Qt/plugins"
export QT_QPA_PLATFORM_PLUGIN_PATH="\$HERE/usr/lib/python\${PYVER}/site-packages/PySide6/Qt/plugins/platforms"

exec "\$HERE/usr/bin/python3" "\$HERE/usr/bin/cachyos-cleaner" "\$@"
EOF

chmod +x "$APPDIR/AppRun"

cp "$ROOT/src/cachyos_cleaner.py" \
   "$APPDIR/usr/bin/cachyos-cleaner"

chmod +x "$APPDIR/usr/bin/cachyos-cleaner"

cat > "$APPDIR/usr/share/applications/CachyOS-Cleaner.desktop" <<EOF
[Desktop Entry]
Name=CachyOS Cleaner
Comment=Limpeza segura de arquivos temporários
Exec=CachyOS-Cleaner
Icon=cachyos-cleaner
Terminal=false
Type=Application
Categories=System;Utility;
EOF

cat > "$APPDIR/usr/share/icons/hicolor/scalable/apps/cachyos-cleaner.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
  <rect x="32" y="32" width="192" height="192" rx="40"
        fill="none" stroke="white" stroke-width="18"/>
  <path d="M72 96h112M88 96l8 96h64l8-96"
        fill="none" stroke="white" stroke-width="16"
        stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M104 72h48"
        fill="none" stroke="white" stroke-width="16"
        stroke-linecap="round"/>
</svg>
EOF

echo "[7/7] Construindo AppImage..."

if ! command -v mksquashfs >/dev/null 2>&1; then
    echo "ERRO: mksquashfs não encontrado."
    echo "Instale com:"
    echo "  sudo pacman -S squashfs-tools"
    exit 1
fi

# Baixa o runtime oficial do AppImage apenas durante a compilação.
# Ele ficará incorporado no AppImage final.
if [ ! -x "$RUNTIME" ]; then
    echo "Baixando runtime oficial do AppImage..."

    if command -v curl >/dev/null 2>&1; then
        curl -fL --retry 3 \
            -o "$RUNTIME" \
            "https://github.com/AppImage/type2-runtime/releases/download/continuous/runtime-x86_64"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$RUNTIME" \
            "https://github.com/AppImage/type2-runtime/releases/download/continuous/runtime-x86_64"
    else
        echo "ERRO: curl ou wget é necessário para baixar o runtime."
        exit 1
    fi

    chmod +x "$RUNTIME"
fi

rm -f "$SQUASHFS" "$OUTPUT"

echo "Compactando AppDir..."

mksquashfs "$APPDIR" "$SQUASHFS" \
    -root-owned \
    -noappend \
    -comp zstd \
    -all-root

echo "Montando AppImage..."

cat "$RUNTIME" "$SQUASHFS" > "$OUTPUT"

chmod +x "$OUTPUT"

echo
echo "============================================"
echo " AppImage criado com sucesso!"
echo "============================================"
echo
echo "Arquivo:"
echo "  $OUTPUT"
echo
echo "Tamanho:"
du -h "$OUTPUT" | awk '{print "  " $1}'
echo
echo "Teste:"
echo "  ./CachyOS-Cleaner-x86_64.AppImage"
echo
echo "Se o sistema não tiver FUSE:"
echo "  ./CachyOS-Cleaner-x86_64.AppImage --appimage-extract-and-run"
echo
