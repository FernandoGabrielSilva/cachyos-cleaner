#!/usr/bin/env python3
import os
import sys
import json
import shutil
import subprocess
import threading
from pathlib import Path
from datetime import datetime

from PySide6.QtCore import Qt, QEvent
from PySide6.QtGui import QFont, QIcon, QPainter, QColor, QPen
from PySide6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QLabel, QPushButton, QTreeWidget, QTreeWidgetItem, QProgressBar,
    QMessageBox, QFrame, QCheckBox, QDialog, QVBoxLayout, QHBoxLayout,
    QFormLayout, QLineEdit, QListWidget, QListWidgetItem, QAbstractItemView,
    QTabWidget, QFileDialog,
)

APP_NAME = "CachyOS Cleaner"
HOME = Path.home()
DATA_DIR = Path.home() / ".local" / "share" / "cachyos-cleaner"
HISTORY_FILE = DATA_DIR / "history.json"
CONFIG_FILE = DATA_DIR / "config.json"

os.makedirs(DATA_DIR, exist_ok=True)

DISTRO = ""
try:
    with open("/etc/os-release") as f:
        for line in f:
            if line.startswith("ID="):
                DISTRO = line.split("=", 1)[1].strip().strip('"')
                break
except Exception:
    DISTRO = "unknown"

SAFE = [
    ("Miniaturas", HOME / ".cache" / "thumbnails", "safe"),
    ("Cache Zen", HOME / ".cache" / "zen", "safe"),
    ("Cache Vivaldi", HOME / ".cache" / "vivaldi", "safe"),
    ("Cache Chrome/Chromium", HOME / ".cache" / "google-chrome", "safe"),
    ("Cache Firefox", HOME / ".cache" / "mozilla", "safe"),
    ("Cache Brave", HOME / ".cache" / "BraveSoftware", "safe"),
    ("Cache node-gyp", HOME / ".cache" / "node-gyp", "safe"),
    ("Cache VS Code C/C++", HOME / ".cache" / "vscode-cpptools", "safe"),
    ("Cache Tracker3", HOME / ".cache" / "tracker3", "safe"),
    ("Cache pip", HOME / ".cache" / "pip", "safe"),
    ("Cache pnpm", HOME / ".local" / "share" / "pnpm" / "store", "safe"),
    ("Cache npm", HOME / ".npm", "safe"),
    ("Cache Yarn", HOME / ".cache" / "yarn", "safe"),
    ("Arquivos temporários /tmp", "/tmp", "safe"),
    ("Arquivos temporários /var/tmp", "/var/tmp", "safe"),
    ("Cache pacman", "/var/cache/pacman/pkg", "safe"),
    ("Cache Steam Runtime", HOME / ".local" / "share" / "Steam" / "steam-runtime", "safe"),
]

REVIEW = [
    ("Codex runtimes", HOME / ".cache" / "codex-runtimes", "review"),
    ("Cache NVIDIA", HOME / ".cache" / "nvidia", "review"),
    ("Cache Dart", HOME / ".cache" / "dart", "review"),
    ("Cache Gradle", HOME / ".cache" / "gradle", "review"),
    ("Cache Maven", HOME / ".cache" / "maven", "review"),
    ("Cache Cargo", HOME / ".cache" / "cargo", "review"),
    ("Caches PyCharm", HOME / ".cache" / "JetBrains", "review"),
    ("Caches IntelliJ", HOME / ".cache" / "intellij", "review"),
]

PROTECTED = [
    ("Steam", HOME / ".local" / "share" / "Steam", "protected"),
    ("JetBrains Toolbox", HOME / ".local" / "share" / "JetBrains" / "Toolbox", "protected"),
    ("Flatpak do sistema", Path("/var/lib/flatpak"), "protected"),
]

if DISTRO in ("arch", "cachyos"):
    SAFE.append(("Cache paccache", "/var/cache/pacman/pkg", "safe"))

KERNEL_DIR = Path("/boot")


def folder_size(path):
    if isinstance(path, str):
        path = Path(path)
    if not path.exists():
        return 0
    total = 0
    if path.is_file():
        try:
            return path.stat().st_size
        except OSError:
            return 0
    for root, dirs, files in os.walk(path, topdown=True, followlinks=False):
        dirs[:] = [d for d in dirs if not (Path(root) / d).is_symlink()]
        for f in files:
            p = Path(root) / f
            try:
                if not p.is_symlink():
                    total += p.stat().st_size
            except OSError:
                pass
    return total


