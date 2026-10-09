#!/usr/bin/env python3
"""
Alien App Center — Fast, beautiful, modern software store for Alien OS Lite.
Inspired by Pop!_OS Pop Shop and LXQt aesthetics.
"""

import sys
import os
import subprocess
import threading
import yaml
import shutil
import urllib.request
from PyQt6.QtCore import Qt, QThread, pyqtSignal, QSize, QTimer
from PyQt6.QtGui import QIcon, QFont, QPixmap, QColor
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QStackedWidget, QPushButton, QLabel, QLineEdit, QScrollArea,
    QGridLayout, QFrame, QProgressBar, QMessageBox, QListWidget,
    QListWidgetItem, QTextEdit, QSizePolicy, QDialog
)

# Configuration & Paths
APP_DIR = os.path.dirname(os.path.abspath(__file__))
PICKS_FILE = os.path.join(APP_DIR, "alien-picks.yaml")
BUNDLES_DIR = os.path.join(APP_DIR, "bundles")

# Tokens / Theming
COLOR_ACCENT = "#4F8EF7"
COLOR_DARK_BG = "#050814"
COLOR_CARD_BG = "#1A1D2C"
COLOR_SIDEBAR_BG = "#0E1120"
COLOR_TEXT = "#F0F0F0"
COLOR_TEXT_MUTED = "#8E93A8"
COLOR_SUCCESS = "#2ECC71"
COLOR_WARNING = "#F1C40F"
COLOR_ERROR = "#E74C3C"
FONT_UI = "DejaVu Sans"

STYLESHEET = f"""
QMainWindow {{
    background-color: {COLOR_DARK_BG};
    color: {COLOR_TEXT};
}}
QWidget {{
    font-family: "{FONT_UI}", sans-serif;
    color: {COLOR_TEXT};
}}
QFrame#sidebar {{
    background-color: {COLOR_SIDEBAR_BG};
    border-right: 1px solid #232738;
}}
QPushButton.sidebar-btn {{
    background-color: transparent;
    color: {COLOR_TEXT_MUTED};
    text-align: left;
    padding: 12px 18px;
    font-size: 13px;
    font-weight: 500;
    border: none;
    border-radius: 8px;
    margin: 3px 10px;
}}
QPushButton.sidebar-btn:hover {{
    background-color: #1E2338;
    color: {COLOR_TEXT};
}}
QPushButton.sidebar-btn:checked {{
    background-color: {COLOR_ACCENT};
    color: #FFFFFF;
    font-weight: bold;
}}
QLineEdit#search-bar {{
    background-color: #151828;
    border: 1px solid #282C40;
    border-radius: 8px;
    padding: 8px 14px;
    color: {COLOR_TEXT};
    font-size: 13px;
}}
QLineEdit#search-bar:focus {{
    border: 1px solid {COLOR_ACCENT};
}}
QFrame.app-card {{
    background-color: {COLOR_CARD_BG};
    border-radius: 10px;
    border: 1px solid #252A40;
    padding: 12px;
}}
QFrame.app-card:hover {{
    border: 1px solid {COLOR_ACCENT};
    background-color: #21263B;
}}
QFrame.hero-card {{
    background-color: qlineargradient(x1:0, y1:0, x2:1, y2:1, stop:0 #1E2B4C, stop:1 #13172C);
    border-radius: 12px;
    border: 1px solid #334370;
    padding: 16px;
}}
QPushButton.action-btn {{
    background-color: {COLOR_ACCENT};
    color: #FFFFFF;
    border-radius: 6px;
    padding: 6px 14px;
    font-weight: bold;
    font-size: 12px;
    border: none;
}}
QPushButton.action-btn:hover {{
    background-color: #6AA2FC;
}}
QPushButton.action-btn-remove {{
    background-color: #38242A;
    color: {COLOR_ERROR};
    border: 1px solid {COLOR_ERROR};
    border-radius: 6px;
    padding: 6px 14px;
    font-size: 12px;
}}
QPushButton.action-btn-remove:hover {{
    background-color: {COLOR_ERROR};
    color: #FFFFFF;
}}
QPushButton.action-btn-open {{
    background-color: #1A382A;
    color: {COLOR_SUCCESS};
    border: 1px solid {COLOR_SUCCESS};
    border-radius: 6px;
    padding: 6px 14px;
    font-size: 12px;
}}
QPushButton.action-btn-open:hover {{
    background-color: {COLOR_SUCCESS};
    color: #FFFFFF;
}}
QProgressBar {{
    background-color: #161928;
    border-radius: 4px;
    border: 1px solid #252A40;
    text-align: center;
    color: #FFFFFF;
    font-size: 11px;
}}
QProgressBar::chunk {{
    background-color: {COLOR_ACCENT};
    border-radius: 4px;
}}
QScrollArea {{
    border: none;
    background-color: transparent;
}}
QScrollBar:vertical {{
    background-color: {COLOR_DARK_BG};
    width: 8px;
    margin: 0;
}}
QScrollBar::handle:vertical {{
    background-color: #2D334C;
    border-radius: 4px;
    min-height: 20px;
}}
QScrollBar::handle:vertical:hover {{
    background-color: {COLOR_ACCENT};
}}
"""


