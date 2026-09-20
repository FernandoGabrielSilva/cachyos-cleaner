#!/usr/bin/env python3
import os
import sys
import shutil
import subprocess
import threading
from pathlib import Path

from PySide6.QtCore import Qt, Signal, QObject
from PySide6.QtGui import QFont, QIcon
from PySide6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QLabel, QPushButton, QTreeWidget, QTreeWidgetItem, QProgressBar,
    QMessageBox, QFrame, QCheckBox
)

from PySide6.QtCore import (
    Qt,
    QThread,
    Signal,
    QObject,
    QEvent,
)

APP_NAME = "CachyOS Cleaner"
HOME = Path.home()

SAFE = [
    ("Miniaturas", HOME/".cache/thumbnails"),
    ("Cache Zen", HOME/".cache/zen"),
    ("Cache Vivaldi", HOME/".cache/vivaldi"),
    ("Cache Chrome/Chromium", HOME/".cache/google-chrome"),
    ("Cache Firefox", HOME/".cache/mozilla"),
    ("Cache Brave", HOME/".cache/BraveSoftware"),
    ("Cache node-gyp", HOME/".cache/node-gyp"),
    ("Cache VS Code C/C++", HOME/".cache/vscode-cpptools"),
    ("Cache Tracker3", HOME/".cache/tracker3"),
    ("Cache pip", HOME/".cache/pip"),
]

REVIEW = [
    ("Codex runtimes", HOME/".cache/codex-runtimes"),
    ("Cache NVIDIA", HOME/".cache/nvidia"),
]

PROTECTED = [
    ("Steam", HOME/".local/share/Steam"),
    ("JetBrains Toolbox", HOME/".local/share/JetBrains/Toolbox"),
    ("Flatpak do sistema", Path("/var/lib/flatpak")),
]

def folder_size(path):
    if not path.exists():
        return 0
    total=0
    if path.is_file():
        try: return path.stat().st_size
        except OSError: return 0
    for root, dirs, files in os.walk(path, topdown=True, followlinks=False):
        dirs[:] = [d for d in dirs if not (Path(root)/d).is_symlink()]
        for f in files:
            p=Path(root)/f
            try:
                if not p.is_symlink():
                    total += p.stat().st_size
            except OSError:
                pass
    return total

def human(n):
    n=float(n)
    for unit in ("B","KB","MB","GB","TB"):
        if n < 1024:
            return f"{n:.1f} {unit}"
        n/=1024
    return f"{n:.1f} PB"

class Worker(QObject):
    finished=Signal(object)
    progress=Signal(str)

    def scan(self):
        rows=[]
        for name,path in SAFE:
            self.progress.emit(f"Analisando {name}…")
            rows.append(("safe",name,str(path),folder_size(path)))
        for name,path in REVIEW:
            self.progress.emit(f"Verificando {name}…")
            rows.append(("review",name,str(path),folder_size(path)))
        for name,path in PROTECTED:
            self.progress.emit(f"Verificando {name}…")
            rows.append(("protected",name,str(path),folder_size(path)))
        self.finished.emit(rows)