def human(n):
    n = float(n)
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if n < 1024:
            return f"{n:.1f} {unit}"
        n /= 1024
    return f"{n:.1f} PB"


def load_config():
    defaults = {"exclusions": [], "ignored_dirs": [], "auto_update_check": True, "language": "pt"}
    try:
        if CONFIG_FILE.exists():
            with open(CONFIG_FILE) as f:
                cfg = json.load(f)
                defaults.update(cfg)
    except Exception:
        pass
    return defaults


def save_config(cfg):
    try:
        DATA_DIR.mkdir(parents=True, exist_ok=True)
        with open(CONFIG_FILE, "w") as f:
            json.dump(cfg, f, indent=2)
    except Exception:
        pass


def load_history():
    try:
        if HISTORY_FILE.exists():
            with open(HISTORY_FILE) as f:
                return json.load(f)
    except Exception:
        pass
    return []


def save_history(entry):
    try:
        DATA_DIR.mkdir(parents=True, exist_ok=True)
        history = load_history()
        history.append(entry)
        with open(HISTORY_FILE, "w") as f:
            json.dump(history, f, indent=2)
    except Exception:
        pass


def trash_path(path):
    try:
        result = subprocess.run(
            ["gio", "trash", str(path)],
            capture_output=True, text=True, timeout=30
        )
        return result.returncode == 0
    except Exception:
        return False


def undo_backup_path():
    return DATA_DIR / "undo"


def move_to_backup(path):
    backup = undo_backup_path()
    backup.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    name = Path(path).name
    dest = backup / f"{ts}_{name}"
    n = 1
    while dest.exists():
        dest = backup / f"{ts}_{name}_{n}"
        n += 1
    try:
        shutil.move(str(path), str(dest))
        return str(dest)
    except Exception:
        return None


def get_kernels():
    kernels = []
    try:
        result = subprocess.run(
            ["pacman", "-Q", "linux", "linux-lts", "linux-zen", "linux-hardened"],
            capture_output=True, text=True, timeout=15
        )
        for line in result.stdout.strip().split("\n"):
            if line:
                kernels.append((line, "", "review"))
    except Exception:
        pass
    if not kernels and KERNEL_DIR.exists():
        for f in sorted(KERNEL_DIR.iterdir()):
            if f.is_file() and (f.name.startswith("vmlinuz") or f.name.startswith("initramfs")):
                name = f.name.replace("vmlinuz-", "").replace("initramfs-", "").replace(".img", "")
                if name:
                    kernels.append((name, str(f), "review"))
    return kernels


def get_var_cache_dirs():
    dirs = []
    vc = Path("/var/cache")
    if not vc.exists():
        return dirs
    for d in sorted(vc.iterdir()):
        if d.is_dir() and not d.is_symlink():
            size = folder_size(d)
            if size > 0:
                dirs.append((f"/var/cache/{d.name}", d, size))
    return dirs


def get_large_files(limit_mb=100):
    files = []
    search_paths = [Path("/tmp"), Path("/var/tmp"), HOME / ".cache"]
    if DISTRO in ("arch", "cachyos"):
        search_paths.append(Path("/var/cache"))
    for base in search_paths:
        if not base.exists():
            continue
        try:
            result = subprocess.run(
                ["find", str(base), "-type", "f", "-size", f"+{limit_mb}M",
                 "-not", "-path", "*/.git/*", "-not", "-path", "*/node_modules/*"],
                capture_output=True, text=True, timeout=30
            )
            for line in result.stdout.strip().split("\n"):
                if line and Path(line).exists():
                    try:
                        size = Path(line).stat().st_size
                        if size > 0:
                            files.append((line, Path(line), size))
                    except OSError:
                        pass
        except Exception:
            pass
    files.sort(key=lambda x: x[2], reverse=True)
    return files[:50]


def is_excluded(path, exclusions):
    p = str(path)
    for ex in exclusions:
        if ex and (p == ex or p.startswith(ex + "/") or p.startswith(ex)):
            return True
    return False