class PackageWorker(QThread):
    """Background worker for apt/packagekit/bundle script operations."""
    output_signal = pyqtSignal(str)
    progress_signal = pyqtSignal(int)
    finished_signal = pyqtSignal(bool, str)

    def __init__(self, action, package_name, custom_script=None):
        super().__init__()
        self.action = action
        self.package_name = package_name
        self.custom_script = custom_script

    def run(self):
        try:
            if self.custom_script:
                cmd = ["pkexec", "bash", self.custom_script]
            elif self.action == "install":
                cmd = ["pkexec", "apt-get", "install", "-y", self.package_name]
            elif self.action == "remove":
                cmd = ["pkexec", "apt-get", "remove", "-y", self.package_name]
            elif self.action == "update_all":
                cmd = ["pkexec", "apt-get", "upgrade", "-y"]
            elif self.action == "refresh":
                cmd = ["pkexec", "apt-get", "update"]
            else:
                self.finished_signal.emit(False, "Unknown action")
                return

            self.output_signal.emit(f"Executing: {' '.join(cmd)}\n")
            proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
            
            for line in proc.stdout:
                self.output_signal.emit(line)
                if "%" in line:
                    for part in line.split():
                        if part.endswith("%") and part[:-1].isdigit():
                            self.progress_signal.emit(int(part[:-1]))

            proc.wait()
            success = (proc.returncode == 0)
            self.finished_signal.emit(success, "Operation completed successfully" if success else f"Exited with code {proc.returncode}")
        except Exception as e:
            self.finished_signal.emit(False, str(e))


class SearchWorker(QThread):
    """Background search worker that queries apt-cache and appstreamcli."""
    results_signal = pyqtSignal(list)

    def __init__(self, query):
        super().__init__()
        self.query = query

    def run(self):
        results = []
        if not self.query or len(self.query) < 2:
            self.results_signal.emit([])
            return

        # 1. Search apt-cache
        try:
            out = subprocess.check_output(["apt-cache", "search", "--names-only", self.query], text=True, timeout=5)
            for line in out.strip().split("\n")[:25]:
                if " - " in line:
                    pkg, desc = line.split(" - ", 1)
                    results.append({
                        "id": pkg.strip(),
                        "package": pkg.strip(),
                        "name": pkg.strip(),
                        "summary": desc.strip(),
                        "description": desc.strip(),
                        "icon": "application-x-executable",
                        "source": "Debian",
                        "is_preinstalled": False
                    })
        except Exception:
            pass

        self.results_signal.emit(results)