class Cleaner(QMainWindow):
    def __init__(self):
        super().__init__()
        self.rows=[]
        self.setWindowTitle(APP_NAME)
        self.resize(1050,720)
        self.setMinimumSize(850,600)
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
        QProgressBar { background:#1b1f27; border:0; border-radius:5px; height:9px; }
        QProgressBar::chunk { background:#4f8cff; border-radius:5px; }
        """)

        root=QWidget()
        self.setCentralWidget(root)
        layout=QVBoxLayout(root)
        layout.setContentsMargins(28,25,28,25)
        layout.setSpacing(14)

        title=QLabel("CachyOS Cleaner")
        title.setObjectName("title")
        layout.addWidget(title)
        sub=QLabel("Limpeza segura de caches e arquivos temporários")
        sub.setObjectName("subtitle")
        layout.addWidget(sub)

        top=QHBoxLayout()
        self.summary=QLabel("Analisando…")
        self.summary.setStyleSheet("font-weight:700;font-size:14px;")
        top.addWidget(self.summary)
        top.addStretch()
        self.refresh=QPushButton("↻  Analisar novamente")
        self.refresh.clicked.connect(self.start_scan)
        top.addWidget(self.refresh)
        layout.addLayout(top)

        card=QFrame()
        card.setObjectName("card")
        cardlayout=QVBoxLayout(card)
        cardlayout.setContentsMargins(10,10,10,10)
        self.tree=QTreeWidget()
        self.tree.setColumnCount(5)
        self.tree.setHeaderLabels(["", "Categoria", "Local", "Tamanho", "Nível"])
        self.tree.setColumnWidth(0,50)
        self.tree.setColumnWidth(1,230)
        self.tree.setColumnWidth(2,440)
        self.tree.setColumnWidth(3,100)
        self.tree.setColumnWidth(4,100)
        self.tree.itemChanged.connect(self.item_changed)
        cardlayout.addWidget(self.tree)
        layout.addWidget(card,1)

        note=QLabel("Steam, JetBrains e Flatpak são protegidos e nunca são apagados por este botão.")
        note.setStyleSheet("color:#9ca3af;")
        layout.addWidget(note)

        bottom=QHBoxLayout()
        self.status=QLabel("Pronto.")
        self.status.setStyleSheet("color:#9ca3af;")
        bottom.addWidget(self.status)
        bottom.addStretch()
        self.progress=QProgressBar()
        self.progress.setRange(0,0)
        self.progress.setVisible(False)
        self.progress.setFixedWidth(180)
        bottom.addWidget(self.progress)
        self.clean=QPushButton("🧹  Limpar selecionados")
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
        self.thread=threading.Thread(target=self.scan_thread, daemon=True)
        self.thread.start()

    def scan_thread(self):
        rows=[]
        for kind,name,path in [( "safe",n,p) for n,p in SAFE] + [( "review",n,p) for n,p in REVIEW] + [( "protected",n,p) for n,p in PROTECTED]:
            self.status_signal(kind,name,path)
            rows.append((kind,name,str(path),folder_size(path)))
        QApplication.instance().postEvent(self, ScanEvent(rows))

    def status_signal(self, kind,name,path):
        pass

    def event(self,event):
        if isinstance(event,ScanEvent):
            self.rows=event.rows
            safe_total=0
            for idx,(kind,name,path,size) in enumerate(self.rows):
                item=QTreeWidgetItem(["☑" if kind=="safe" and size else "☐",name,path,human(size),
                                      {"safe":"Seguro","review":"Revisar","protected":"Protegido"}[kind]])
                item.setData(0,Qt.ItemDataRole.UserRole,idx)
                if kind=="safe" and size:
                    item.setFlags(item.flags() | Qt.ItemFlag.ItemIsUserCheckable)
                    item.setCheckState(0,Qt.CheckState.Checked)
                    safe_total += size
                else:
                    item.setFlags(item.flags() & ~Qt.ItemFlag.ItemIsUserCheckable)
                    item.setForeground(4, Qt.GlobalColor.gray)
                self.tree.addTopLevelItem(item)
            self.summary.setText(f"{len(self.rows)} categorias • até {human(safe_total)} em limpeza segura")
            self.status.setText("Análise concluída.")
            self.progress.setVisible(False)
            self.refresh.setEnabled(True)
            self.clean.setEnabled(True)
            return True
        return super().event(event)

    def item_changed(self,item,column):
        pass

    def clean_selected(self):
        selected=[]
        for i in range(self.tree.topLevelItemCount()):
            item=self.tree.topLevelItem(i)
            idx=item.data(0,Qt.ItemDataRole.UserRole)
            if idx is None: continue
            kind,name,path,size=self.rows[idx]
            if kind=="safe" and item.checkState(0)==Qt.CheckState.Checked and size>0:
                selected.append((name,Path(path),size))
        if not selected:
            QMessageBox.information(self,APP_NAME,"Nenhum cache seguro selecionado.")
            return
        total=sum(x[2] for x in selected)
        text="\n".join(f"• {n} — {human(s)}" for n,p,s in selected)
        answer=QMessageBox.question(self,APP_NAME,
            f"Os seguintes caches serão removidos:\n\n{text}\n\nEspaço estimado: {human(total)}\n\nContinuar?",
            QMessageBox.StandardButton.Yes|QMessageBox.StandardButton.No)
        if answer != QMessageBox.StandardButton.Yes:
            return
        errors=[]
        removed=0
        for name,path,size in selected:
            try:
                before=folder_size(path)
                if path.exists() and path.is_dir() and not path.is_symlink():
                    for child in path.iterdir():
                        if child.is_symlink() or child.is_file():
                            child.unlink()
                        elif child.is_dir():
                            shutil.rmtree(child)
                removed += before
            except Exception as e:
                errors.append(f"{name}: {e}")
        if errors:
            QMessageBox.warning(self,APP_NAME,f"Limpeza parcial.\n\nLiberado: {human(removed)}\n\n" + "\n".join(errors))
        else:
            QMessageBox.information(self,APP_NAME,f"Limpeza concluída.\n\nEspaço processado: {human(removed)}")
        self.start_scan()

class ScanEvent(QEvent):
    TYPE=QEvent.Type(QEvent.registerEventType())
    def __init__(self,rows):
        super().__init__(self.TYPE)
        self.rows=rows

if __name__=="__main__":
    app=QApplication(sys.argv)
    app.setApplicationName(APP_NAME)
    win=Cleaner()
    win.show()
    sys.exit(app.exec())