def is_ignored(path, ignored_dirs):
    p = str(path)
    for ig in ignored_dirs:
        if ig and (p == ig or p.startswith(ig + "/")):
            return True
    return False


def is_disabled_area(path, disabled_areas):
    p = str(path)
    for da in disabled_areas:
        if da and (p == da or p.startswith(da + "/")):
            return True
    return False


class ScanEvent(QEvent):
    TYPE = QEvent.Type(QEvent.registerEventType())

    def __init__(self, rows):
        super().__init__(self.TYPE)
        self.rows = rows


class ChartDialog(QDialog):
    def __init__(self, rows, parent=None):
        super().__init__(parent)
        self.rows = [r for r in rows if r[0] in ("safe", "review", "large") and r[3] > 0]
        self.setWindowTitle("Espaço utilizado")
        self.resize(800, 550)
        self.setMinimumSize(550, 400)
        if self.rows:
            total = sum(r[3] for r in self.rows)
            self.setWindowTitle(f"Espaço utilizado — Total: {human(total)}")

    def paintEvent(self, event):
        if not self.rows:
            return
        p = QPainter(self)
        p.setRenderHint(QPainter.Antialiasing)
        w = self.width()
        h = self.height()
        margin_left = 20
        margin_right = 160
        margin_top = 40
        margin_bottom = 40
        bar_x = margin_left
        bar_y = margin_top + 25
        bar_w = max(20, w - margin_left - margin_right)
        bar_h = h - margin_top - margin_bottom - 25
        max_size = max(r[3] for r in self.rows)
        total = sum(r[3] for r in self.rows)
        if max_size == 0:
            max_size = 1
        y = bar_y
        p.setFont(QFont("Segoe UI", 9))
        for idx, (kind, name, path, size) in enumerate(self.rows):
            ratio = size / max_size
            bh = max(3, int(ratio * bar_h))
            color = QColor([
                "#4f8cff", "#ff6b6b", "#51cf66", "#ffd43b", "#cc5de8",
                "#ff922b", "#20c997", "#748ffc", "#f06595", "#a9e34b",
                "#e599f7", "#66d9e8", "#ffa94d", "#74c0fc", "#69db7c",
                "#e78b2e", "#d0bfff", "#91a6ff", "#7ee8fa", "#e8c4fa",
            ][idx % 20])
            p.setBrush(color)
            p.setPen(Qt.GlobalColor.transparent)
            p.drawRoundedRect(bar_x, y, bar_w, bh, 4, 4)
            p.setPen(Qt.GlobalColor.white)
            p.drawText(bar_x + 6, y + bh // 2 + 4, name[:30])
            p.setPen(QColor("#cccccc"))
            p.drawText(bar_x + bar_w + 10, y + bh // 2 + 4, human(size))
            y += bh + 4
            if y + bh > bar_y + bar_h:
                break
        drawn = idx + 1 if self.rows else 0
        p.setPen(QColor("#888888"))
        p.setFont(QFont("Segoe UI", 10))
        p.drawText(margin_left, 20, f"Total: {human(total)}")
        p.drawText(margin_left, h - 12, f"Mostrando {drawn} de {len(self.rows)} categorias")
        p.end()


class SettingsDialog(QDialog):
    def __init__(self, config, rows, parent=None):
        super().__init__(parent)
        self.config = config.copy()
        self.rows = rows
        self.setWindowTitle("Configurações")
        self.resize(750, 550)
        self.setMinimumSize(550, 400)

        layout = QVBoxLayout(self)

        tabs = QTabWidget()

        areas_widget = QWidget()
        areas_layout = QVBoxLayout(areas_widget)
        areas_layout.addWidget(QLabel("Áreas escaneadas — marque para incluir na análise, desmarque para ignorar:"))
        self.areas_list = QListWidget()
        self.areas_list.setSelectionMode(QAbstractItemView.SelectionMode.MultiSelection)
        self.area_checkboxes = {}
        for kind, name, path, size in rows:
            cat = {"safe": "Seguro", "review": "Revisar", "protected": "Protegido", "large": "Grande"}.get(kind, "Outro")
            text = f"[{cat}] {name} — {path} ({human(size)})"
            item = QListWidgetItem(text)
            item.setFlags(item.flags() | Qt.ItemFlag.ItemIsUserCheckable)
            if kind in ("safe", "review"):
                item.setCheckState(Qt.CheckState.Checked)
            else:
                item.setCheckState(Qt.CheckState.Unchecked)
                item.setForeground(4, Qt.GlobalColor.gray)
            self.areas_list.addItem(item)
            self.area_checkboxes[name] = item
        areas_layout.addWidget(self.areas_list)
        areas_btns = QHBoxLayout()
        add_area = QPushButton("+ Adicionar área")
        add_area.clicked.connect(self.add_area)
        rem_area = QPushButton("- Remover selecionados")
        rem_area.clicked.connect(self.remove_area)
        areas_btns.addWidget(add_area)
        areas_btns.addWidget(rem_area)
        areas_layout.addLayout(areas_btns)
        tabs.addTab(areas_widget, "Áreas de Varredura")

        exclusion_widget = QWidget()
        excl_layout = QVBoxLayout(exclusion_widget)
        excl_layout.addWidget(QLabel("Diretórios excluídos da análise e limpeza (um por linha):"))
        self.exclusions_list = QListWidget()
        self.exclusions_list.setSelectionMode(QAbstractItemView.SelectionMode.MultiSelection)
        for ex in self.config.get("exclusions", []):
            self.exclusions_list.addItem(ex)
        excl_layout.addWidget(self.exclusions_list)
        excl_btns = QHBoxLayout()
        add_excl = QPushButton("+ Adicionar")
        add_excl.clicked.connect(self.add_exclusion)
        rem_excl = QPushButton("- Remover selecionados")
        rem_excl.clicked.connect(self.remove_exclusion)
        excl_btns.addWidget(add_excl)
        excl_btns.addWidget(rem_excl)
        excl_layout.addLayout(excl_btns)
        tabs.addTab(exclusion_widget, "Exclusões")

        ignored_widget = QWidget()
        ig_layout = QVBoxLayout(ignored_widget)
        ig_layout.addWidget(QLabel("Diretórios ignorados (exibidos apenas como informação):"))
        self.ignored_list = QListWidget()
        self.ignored_list.setSelectionMode(QAbstractItemView.SelectionMode.MultiSelection)
        for ig in self.config.get("ignored_dirs", []):
            self.ignored_list.addItem(ig)
        ig_layout.addWidget(self.ignored_list)
        ig_btns = QHBoxLayout()
        add_ig = QPushButton("+ Adicionar")
        add_ig.clicked.connect(self.add_ignored)
        rem_ig = QPushButton("- Remover selecionados")
        rem_ig.clicked.connect(self.remove_ignored)
        ig_btns.addWidget(add_ig)
        ig_btns.addWidget(rem_ig)
        ig_layout.addLayout(ig_btns)
        tabs.addTab(ignored_widget, "Diretórios Ignorados")

        other_widget = QWidget()
        other_layout = QVBoxLayout(other_widget)
        self.auto_update = QCheckBox("Verificar atualizações automaticamente")
        self.auto_update.setChecked(self.config.get("auto_update_check", True))
        other_layout.addWidget(self.auto_update)
        other_layout.addSpacing(10)
        other_layout.addWidget(QLabel("Idioma da interface:"))
        lang_layout = QHBoxLayout()
        self.language = QLineEdit(self.config.get("language", "pt"))
        lang_layout.addWidget(self.language)
        lang_layout.addWidget(QLabel("(pt, en, es, etc.)"))
        other_layout.addLayout(lang_layout)
        tabs.addTab(other_widget, "Outros")

        layout.addWidget(tabs)

        btn_layout = QHBoxLayout()
        save = QPushButton("Salvar")
        save.clicked.connect(self.save_settings)
        cancel = QPushButton("Cancelar")
        cancel.clicked.connect(self.reject)
        btn_layout.addStretch()
        btn_layout.addWidget(save)
        btn_layout.addWidget(cancel)
        layout.addLayout(btn_layout)

    def add_area(self):
        path, ok = QFileDialog.getExistingDirectory(self, "Selecionar diretório para adicionar")
        if ok and path:
            text = f"[Outro] {Path(path).name} — {path}"
            item = QListWidgetItem(text)
            item.setFlags(item.flags() | Qt.ItemFlag.ItemIsUserCheckable)
            item.setCheckState(0, Qt.CheckState.Checked)
            self.areas_list.addItem(item)

    def remove_area(self):
        for item in self.areas_list.selectedItems():
            self.areas_list.takeItem(self.areas_list.row(item))

    def get_enabled_areas(self):
        enabled = []
        excluded_paths = []
        for i in range(self.areas_list.count()):
            item = self.areas_list.item(i)
            checked = item.checkState(0) == Qt.CheckState.Checked
            path_text = item.text()
            path_start = path_text.find(" — ")
            if path_start >= 0:
                path_str = path_text[path_start + 3:]
            else:
                path_str = path_text
            if checked:
                enabled.append(path_str)
            else:
                excluded_paths.append(path_str)
        return enabled, excluded_paths

    def add_exclusion(self):
        path, ok = QFileDialog.getExistingDirectory(self, "Selecionar diretório para excluir")
        if ok and path:
            self.exclusions_list.addItem(path)

    def remove_exclusion(self):
        for item in self.exclusions_list.selectedItems():
            self.exclusions_list.takeItem(self.exclusions_list.row(item))

    def add_ignored(self):
        path, ok = QFileDialog.getExistingDirectory(self, "Selecionar diretório para ignorar")
        if ok and path:
            self.ignored_list.addItem(path)

    def remove_ignored(self):
        for item in self.ignored_list.selectedItems():
            self.ignored_list.takeItem(self.ignored_list.row(item))

    def save_settings(self):
        exclusions = [self.exclusions_list.item(i).text() for i in range(self.exclusions_list.count())]
        ignored = [self.ignored_list.item(i).text() for i in range(self.ignored_list.count())]
        enabled, disabled = self.get_enabled_areas()
        self.config["exclusions"] = exclusions
        self.config["ignored_dirs"] = ignored
        self.config["auto_update_check"] = self.auto_update.isChecked()
        self.config["language"] = self.language.text().strip() or "pt"
        self.config["enabled_areas"] = enabled
        self.config["disabled_areas"] = disabled
        save_config(self.config)
        self.accept()


class HistoryDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Histórico de limpezas")
        self.resize(650, 450)
        self.setMinimumSize(450, 300)

        layout = QVBoxLayout(self)
        layout.addWidget(QLabel("Histórico das últimas limpezas realizadas:"))

        self.list_widget = QListWidget()
        self.list_widget.setSelectionMode(QAbstractItemView.SelectionMode.SingleSelection)
        layout.addWidget(self.list_widget)

        btns = QHBoxLayout()
        undo_btn = QPushButton("↩ Desfazer última (quando possível)")
        undo_btn.clicked.connect(self.try_undo)
        clear_btn = QPushButton("🗑 Limpar histórico")
        clear_btn.clicked.connect(self.clear_history)
        close_btn = QPushButton("Fechar")
        close_btn.clicked.connect(self.reject)
        btns.addWidget(undo_btn)
        btns.addWidget(clear_btn)
        btns.addWidget(close_btn)
        layout.addLayout(btns)

        self.refresh()

    def refresh(self):
        self.list_widget.clear()
        history = load_history()
        for entry in reversed(history[-50:]):
            ts = entry.get("timestamp", "???")
            total = entry.get("total", 0)
            count = entry.get("count", 0)
            dist = entry.get("distro", "")
            text = f"{ts} — {human(total)} liberados ({count} itens)"
            if dist:
                text += f" [{dist}]"
            self.list_widget.addItem(text)

    def try_undo(self):
        history = load_history()
        if not history:
            QMessageBox.information(self, APP_NAME, "Nenhuma limpeza no histórico para desfazer.")
            return
        last = history[-1]
        backups = last.get("backups", [])
        if not backups:
            QMessageBox.information(self, APP_NAME, "A última limpeza não possui backups para restaurar (itens foram excluídos permanentemente).")
            return
        restored = 0
        errors = []
        for src, dst in backups:
            if os.path.exists(src):
                errors.append(f"Já existe: {src}")
                continue
            try:
                shutil.move(dst, src)
                restored += 1
            except Exception as e:
                errors.append(f"{src}: {e}")
        msg = f"Restaurados {restored} itens."
        if errors:
            msg += "\n" + "\n".join(errors)
        QMessageBox.information(self, APP_NAME, msg)
        self.refresh()

    def clear_history(self):
        try:
            if HISTORY_FILE.exists():
                HISTORY_FILE.unlink()
            self.refresh()
        except Exception as e:
            QMessageBox.warning(self, APP_NAME, f"Erro ao limpar histórico: {e}")


class Cleaner(QMainWindow):
    def __init__(self):
        super().__init__()
        self.rows = []
        self.config = load_config()
        self.exclusions = self.config.get("exclusions", [])
        self.ignored_dirs = self.config.get("ignored_dirs", [])
        self.setWindowTitle(APP_NAME)
        self.resize(1100, 780)
        self.setMinimumSize(900, 640)
        self.setStyleSheet("""
        QMainWindow, QWidget { background:#101216; color:#e8eaf0; }
        QLabel#title { font-size:28px; font-weight:700; }
        QLabel#subtitle { color:#9ca3af; font-size:13px; }
        QFrame#card { background:#191c23; border:1px solid #292e38; border-radius:14px; }
        QTreeWidget { background:#15181e; border:0; border-radius:10px; padding:8px; }
        QTreeWidget::item { height:38px; }
        QTreeWidget::item:selected { background:#252b36; }
        QHeaderView::section { background:#242932; color:#fff; padding:8px; border:0; }
        QPushButton { background:#252b35; border:0; border-radius:9px; padding:10px 16px; }
        QPushButton:hover { background:#303746; }
        QPushButton#clean { background:#4f8cff; font-weight:700; }
        QPushButton#clean:hover { background:#6b9eff; }
        QPushButton#settings { background:#2a3040; border:0; border-radius:9px; padding:10px 16px; }
        QPushButton#settings:hover { background:#353c4d; }
        QPushButton#history { background:#2a3040; border:0; border-radius:9px; padding:10px 16px; }
        QPushButton#history:hover { background:#353c4d; }
        QPushButton#chart-btn { background:#2a3040; border:0; border-radius:9px; padding:10px 16px; }
        QPushButton#chart-btn:hover { background:#353c4d; }
        QProgressBar { background:#1b1f27; border:0; border-radius:5px; height:9px; }
        QProgressBar::chunk { background:#4f8cff; border-radius:5px; }
        QTabWidget::pane { border:1px solid #292e38; border-radius:10px; background:#191c23; }
        QTabBar::tab { background:#242932; padding:8px 16px; margin-right:2px; border-radius:8px 8px 0 0; }
        QTabBar::tab:selected { background:#191c23; }
        """)

        root = QWidget()
        self.setCentralWidget(root)
        layout = QVBoxLayout(root)
        layout.setContentsMargins(28, 25, 28, 25)
        layout.setSpacing(14)

        title = QLabel("CachyOS Cleaner")
        title.setObjectName("title")
        layout.addWidget(title)
        sub = QLabel(f"Limpeza segura de caches e arquivos temporários{' — ' + DISTRO.upper() if DISTRO != 'unknown' else ''}")
        sub.setObjectName("subtitle")
        layout.addWidget(sub)

        top = QHBoxLayout()
        self.summary = QLabel("Analisando…")
        self.summary.setStyleSheet("font-weight:700;font-size:14px;")
        top.addWidget(self.summary)
        top.addStretch()
        self.history_btn = QPushButton("📋 Histórico")
        self.history_btn.setObjectName("history")
        self.history_btn.clicked.connect(self.show_history)
        top.addWidget(self.history_btn)
        self.chart_btn = QPushButton("📊 Espaço")
        self.chart_btn.setObjectName("chart-btn")
        self.chart_btn.clicked.connect(self.show_chart)
        top.addWidget(self.chart_btn)
        self.settings_btn = QPushButton("⚙ Configurar")
        self.settings_btn.setObjectName("settings")
        self.settings_btn.clicked.connect(self.show_settings)
        top.addWidget(self.settings_btn)
        self.refresh = QPushButton("↻  Analisar novamente")
        self.refresh.clicked.connect(self.start_scan)
        top.addWidget(self.refresh)
        layout.addLayout(top)

        card = QFrame()
        card.setObjectName("card")
        cardlayout = QVBoxLayout(card)
        cardlayout.setContentsMargins(10, 10, 10, 10)
        self.tree = QTreeWidget()
        self.tree.setColumnCount(5)
        self.tree.setHeaderLabels(["", "Categoria", "Local", "Tamanho", "Nível"])
        self.tree.setColumnWidth(0, 50)
        self.tree.setColumnWidth(1, 230)
        self.tree.setColumnWidth(2, 440)
        self.tree.setColumnWidth(3, 100)
        self.tree.setColumnWidth(4, 100)
        self.tree.itemChanged.connect(self.item_changed)
        cardlayout.addWidget(self.tree)
        layout.addWidget(card, 1)

        note = QLabel(
            "Steam, JetBrains e Flatpak são protegidos e nunca são apagados. "
            "Itens selecionados são enviados à lixeira (permite desfazer via Histórico)."
        )
        note.setStyleSheet("color:#9ca3af;")
        layout.addWidget(note)

        bottom = QHBoxLayout()
        self.status = QLabel("Pronto.")
        self.status.setStyleSheet("color:#9ca3af;")
        bottom.addWidget(self.status)
        bottom.addStretch()
        self.progress = QProgressBar()
        self.progress.setRange(0, 0)
        self.progress.setVisible(False)
        self.progress.setFixedWidth(180)
        bottom.addWidget(self.progress)
        self.clean = QPushButton("🧹  Limpar selecionados")
        self.clean.setObjectName("clean")
        self.clean.clicked.connect(self.clean_selected)
        bottom.addWidget(self.clean)
        layout.addLayout(bottom)

        self.start_scan()

    def start_scan(self):
        self.refresh.setEnabled(False)
        self.clean.setEnabled(False)
        self.progress.setVisible(True)
        self.status.setText("Analisando…")
        self.tree.clear()
        self.thread = threading.Thread(target=self.scan_thread, daemon=True)
        self.thread.start()

    def scan_thread(self):
        exclusions = self.exclusions
        ignored_dirs = self.ignored_dirs
        disabled_areas = self.config.get("disabled_areas", [])
        rows = []
        for name, path, kind in SAFE:
            if is_excluded(path, exclusions) or is_ignored(path, ignored_dirs) or is_disabled_area(path, disabled_areas):
                continue
            rows.append((kind, name, str(path), folder_size(path)))
        for name, path, kind in REVIEW:
            if is_excluded(path, exclusions) or is_ignored(path, ignored_dirs) or is_disabled_area(path, disabled_areas):
                continue
            rows.append((kind, name, str(path), folder_size(path)))
        for name, path, kind in PROTECTED:
            if is_disabled_area(path, disabled_areas):
                continue
            rows.append((kind, name, str(path), folder_size(path)))
        if DISTRO in ("arch", "cachyos"):
            for dirpath, dpath, size in get_var_cache_dirs():
                if is_excluded(dpath, exclusions) or is_ignored(dpath, ignored_dirs) or is_disabled_area(dpath, disabled_areas):
                    continue
                rows.append(("safe", f"Cache: {Path(dirpath).name}", dirpath, size))
            for filepath, fpath, size in get_large_files():
                if is_disabled_area(filepath, disabled_areas):
                    continue
                rows.append(("large", f"Arquivo grande: {Path(filepath).name}", filepath, size))
            for kname, kpath, _kind in get_kernels():
                boot_path = KERNEL_DIR / f"extramods-{kname}"
                boot_str = str(boot_path) if boot_path.exists() else "/boot"
                if is_disabled_area(boot_str, disabled_areas):
                    continue
                size = folder_size(boot_path) if boot_path.exists() else 0
                rows.append(("review", f"Kernel: {kname}", boot_str, size))
        QApplication.instance().postEvent(self, ScanEvent(rows))

    def event(self, event):
        if isinstance(event, ScanEvent):
            self.rows = event.rows
            safe_total = 0
            for idx, (kind, name, path, size) in enumerate(self.rows):
                item = QTreeWidgetItem([
                    "☑" if kind == "safe" and size else "☐",
                    name, path, human(size),
                    {"safe": "Seguro", "review": "Revisar", "protected": "Protegido", "large": "Grande"}.get(kind, "Outro")
                ])
                item.setData(0, Qt.ItemDataRole.UserRole, idx)
                item.setData(0, Qt.ItemDataRole.UserRole + 1, kind)
                if kind in ("safe", "review") and size > 0:
                    item.setFlags(item.flags() | Qt.ItemFlag.ItemIsUserCheckable)
                    item.setCheckState(0, Qt.CheckState.Checked)
                    if kind == "safe":
                        safe_total += size
                else:
                    item.setFlags(item.flags() & ~Qt.ItemFlag.ItemIsUserCheckable)
                    item.setForeground(4, Qt.GlobalColor.gray)
                self.tree.addTopLevelItem(item)
            self.summary.setText(
                f"{len(self.rows)} categorias • até {human(safe_total)} em limpeza segura"
            )
            self.status.setText("Análise concluída.")
            self.progress.setVisible(False)
            self.refresh.setEnabled(True)
            self.clean.setEnabled(True)
            return True
        return super().event(event)

    def item_changed(self, item, column):
        pass

    def clean_selected(self):
        selected = []
        for i in range(self.tree.topLevelItemCount()):
            item = self.tree.topLevelItem(i)
            idx = item.data(0, Qt.ItemDataRole.UserRole)
            if idx is None:
                continue
            kind = item.data(0, Qt.ItemDataRole.UserRole + 1)
            name, path, size = self.rows[idx][1], Path(self.rows[idx][2]), self.rows[idx][3]
            if kind in ("safe", "review") and item.checkState(0) == Qt.CheckState.Checked and size > 0:
                selected.append((name, path, size, kind))
        if not selected:
            QMessageBox.information(self, APP_NAME, "Nenhum item selecionado para limpeza.")
            return
        total = sum(x[2] for x in selected)
        text = "\n".join(f"• {n} — {human(s)}" for n, p, s, k in selected)
        answer = QMessageBox.question(self, APP_NAME,
            f"Os seguintes itens serão removidos:\n\n{text}\n\nEspaço estimado: {human(total)}\n\n"
            f"Deseja enviar à lixeira (permite desfazer) ou excluir permanentemente?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No | QMessageBox.StandardButton.Cancel,
            QMessageBox.StandardButton.Yes)
        if answer != QMessageBox.StandardButton.Yes:
            return

        backups = []
        errors = []
        removed = 0
        use_trash = True

        for name, path, size, kind in selected:
            try:
                before = folder_size(path)
                if path.exists() and path.is_dir() and not path.is_symlink():
                    if use_trash:
                        if trash_path(path):
                            backups.append((str(path), None))
                            removed += before
                            continue
                        else:
                            use_trash = False
                    children_moved = 0
                    for child in path.iterdir():
                        if child.is_symlink() or child.is_file():
                            backup_dest = move_to_backup(child)
                            if backup_dest:
                                backups.append((str(child), backup_dest))
                                children_moved += 1
                        elif child.is_dir():
                            backup_dest = move_to_backup(child)
                            if backup_dest:
                                backups.append((str(child), backup_dest))
                                children_moved += 1
                    try:
                        if path.exists() and not any(path.iterdir()):
                            path.rmdir()
                    except Exception:
                        pass
                    removed += before
                elif path.exists() and path.is_file():
                    backup_dest = move_to_backup(path)
                    if backup_dest:
                        backups.append((str(path), backup_dest))
                        removed += size
            except Exception as e:
                errors.append(f"{name}: {e}")

        entry = {
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "total": removed,
            "count": len(backups),
            "distro": DISTRO,
            "backups": backups,
            "items": [n for n, p, s, k in selected],
        }
        save_history(entry)

        if errors:
            QMessageBox.warning(self, APP_NAME,
                f"Limpeza parcial.\n\nLiberado: {human(removed)}\n\n" + "\n".join(errors))
        else:
            QMessageBox.information(self, APP_NAME,
                f"Limpeza concluída.\n\nEspaço processado: {human(removed)}\n"
                f"{len(backups)} itens salvos para possível restauração.")
        self.start_scan()

    def show_settings(self):
        dlg = SettingsDialog(self.config, self.rows, self)
        if dlg.exec() == QDialog.Accepted:
            self.config = load_config()
            self.exclusions = self.config.get("exclusions", [])
            self.ignored_dirs = self.config.get("ignored_dirs", [])
            self.start_scan()

    def show_history(self):
        dlg = HistoryDialog(self)
        dlg.exec()

    def show_chart(self):
        dlg = ChartDialog(self.rows, self)
        dlg.exec()


if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setApplicationName(APP_NAME)
    win = Cleaner()
    win.show()
    sys.exit(app.exec())