def is_package_installed(pkg_name):
    """Check if a Debian package is installed."""
    if not pkg_name:
        return False
    try:
        res = subprocess.run(["dpkg", "-s", pkg_name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return res.returncode == 0
    except Exception:
        return False


def is_online():
    """Quick non-blocking check for internet connectivity."""
    try:
        urllib.request.urlopen("https://deb.debian.org", timeout=1.5)
        return True
    except Exception:
        return False


class OperationDialog(QDialog):
    """Real-time log and progress dialog for app install/remove/bundle execution."""
    def __init__(self, title, worker, parent=None):
        super().__init__(parent)
        self.setWindowTitle(title)
        self.setFixedSize(580, 360)
        self.setStyleSheet(f"background-color: {COLOR_DARK_BG}; color: {COLOR_TEXT};")
        self.worker = worker

        layout = QVBoxLayout(self)
        self.title_label = QLabel(f"<b>{title}</b>")
        self.title_label.setStyleSheet("font-size: 14px; margin-bottom: 5px;")
        layout.addWidget(self.title_label)

        self.progress_bar = QProgressBar()
        self.progress_bar.setRange(0, 100)
        self.progress_bar.setValue(0)
        layout.addWidget(self.progress_bar)

        self.log_view = QTextEdit()
        self.log_view.setReadOnly(True)
        self.log_view.setStyleSheet("background-color: #0A0D1A; border: 1px solid #232738; font-family: monospace; font-size: 11px;")
        layout.addWidget(self.log_view)

        btn_layout = QHBoxLayout()
        self.close_btn = QPushButton("Running...")
        self.close_btn.setEnabled(False)
        self.close_btn.setStyleSheet(f"background-color: {COLOR_ACCENT}; color: white; padding: 6px 16px; border-radius: 6px;")
        self.close_btn.clicked.connect(self.accept)
        btn_layout.addStretch()
        btn_layout.addWidget(self.close_btn)
        layout.addLayout(btn_layout)

        self.worker.output_signal.connect(self.append_log)
        self.worker.progress_signal.connect(self.progress_bar.setValue)
        self.worker.finished_signal.connect(self.on_finished)
        self.worker.start()

    def append_log(self, text):
        self.log_view.append(text.strip())

    def on_finished(self, success, msg):
        self.progress_bar.setValue(100)
        self.close_btn.setEnabled(True)
        self.close_btn.setText("Close")
        if success:
            self.title_label.setText(f"<span style='color:{COLOR_SUCCESS};'>✓ Completed Successfully</span>")
        else:
            self.title_label.setText(f"<span style='color:{COLOR_ERROR};'>✗ Operation Failed: {msg}</span>")


class AppCenter(QMainWindow):
    def __init__(self, start_tab="home"):
        super().__init__()
        self.setWindowTitle("Alien App Center")
        self.resize(1020, 680)
        self.setStyleSheet(STYLESHEET)

        # Window Icon
        icon_path = "/usr/share/icons/hicolor/64x64/apps/alien-launcher.png"
        if os.path.exists(icon_path):
            self.setWindowIcon(QIcon(icon_path))

        self.load_picks()
        self.active_worker = None
        self.search_worker = None
        self.network_online = True

        self.init_ui(start_tab)
        
        # Check network status periodically
        QTimer.singleShot(100, self.check_network)

    def load_picks(self):
        """Load curated applications and categories from alien-picks.yaml."""
        self.categories = []
        self.bundles = []
        self.all_apps = []

        if os.path.exists(PICKS_FILE):
            try:
                with open(PICKS_FILE, "r") as f:
                    data = yaml.safe_load(f)
                    self.categories = data.get("categories", [])
                    self.bundles = data.get("bundles", [])
                    for cat in self.categories:
                        for app in cat.get("apps", []):
                            app["category_id"] = cat.get("id")
                            self.all_apps.append(app)
            except Exception as e:
                print(f"Error loading picks: {e}")

    def init_ui(self, start_tab):
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        main_layout = QHBoxLayout(main_widget)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(0)

        # Sidebar
        sidebar = QFrame()
        sidebar.setObjectName("sidebar")
        sidebar.setFixedWidth(220)
        sidebar_layout = QVBoxLayout(sidebar)
        sidebar_layout.setContentsMargins(8, 16, 8, 16)
        sidebar_layout.setSpacing(6)

        # Header Logo & Title
        header_layout = QHBoxLayout()
        header_layout.setContentsMargins(10, 0, 10, 15)
        logo_label = QLabel()
        logo_path = "/usr/share/icons/hicolor/64x64/apps/alien-launcher.png"
        if os.path.exists(logo_path):
            logo_pix = QPixmap(logo_path).scaled(32, 32, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)
            logo_label.setPixmap(logo_pix)
        header_layout.addWidget(logo_label)

        title_label = QLabel("App Center")
        title_label.setStyleSheet("font-size: 16px; font-weight: bold; color: #FFFFFF;")
        header_layout.addWidget(title_label)
        header_layout.addStretch()
        sidebar_layout.addLayout(header_layout)

        # Sidebar Navigation Buttons
        self.nav_buttons = {}
        nav_items = [
            ("home", "🏠  Home"),
            ("categories", "📁  Categories"),
            ("installed", "⬇️  Installed"),
            ("updates", "🔄  Updates"),
            ("bundles", "📦  Bundles"),
            ("settings", "⚙️  Settings")
        ]

        for tab_id, text in nav_items:
            btn = QPushButton(text)
            btn.setProperty("class", "sidebar-btn")
            btn.setCheckable(True)
            btn.clicked.connect(lambda checked, t=tab_id: self.switch_page(t))
            sidebar_layout.addWidget(btn)
            self.nav_buttons[tab_id] = btn

        sidebar_layout.addStretch()

        # Offline Status Indicator
        self.offline_badge = QLabel("🌐 Online")
        self.offline_badge.setStyleSheet(f"color: {COLOR_SUCCESS}; font-size: 11px; padding: 10px;")
        sidebar_layout.addWidget(self.offline_badge)

        main_layout.addWidget(sidebar)

        # Content Area
        content_container = QWidget()
        content_layout = QVBoxLayout(content_container)
        content_layout.setContentsMargins(20, 15, 20, 15)
        content_layout.setSpacing(15)

        # Top Bar: Search Bar
        top_bar = QHBoxLayout()
        self.search_bar = QLineEdit()
        self.search_bar.setObjectName("search-bar")
        self.search_bar.setPlaceholderText("🔍  Search applications, packages, and tools...")
        self.search_bar.textChanged.connect(self.on_search_changed)
        top_bar.addWidget(self.search_bar)
        content_layout.addLayout(top_bar)

        # Offline Alert Banner
        self.offline_banner = QLabel("⚠️ Offline Mode: Connected repositories unavailable. Installed and cached applications remain functional.")
        self.offline_banner.setStyleSheet(f"background-color: #382B14; color: {COLOR_WARNING}; border: 1px solid {COLOR_WARNING}; border-radius: 6px; padding: 8px 12px; font-size: 12px;")
        self.offline_banner.setVisible(False)
        content_layout.addWidget(self.offline_banner)

        # Stacked Pages
        self.stack = QStackedWidget()
        
        self.page_home = self.create_home_page()
        self.page_categories = self.create_categories_page()
        self.page_category_detail = QWidget() # dynamically built
        self.page_installed = self.create_installed_page()
        self.page_updates = self.create_updates_page()
        self.page_bundles = self.create_bundles_page()
        self.page_settings = self.create_settings_page()
        self.page_app_detail = QWidget() # dynamically built
        self.page_search_results = self.create_search_results_page()

        self.stack.addWidget(self.page_home)             # 0
        self.stack.addWidget(self.page_categories)       # 1
        self.stack.addWidget(self.page_category_detail) # 2
        self.stack.addWidget(self.page_installed)        # 3
        self.stack.addWidget(self.page_updates)          # 4
        self.stack.addWidget(self.page_bundles)          # 5
        self.stack.addWidget(self.page_settings)         # 6
        self.stack.addWidget(self.page_app_detail)       # 7
        self.stack.addWidget(self.page_search_results)   # 8

        content_layout.addWidget(self.stack)
        main_layout.addWidget(content_container)

        self.switch_page(start_tab)

    def check_network(self):
        def _check():
            online = is_online()
            self.network_online = online
            QTimer.singleShot(0, self._apply_network_state)
        threading.Thread(target=_check, daemon=True).start()

    def _apply_network_state(self):
        if self.network_online:
            self.offline_badge.setText("🌐 Online")
            self.offline_badge.setStyleSheet(f"color: {COLOR_SUCCESS}; font-size: 11px; padding: 10px;")
            self.offline_banner.setVisible(False)
        else:
            self.offline_badge.setText("⚠️ Offline")
            self.offline_badge.setStyleSheet(f"color: {COLOR_WARNING}; font-size: 11px; padding: 10px;")
            self.offline_banner.setVisible(True)

    def switch_page(self, page_name):
        self.search_bar.blockSignals(True)
        if page_name != "search":
            self.search_bar.clear()
        self.search_bar.blockSignals(False)

        for btn in self.nav_buttons.values():
            btn.setChecked(False)

        if page_name == "home":
            self.nav_buttons["home"].setChecked(True)
            self.stack.setCurrentIndex(0)
        elif page_name == "categories":
            self.nav_buttons["categories"].setChecked(True)
            self.stack.setCurrentIndex(1)
        elif page_name == "installed":
            self.nav_buttons["installed"].setChecked(True)
            self.refresh_installed_page()
            self.stack.setCurrentIndex(3)
        elif page_name == "updates":
            self.nav_buttons["updates"].setChecked(True)
            self.refresh_updates_page()
            self.stack.setCurrentIndex(4)
        elif page_name == "bundles":
            self.nav_buttons["bundles"].setChecked(True)
            self.stack.setCurrentIndex(5)
        elif page_name == "settings":
            self.nav_buttons["settings"].setChecked(True)
            self.stack.setCurrentIndex(6)

    def create_home_page(self):
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        container = QWidget()
        layout = QVBoxLayout(container)
        layout.setSpacing(22)

        # Featured Row Header
        featured_header = QLabel("<b>Alien Picks & Featured</b>")
        featured_header.setStyleSheet("font-size: 18px; color: #FFFFFF;")
        layout.addWidget(featured_header)

        # Hero Cards Row (Horizontal Scroll / Row)
        hero_layout = QHBoxLayout()
        featured_apps = [a for a in self.all_apps if a.get("featured", False)][:3]
        for app in featured_apps:
            hero_card = self.create_hero_card(app)
            hero_layout.addWidget(hero_card)
        layout.addLayout(hero_layout)

        # Category Sections
        for cat in self.categories:
            cat_header_layout = QHBoxLayout()
            cat_title = QLabel(f"<b>{cat.get('name')}</b>")
            cat_title.setStyleSheet("font-size: 16px; color: #FFFFFF;")
            cat_header_layout.addWidget(cat_title)
            cat_header_layout.addStretch()

            view_all_btn = QPushButton("View All →")
            view_all_btn.setStyleSheet(f"background: transparent; color: {COLOR_ACCENT}; font-size: 12px; border: none;")
            view_all_btn.clicked.connect(lambda _, c=cat: self.show_category_detail(c))
            cat_header_layout.addWidget(view_all_btn)
            layout.addLayout(cat_header_layout)

            # Horizontal cards grid
            grid = QGridLayout()
            grid.setSpacing(10)
            apps = cat.get("apps", [])[:4]
            for idx, app in enumerate(apps):
                card = self.create_app_card(app)
                grid.addWidget(card, idx // 2, idx % 2)
            layout.addLayout(grid)

        layout.addStretch()
        scroll.setWidget(container)
        return scroll

    def create_hero_card(self, app):
        frame = QFrame()
        frame.setProperty("class", "hero-card")
        layout = QVBoxLayout(frame)
        layout.setSpacing(8)

        top_layout = QHBoxLayout()
        icon_lbl = QLabel()
        icon = QIcon.fromTheme(app.get("icon", "application-x-executable"))
        icon_lbl.setPixmap(icon.pixmap(48, 48))
        top_layout.addWidget(icon_lbl)

        info_layout = QVBoxLayout()
        name_lbl = QLabel(f"<b>{app.get('name')}</b>")
        name_lbl.setStyleSheet("font-size: 14px; color: #FFFFFF;")
        summary_lbl = QLabel(app.get("summary", ""))
        summary_lbl.setStyleSheet(f"color: {COLOR_TEXT_MUTED}; font-size: 11px;")
        summary_lbl.setWordWrap(True)
        info_layout.addWidget(name_lbl)
        info_layout.addWidget(summary_lbl)
        top_layout.addLayout(info_layout)
        layout.addLayout(top_layout)

        btn_layout = QHBoxLayout()
        btn_layout.addStretch()
        action_btn = self.create_action_button(app)
        btn_layout.addWidget(action_btn)
        layout.addLayout(btn_layout)

        frame.mousePressEvent = lambda _: self.show_app_detail(app)
        return frame

    def create_app_card(self, app):
        frame = QFrame()
        frame.setProperty("class", "app-card")
        layout = QHBoxLayout(frame)
        layout.setSpacing(12)

        icon_lbl = QLabel()
        icon = QIcon.fromTheme(app.get("icon", "application-x-executable"))
        icon_lbl.setPixmap(icon.pixmap(36, 36))
        layout.addWidget(icon_lbl)

        info_layout = QVBoxLayout()
        name_lbl = QLabel(f"<b>{app.get('name')}</b>")
        name_lbl.setStyleSheet("font-size: 13px; color: #FFFFFF;")
        summary_lbl = QLabel(app.get("summary", ""))
        summary_lbl.setStyleSheet(f"color: {COLOR_TEXT_MUTED}; font-size: 11px;")
        summary_lbl.setWordWrap(True)
        info_layout.addWidget(name_lbl)
        info_layout.addWidget(summary_lbl)
        layout.addLayout(info_layout)

        layout.addStretch()
        action_btn = self.create_action_button(app)
        layout.addWidget(action_btn)

        frame.mousePressEvent = lambda _: self.show_app_detail(app)
        return frame

    def create_action_button(self, app):
        pkg = app.get("package")
        installed = app.get("is_preinstalled", False) or is_package_installed(pkg)

        # Developer Stack special button
        if app.get("id") in ["postgresql", "mongodb-org-server"]:
            btn = QPushButton("Dev Services")
            btn.setProperty("class", "action-btn-open")
            btn.clicked.connect(lambda: subprocess.Popen(["alien-dev-services"]))
            return btn

        if installed:
            btn = QPushButton("Open")
            btn.setProperty("class", "action-btn-open")
            btn.clicked.connect(lambda: self.launch_app(app))
            return btn
        else:
            btn = QPushButton("Install")
            btn.setProperty("class", "action-btn")
            btn.clicked.connect(lambda: self.perform_package_action("install", app))
            return btn

    def launch_app(self, app):
        exec_cmd = app.get("exec", "")
        if exec_cmd:
            subprocess.Popen(exec_cmd, shell=True)

    def perform_package_action(self, action, app):
        pkg = app.get("package", "")
        if not pkg:
            return
        worker = PackageWorker(action, pkg)
        dialog = OperationDialog(f"{action.capitalize()}ing {app.get('name')}...", worker, self)
        dialog.exec()
        self.switch_page("installed" if action == "install" else "home")

    def create_categories_page(self):
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        container = QWidget()
        layout = QVBoxLayout(container)
        layout.setSpacing(15)

        title = QLabel("<b>Categories</b>")
        title.setStyleSheet("font-size: 18px; color: #FFFFFF; margin-bottom: 10px;")
        layout.addWidget(title)

        grid = QGridLayout()
        grid.setSpacing(12)

        for idx, cat in enumerate(self.categories):
            frame = QFrame()
            frame.setProperty("class", "app-card")
            cat_layout = QHBoxLayout(frame)
            cat_layout.setSpacing(14)

            icon_lbl = QLabel()
            icon = QIcon.fromTheme(cat.get("icon", "applications-other"))
            icon_lbl.setPixmap(icon.pixmap(32, 32))
            cat_layout.addWidget(icon_lbl)

            info_layout = QVBoxLayout()
            name_lbl = QLabel(f"<b>{cat.get('name')}</b>")
            name_lbl.setStyleSheet("font-size: 14px; color: #FFFFFF;")
            summary_lbl = QLabel(f"{len(cat.get('apps', []))} apps — {cat.get('summary', '')}")
            summary_lbl.setStyleSheet(f"color: {COLOR_TEXT_MUTED}; font-size: 11px;")
            summary_lbl.setWordWrap(True)
            info_layout.addWidget(name_lbl)
            info_layout.addWidget(summary_lbl)
            cat_layout.addLayout(info_layout)

            frame.mousePressEvent = lambda _, c=cat: self.show_category_detail(c)
            grid.addWidget(frame, idx // 2, idx % 2)

        layout.addLayout(grid)
        layout.addStretch()
        scroll.setWidget(container)
        return scroll

    def show_category_detail(self, cat):
        container = QWidget()
        layout = QVBoxLayout(container)
        layout.setSpacing(15)

        # Header with back button
        header_layout = QHBoxLayout()
        back_btn = QPushButton("← Back to Categories")
        back_btn.setStyleSheet(f"background: transparent; color: {COLOR_ACCENT}; font-size: 13px; border: none;")
        back_btn.clicked.connect(lambda: self.switch_page("categories"))
        header_layout.addWidget(back_btn)
        header_layout.addStretch()
        layout.addLayout(header_layout)

        cat_title = QLabel(f"<b>{cat.get('name')}</b>")
        cat_title.setStyleSheet("font-size: 20px; color: #FFFFFF;")
        layout.addWidget(cat_title)

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        grid_widget = QWidget()
        grid = QGridLayout(grid_widget)
        grid.setSpacing(10)

        for idx, app in enumerate(cat.get("apps", [])):
            card = self.create_app_card(app)
            grid.addWidget(card, idx // 2, idx % 2)

        scroll.setWidget(grid_widget)
        layout.addWidget(scroll)

        # Replace index 2
        self.stack.removeWidget(self.page_category_detail)
        self.page_category_detail = container
        self.stack.insertWidget(2, self.page_category_detail)
        self.stack.setCurrentIndex(2)

    def show_app_detail(self, app):
        container = QWidget()
        layout = QVBoxLayout(container)
        layout.setSpacing(20)

        # Header back button
        header_layout = QHBoxLayout()
        back_btn = QPushButton("← Back")
        back_btn.setStyleSheet(f"background: transparent; color: {COLOR_ACCENT}; font-size: 13px; border: none;")
        back_btn.clicked.connect(lambda: self.stack.setCurrentIndex(0))
        header_layout.addWidget(back_btn)
        header_layout.addStretch()
        layout.addLayout(header_layout)

        # Hero info section
        hero = QFrame()
        hero.setProperty("class", "hero-card")
        hero_layout = QHBoxLayout(hero)
        hero_layout.setSpacing(20)

        icon_lbl = QLabel()
        icon = QIcon.fromTheme(app.get("icon", "application-x-executable"))
        icon_lbl.setPixmap(icon.pixmap(72, 72))
        hero_layout.addWidget(icon_lbl)

        info_layout = QVBoxLayout()
        name_lbl = QLabel(f"<b>{app.get('name')}</b>")
        name_lbl.setStyleSheet("font-size: 22px; color: #FFFFFF;")
        summary_lbl = QLabel(app.get("summary", ""))
        summary_lbl.setStyleSheet(f"color: {COLOR_TEXT_MUTED}; font-size: 13px;")

        meta_lbl = QLabel(f"Version: <b>{app.get('version', 'N/A')}</b>  •  Size: <b>{app.get('size', 'N/A')}</b>  •  Source: <span style='color:{COLOR_ACCENT};'>{app.get('source', 'Debian')}</span>")
        meta_lbl.setStyleSheet("font-size: 11px; margin-top: 5px;")

        info_layout.addWidget(name_lbl)
        info_layout.addWidget(summary_lbl)
        info_layout.addWidget(meta_lbl)
        hero_layout.addLayout(info_layout)

        # Action Buttons
        pkg = app.get("package")
        installed = app.get("is_preinstalled", False) or is_package_installed(pkg)

        btn_box = QVBoxLayout()
        if app.get("id") in ["postgresql", "mongodb-org-server"]:
            open_btn = QPushButton("Open Dev Services")
            open_btn.setProperty("class", "action-btn-open")
            open_btn.clicked.connect(lambda: subprocess.Popen(["alien-dev-services"]))
            btn_box.addWidget(open_btn)
        elif installed:
            open_btn = QPushButton("Open Application")
            open_btn.setProperty("class", "action-btn-open")
            open_btn.clicked.connect(lambda: self.launch_app(app))
            btn_box.addWidget(open_btn)

            if not app.get("is_preinstalled", False):
                remove_btn = QPushButton("Remove")
                remove_btn.setProperty("class", "action-btn-remove")
                remove_btn.clicked.connect(lambda: self.perform_package_action("remove", app))
                btn_box.addWidget(remove_btn)
        else:
            install_btn = QPushButton("Install")
            install_btn.setProperty("class", "action-btn")
            install_btn.clicked.connect(lambda: self.perform_package_action("install", app))
            btn_box.addWidget(install_btn)

        hero_layout.addLayout(btn_box)
        layout.addWidget(hero)

        # Description
        desc_header = QLabel("<b>Description</b>")
        desc_header.setStyleSheet("font-size: 16px; color: #FFFFFF;")
        layout.addWidget(desc_header)

        desc_lbl = QLabel(app.get("description", app.get("summary", "")))
        desc_lbl.setStyleSheet(f"color: {COLOR_TEXT}; font-size: 13px; line-height: 1.5;")
        desc_lbl.setWordWrap(True)
        layout.addWidget(desc_lbl)

        layout.addStretch()

        self.stack.removeWidget(self.page_app_detail)
        self.page_app_detail = container
        self.stack.insertWidget(7, self.page_app_detail)
        self.stack.setCurrentIndex(7)

    def create_installed_page(self):
        self.installed_container = QWidget()
        self.installed_layout = QVBoxLayout(self.installed_container)
        self.refresh_installed_page()
        return self.installed_container

    def refresh_installed_page(self):
        # Clear existing
        while self.installed_layout.count():
            item = self.installed_layout.takeAt(0)
            if item.widget():
                item.widget().deleteLater()

        title = QLabel("<b>Installed Applications</b>")
        title.setStyleSheet("font-size: 18px; color: #FFFFFF; margin-bottom: 10px;")
        self.installed_layout.addWidget(title)

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        list_widget = QWidget()
        layout = QVBoxLayout(list_widget)
        layout.setSpacing(10)

        count = 0
        for app in self.all_apps:
            pkg = app.get("package")
            if app.get("is_preinstalled", False) or is_package_installed(pkg):
                card = self.create_installed_app_card(app)
                layout.addWidget(card)
                count += 1

        if count == 0:
            none_lbl = QLabel("No user-installed applications found.")
            none_lbl.setStyleSheet(f"color: {COLOR_TEXT_MUTED}; font-size: 13px;")
            layout.addWidget(none_lbl)

        layout.addStretch()
        scroll.setWidget(list_widget)
        self.installed_layout.addWidget(scroll)

    def create_installed_app_card(self, app):
        frame = QFrame()
        frame.setProperty("class", "app-card")
        layout = QHBoxLayout(frame)
        layout.setSpacing(12)

        icon_lbl = QLabel()
        icon = QIcon.fromTheme(app.get("icon", "application-x-executable"))
        icon_lbl.setPixmap(icon.pixmap(36, 36))
        layout.addWidget(icon_lbl)

        info = QVBoxLayout()
        name_lbl = QLabel(f"<b>{app.get('name')}</b>")
        name_lbl.setStyleSheet("font-size: 13px; color: #FFFFFF;")
        summary_lbl = QLabel(f"{app.get('summary', '')} • Size: {app.get('installed_size', app.get('size', 'N/A'))}")
        summary_lbl.setStyleSheet(f"color: {COLOR_TEXT_MUTED}; font-size: 11px;")
        info.addWidget(name_lbl)
        info.addWidget(summary_lbl)
        layout.addLayout(info)

        layout.addStretch()

        if app.get("id") in ["postgresql", "mongodb-org-server"]:
            dev_btn = QPushButton("Dev Services")
            dev_btn.setProperty("class", "action-btn-open")
            dev_btn.clicked.connect(lambda: subprocess.Popen(["alien-dev-services"]))
            layout.addWidget(dev_btn)
        else:
            open_btn = QPushButton("Open")
            open_btn.setProperty("class", "action-btn-open")
            open_btn.clicked.connect(lambda: self.launch_app(app))
            layout.addWidget(open_btn)

            if not app.get("is_preinstalled", False):
                remove_btn = QPushButton("Remove")
                remove_btn.setProperty("class", "action-btn-remove")
                remove_btn.clicked.connect(lambda: self.perform_package_action("remove", app))
                layout.addWidget(remove_btn)

        return frame

    def create_updates_page(self):
        self.updates_container = QWidget()
        self.updates_layout = QVBoxLayout(self.updates_container)
        self.refresh_updates_page()
        return self.updates_container

    def refresh_updates_page(self):
        while self.updates_layout.count():
            item = self.updates_layout.takeAt(0)
            if item.widget():
                item.widget().deleteLater()

        header = QHBoxLayout()
        title = QLabel("<b>Software Updates</b>")
        title.setStyleSheet("font-size: 18px; color: #FFFFFF;")
        header.addWidget(title)
        header.addStretch()

        update_all_btn = QPushButton("Update All")
        update_all_btn.setProperty("class", "action-btn")
        update_all_btn.clicked.connect(self.perform_update_all)
        header.addWidget(update_all_btn)
        self.updates_layout.addLayout(header)

        # Scan for upgradable packages
        upgradable = []
        try:
            out = subprocess.check_output(["apt", "list", "--upgradable"], stderr=subprocess.DEVNULL, text=True)
            for line in out.strip().split("\n"):
                if "/" in line and "[" in line:
                    upgradable.append(line.strip())
        except Exception:
            pass

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        list_widget = QWidget()
        layout = QVBoxLayout(list_widget)
        layout.setSpacing(10)

        if upgradable:
            status = QLabel(f"<b>{len(upgradable)} update(s) available:</b>")
            status.setStyleSheet(f"color: {COLOR_WARNING}; font-size: 13px;")
            layout.addWidget(status)

            for item in upgradable:
                card = QFrame()
                card.setProperty("class", "app-card")
                c_layout = QHBoxLayout(card)
                lbl = QLabel(item)
                lbl.setStyleSheet("font-size: 12px; font-family: monospace;")
                c_layout.addWidget(lbl)
                layout.addWidget(card)
        else:
            status = QLabel("✓ All applications and system packages are up to date.")
            status.setStyleSheet(f"color: {COLOR_SUCCESS}; font-size: 14px; margin-top: 20px;")
            layout.addWidget(status)

        layout.addStretch()
        scroll.setWidget(list_widget)
        self.updates_layout.addWidget(scroll)

    def perform_update_all(self):
        worker = PackageWorker("update_all", "")
        dialog = OperationDialog("Updating System Software...", worker, self)
        dialog.exec()
        self.refresh_updates_page()

    def create_bundles_page(self):
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        container = QWidget()
        layout = QVBoxLayout(container)
        layout.setSpacing(15)

        title = QLabel("<b>Alien Add-On Bundles</b>")
        title.setStyleSheet("font-size: 18px; color: #FFFFFF;")
        desc = QLabel("Pre-engineered server suites, subsystems, and web app tools folded directly into Alien App Center.")
        desc.setStyleSheet(f"color: {COLOR_TEXT_MUTED}; font-size: 12px; margin-bottom: 10px;")
        layout.addWidget(title)
        layout.addWidget(desc)

        for b in self.bundles:
            card = QFrame()
            card.setProperty("class", "app-card")
            c_layout = QHBoxLayout(card)
            c_layout.setSpacing(15)

            icon_lbl = QLabel()
            icon = QIcon.fromTheme(b.get("icon", "package-x-generic"))
            icon_lbl.setPixmap(icon.pixmap(48, 48))
            c_layout.addWidget(icon_lbl)

            info = QVBoxLayout()
            name_lbl = QLabel(f"<b>{b.get('name')}</b>")
            name_lbl.setStyleSheet("font-size: 14px; color: #FFFFFF;")
            summary_lbl = QLabel(b.get("summary", ""))
            summary_lbl.setStyleSheet(f"color: {COLOR_TEXT_MUTED}; font-size: 12px;")
            summary_lbl.setWordWrap(True)
            info.addWidget(name_lbl)
            info.addWidget(summary_lbl)
            c_layout.addLayout(info)

            c_layout.addStretch()

            btn = QPushButton("Launch Setup")
            btn.setProperty("class", "action-btn")
            btn.clicked.connect(lambda _, bundle=b: self.run_bundle_script(bundle))
            c_layout.addWidget(btn)

            layout.addWidget(card)

        layout.addStretch()
        scroll.setWidget(container)
        return scroll

    def run_bundle_script(self, bundle):
        script_name = bundle.get("script")
        script_path = os.path.join(BUNDLES_DIR, script_name)

        if not os.path.exists(script_path):
            QMessageBox.critical(self, "Error", f"Bundle script {script_name} not found in {BUNDLES_DIR}")
            return

        worker = PackageWorker("bundle", "", custom_script=script_path)
        dialog = OperationDialog(f"Setting up {bundle.get('name')}...", worker, self)
        dialog.exec()

    def create_settings_page(self):
        container = QWidget()
        layout = QVBoxLayout(container)
        layout.setSpacing(20)

        title = QLabel("<b>Store Settings</b>")
        title.setStyleSheet("font-size: 18px; color: #FFFFFF; margin-bottom: 10px;")
        layout.addWidget(title)

        # Flathub Integration Frame
        flathub_card = QFrame()
        flathub_card.setProperty("class", "app-card")
        f_layout = QHBoxLayout(flathub_card)
        f_layout.setSpacing(15)

        f_info = QVBoxLayout()
        f_title = QLabel("<b>Enable Flathub (Flatpak Apps)</b>")
        f_title.setStyleSheet("font-size: 14px; color: #FFFFFF;")
        f_desc = QLabel("Adds Flathub remote repository to search and install sandboxed Flatpak packages. (Off by default for lightweight footprint).")
        f_desc.setStyleSheet(f"color: {COLOR_TEXT_MUTED}; font-size: 12px;")
        f_desc.setWordWrap(True)
        f_info.addWidget(f_title)
        f_info.addWidget(f_desc)
        f_layout.addLayout(f_info)

        f_layout.addStretch()

        self.flatpak_toggle = QPushButton("Enable Flathub")
        self.flatpak_toggle.setProperty("class", "action-btn")
        self.flatpak_toggle.clicked.connect(self.toggle_flathub)
        f_layout.addWidget(self.flatpak_toggle)
        layout.addWidget(flathub_card)

        # Cache Refresh Frame
        cache_card = QFrame()
        cache_card.setProperty("class", "app-card")
        c_layout = QHBoxLayout(cache_card)
        c_layout.setSpacing(15)

        c_info = QVBoxLayout()
        c_title = QLabel("<b>Refresh Repository Cache</b>")
        c_title.setStyleSheet("font-size: 14px; color: #FFFFFF;")
        c_desc = QLabel("Update package metadata from Debian, MongoDB, and Microsoft repositories.")
        c_desc.setStyleSheet(f"color: {COLOR_TEXT_MUTED}; font-size: 12px;")
        c_info.addWidget(c_title)
        c_info.addWidget(c_desc)
        c_layout.addLayout(c_info)

        c_layout.addStretch()

        refresh_btn = QPushButton("Refresh Now")
        refresh_btn.setProperty("class", "action-btn")
        refresh_btn.clicked.connect(self.refresh_cache)
        c_layout.addWidget(refresh_btn)
        layout.addWidget(cache_card)

        # About Store Frame
        about_card = QFrame()
        about_card.setProperty("class", "app-card")
        a_layout = QVBoxLayout(about_card)
        a_title = QLabel("<b>About Alien App Center</b>")
        a_title.setStyleSheet("font-size: 14px; color: #FFFFFF;")
        a_desc = QLabel("Alien App Center 0.1 (Pop Shop Edition)\nLightweight graphical application manager engineered for Alien OS Lite with native Debian Trixie & Qt6 integration.\n\nLicense: MIT License.")
        a_desc.setStyleSheet(f"color: {COLOR_TEXT_MUTED}; font-size: 12px; line-height: 1.4;")
        a_layout.addWidget(a_title)
        a_layout.addWidget(a_desc)
        layout.addWidget(about_card)

        layout.addStretch()
        return container

    def toggle_flathub(self):
        worker = PackageWorker("bundle", "", custom_script="/usr/lib/alien-app-center/enable-flathub.sh")
        dialog = OperationDialog("Configuring Flathub...", worker, self)
        dialog.exec()

    def refresh_cache(self):
        worker = PackageWorker("refresh", "")
        dialog = OperationDialog("Refreshing APT Metadata...", worker, self)
        dialog.exec()

    def create_search_results_page(self):
        self.search_scroll = QScrollArea()
        self.search_scroll.setWidgetResizable(True)
        self.search_results_widget = QWidget()
        self.search_results_layout = QVBoxLayout(self.search_results_widget)
        self.search_scroll.setWidget(self.search_results_widget)
        return self.search_scroll

    def on_search_changed(self, text):
        query = text.strip().lower()
        if not query:
            self.switch_page("home")
            return

        # Instant search curated apps first
        matched = []
        for app in self.all_apps:
            if query in app.get("name", "").lower() or query in app.get("summary", "").lower() or query in app.get("package", "").lower():
                matched.append(app)

        self.display_search_results(matched, query)

        # Query apt-cache in background if query is 3+ chars
        if len(query) >= 3:
            if self.search_worker and self.search_worker.isRunning():
                self.search_worker.terminate()
            self.search_worker = SearchWorker(query)
            self.search_worker.results_signal.connect(lambda res: self.merge_search_results(matched, res, query))
            self.search_worker.start()

    def display_search_results(self, apps, query):
        while self.search_results_layout.count():
            item = self.search_results_layout.takeAt(0)
            if item.widget():
                item.widget().deleteLater()

        header = QLabel(f"<b>Search results for '{query}':</b>")
        header.setStyleSheet("font-size: 16px; color: #FFFFFF; margin-bottom: 10px;")
        self.search_results_layout.addWidget(header)

        for app in apps:
            card = self.create_app_card(app)
            self.search_results_layout.addWidget(card)

        if not apps:
            no_lbl = QLabel("Searching system repositories...")
            no_lbl.setStyleSheet(f"color: {COLOR_TEXT_MUTED}; font-size: 13px;")
            self.search_results_layout.addWidget(no_lbl)

        self.search_results_layout.addStretch()
        self.stack.setCurrentIndex(8)

    def merge_search_results(self, curated_matches, apt_matches, query):
        seen_pkgs = {a.get("package") for a in curated_matches}
        combined = list(curated_matches)

        for item in apt_matches:
            if item.get("package") not in seen_pkgs:
                combined.append(item)
                seen_pkgs.add(item.get("package"))

        self.display_search_results(combined, query)


def main():
    app = QApplication(sys.argv)
    app.setApplicationName("Alien App Center")

    start_tab = "home"
    if "--tab" in sys.argv:
        try:
            idx = sys.argv.index("--tab")
            start_tab = sys.argv[idx + 1]
        except Exception:
            pass
    elif "--page" in sys.argv:
        try:
            idx = sys.argv.index("--page")
            start_tab = sys.argv[idx + 1]
        except Exception:
            pass

    window = AppCenter(start_tab=start_tab)
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
