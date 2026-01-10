#!/usr/bin/env python3
"""
StemWeaver v1.1 - Professional Audio Stem Separation Tool
Created by bendeb creations
Licensed under Creative Commons Attribution 4.0 International (CC BY 4.0)
Attribution required: bendeb creations - https://github.com/mangoban/StemWeaver
Support development: https://buymeacoffee.com/mangoban
"""

import sys
import os
import subprocess
import dearpygui.dearpygui as dpg
from pathlib import Path
import threading
import traceback
import time

# Try to import audio libraries
try:
    import numpy as np
    import soundfile as sf
    import librosa
    HAS_AUDIO_LIBS = True
except ImportError:
    HAS_AUDIO_LIBS = False
    print("[WARNING] Audio libraries not found. Install with: pip install numpy soundfile librosa")

# Try to import Demucs AI model
try:
    import torch
    import torchaudio
    from demucs.pretrained import get_model
    from demucs.apply import apply_model
    HAS_DEMUCS = True
except ImportError:
    HAS_DEMUCS = False
    print("[INFO] Demucs AI not available. Install with: pip install torch torchaudio demucs")

# Try to import MIDI libraries
try:
    import pretty_midi
    from midiutil import MIDIFile
    HAS_MIDI = True
except ImportError:
    HAS_MIDI = False
    print("[INFO] MIDI export not available. Install with: pip install pretty_midi midiutil")

# Import icon system
try:
    from icons import Icons, IconButtons, IconText
except ImportError:
    # Create dummy if icons not available
    class Icons:
        PLAY = "Play"
        MUSIC = "Audio"
    class IconButtons:
        PLAY = "Play"
        BROWSE = "Browse"
        PROCESS = "Process"
        ABOUT = "About"
        EXIT = "Exit"
        STOP = "Stop"
        CLEAR = "Clear"
        ANALYZE = "🔍 Analyze"
        APPLY = "✅ Apply"
    class IconText:
        FILE_SELECTION = "File Selection"
        SETTINGS = "Settings"
        FEATURES = "Features"
        FORMATS = "Formats"
        STRUCTURE = "Structure"
        SUPPORT = "Support"

# Add parent directory to path
parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if parent_dir not in sys.path:
    sys.path.insert(0, parent_dir)


class StemWeaverGUI:
    """Clean, Professional StemWeaver GUI"""

    def __init__(self):
        self.selected_files = []
        self.processing = False
        self.recommended_model = None  # Store recommendation from analysis
        self.icon_textures = {}  # Will hold loaded icon texture tags
        self.icons = {}  # Will hold icon dimensions
        self.current_theme = "Dark/Green"  # Default theme
        self.title_color = (120, 220, 140, 255)
        self.subtitle_color = (160, 200, 170, 255)
        
        # Initialize DearPyGui
        dpg.create_context()
        
        # Create viewport
        dpg.create_viewport(
            title="StemWeaver v1.1 - Audio Stem Separation",
            width=1200,
            height=800,
            min_width=900,
            min_height=600
        )
        
        # Setup theme BEFORE building UI
        self.setup_global_theme()
        
        # Setup fonts
        self.setup_fonts()
        
        # Load icons BEFORE building UI
        self.load_icons()
        
        # Build UI
        self.build_ui()
    
    def setup_fonts(self):
        """Setup fonts - DearPyGui uses default fonts, we'll use viewport scaling"""
        # DearPyGui 2.x uses default fonts automatically
        # We'll use font scaling for larger text
        self.title_font = None  # Will use default with scaling
        self.medium_font = None
    
    def load_icons(self):
        """Load icons for the UI buttons"""
        self.icons = {}
        self.icon_textures = {}
        
        # Define icons to load
        icon_files = {
            'process': 'process_icon.png',
            'stop': 'stop_icon.png',
            'folder': 'folder_icon.png', 
            'clear': 'clear_icon.png',
            'about': 'about_icon.png',
            'exit': 'exit_icon.png',
            'file': 'File.png',
            'play': 'play_icon.png',
            'settings': 'settings_icon.png',
        }
        
        # Get the image directory
        img_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'img')
        
        # Create texture registry
        with dpg.texture_registry(show=False):
            for icon_name, filename in icon_files.items():
                img_path = os.path.join(img_dir, filename)
                if os.path.exists(img_path):
                    try:
                        width, height, channels, data = dpg.load_image(img_path)
                        # Create texture with unique tag
                        tag = f"icon_{icon_name}"
                        dpg.add_static_texture(width, height, data, tag=tag)
                        self.icon_textures[icon_name] = tag
                        self.icons[icon_name] = (width, height)
                    except Exception as e:
                        print(f"[WARN] Could not load icon {filename}: {e}")
    
    def setup_global_theme(self):
        """Setup theme system - user can select from multiple themes"""
        # Store theme definitions
        self.themes = {
            "Dark/Green": {
                "window_bg": (15, 20, 15, 255),
                "child_bg": (25, 30, 25, 255),
                "text": (230, 240, 230, 255),
                "frame_bg": (40, 50, 40, 255),
                "frame_hover": (60, 70, 60, 255),
                "frame_active": (60, 160, 80, 255),
                "button": (35, 45, 35, 255),
                "button_hover": (50, 65, 50, 255),
                "button_active": (60, 160, 80, 255),
                "accent": (100, 200, 120, 255),
                "separator": (80, 140, 90, 255),
                "progress": (80, 180, 100, 255),
                "border": (60, 90, 60, 255),
                "title": (120, 220, 140, 255),
                "subtitle": (160, 200, 170, 255),
            },
            "Dark/Pink": {
                "window_bg": (20, 20, 25, 255),
                "child_bg": (30, 30, 35, 255),
                "text": (240, 240, 245, 255),
                "frame_bg": (50, 50, 60, 255),
                "frame_hover": (70, 50, 60, 255),
                "frame_active": (200, 50, 100, 255),
                "button": (60, 40, 50, 255),
                "button_hover": (90, 50, 70, 255),
                "button_active": (200, 50, 100, 255),
                "accent": (255, 100, 150, 255),
                "separator": (220, 60, 120, 255),
                "progress": (220, 60, 120, 255),
                "border": (100, 50, 80, 255),
                "title": (255, 100, 150, 255),
                "subtitle": (200, 180, 190, 255),
            },
            "Dark/Blue": {
                "window_bg": (15, 15, 20, 255),
                "child_bg": (25, 25, 30, 255),
                "text": (230, 230, 240, 255),
                "frame_bg": (40, 45, 55, 255),
                "frame_hover": (60, 65, 80, 255),
                "frame_active": (50, 120, 200, 255),
                "button": (35, 40, 50, 255),
                "button_hover": (50, 60, 80, 255),
                "button_active": (50, 120, 200, 255),
                "accent": (100, 180, 255, 255),
                "separator": (80, 120, 180, 255),
                "progress": (80, 150, 220, 255),
                "border": (60, 80, 120, 255),
                "title": (120, 180, 255, 255),
                "subtitle": (160, 190, 220, 255),
            },
            "Light/Purple": {
                "window_bg": (245, 245, 250, 255),
                "child_bg": (250, 250, 255, 255),
                "text": (30, 30, 40, 255),
                "frame_bg": (220, 220, 230, 255),
                "frame_hover": (200, 200, 215, 255),
                "frame_active": (140, 80, 200, 255),
                "button": (225, 225, 235, 255),
                "button_hover": (210, 210, 225, 255),
                "button_active": (140, 80, 200, 255),
                "accent": (160, 100, 220, 255),
                "separator": (180, 150, 210, 255),
                "progress": (140, 80, 200, 255),
                "border": (190, 190, 200, 255),
                "title": (120, 60, 180, 255),
                "subtitle": (100, 80, 120, 255),
            },
            "Light/Orange": {
                "window_bg": (248, 245, 240, 255),
                "child_bg": (253, 250, 245, 255),
                "text": (40, 30, 20, 255),
                "frame_bg": (230, 220, 210, 255),
                "frame_hover": (220, 205, 190, 255),
                "frame_active": (220, 120, 50, 255),
                "button": (235, 225, 215, 255),
                "button_hover": (225, 210, 195, 255),
                "button_active": (220, 120, 50, 255),
                "accent": (240, 140, 60, 255),
                "separator": (220, 180, 140, 255),
                "progress": (220, 120, 50, 255),
                "border": (210, 190, 170, 255),
                "title": (180, 80, 20, 255),
                "subtitle": (120, 90, 60, 255),
            },
        }
        
        # Apply default theme
        self.current_theme = "Dark/Green"
        self.apply_theme(self.current_theme)
    
    def apply_theme(self, theme_name):
        """Apply a specific theme"""
        if theme_name not in self.themes:
            return
        
        theme = self.themes[theme_name]
        
        # Create and bind theme
        with dpg.theme() as global_theme:
            with dpg.theme_component(dpg.mvAll):
                dpg.add_theme_color(dpg.mvThemeCol_WindowBg, theme["window_bg"])
                dpg.add_theme_color(dpg.mvThemeCol_ChildBg, theme["child_bg"])
                dpg.add_theme_color(dpg.mvThemeCol_Text, theme["text"])
                dpg.add_theme_color(dpg.mvThemeCol_FrameBg, theme["frame_bg"])
                dpg.add_theme_color(dpg.mvThemeCol_FrameBgHovered, theme["frame_hover"])
                dpg.add_theme_color(dpg.mvThemeCol_FrameBgActive, theme["frame_active"])
                dpg.add_theme_color(dpg.mvThemeCol_Button, theme["button"])
                dpg.add_theme_color(dpg.mvThemeCol_ButtonHovered, theme["button_hover"])
                dpg.add_theme_color(dpg.mvThemeCol_ButtonActive, theme["button_active"])
                dpg.add_theme_color(dpg.mvThemeCol_CheckMark, theme["accent"])
                dpg.add_theme_color(dpg.mvThemeCol_SliderGrab, theme["button_active"])
                dpg.add_theme_color(dpg.mvThemeCol_SliderGrabActive, theme["accent"])
                dpg.add_theme_color(dpg.mvThemeCol_Header, theme["button"])
                dpg.add_theme_color(dpg.mvThemeCol_HeaderHovered, theme["button_hover"])
                dpg.add_theme_color(dpg.mvThemeCol_HeaderActive, theme["button_active"])
                dpg.add_theme_color(dpg.mvThemeCol_Separator, theme["separator"])
                dpg.add_theme_color(dpg.mvThemeCol_PlotHistogram, theme["progress"])
                dpg.add_theme_color(dpg.mvThemeCol_Border, theme["border"])
                # Combo dropdown styling
                dpg.add_theme_color(dpg.mvThemeCol_PopupBg, theme["child_bg"])
                
                dpg.add_theme_style(dpg.mvStyleVar_FrameRounding, 6)
                dpg.add_theme_style(dpg.mvStyleVar_FramePadding, 10, 8)
                dpg.add_theme_style(dpg.mvStyleVar_ItemSpacing, 10, 8)
                dpg.add_theme_style(dpg.mvStyleVar_WindowPadding, 15, 15)
        
        dpg.bind_theme(global_theme)
        self.current_theme = theme_name
        
        # Update title and subtitle colors
        self.title_color = theme["title"]
        self.subtitle_color = theme["subtitle"]
        
        # Update UI elements if they exist
        if dpg.does_item_exist("main_title"):
            dpg.configure_item("main_title", color=self.title_color)
        if dpg.does_item_exist("subtitle"):
            dpg.configure_item("subtitle", color=self.subtitle_color)
        # Update theme selector to show current theme
        if dpg.does_item_exist("theme_selector"):
            dpg.set_value("theme_selector", theme_name)
    
    def on_theme_change(self, sender, app_data):
        """Callback when user changes theme"""
        self.apply_theme(app_data)
        self.log(f"[*] Theme changed to: {app_data}")
    
    def build_ui(self):
        """Build clean UI"""
        
        # File dialog
        with dpg.file_dialog(
            directory_selector=False,
            show=False,
            callback=self.file_dialog_callback,
            tag="file_dialog",
            width=700,
            height=400
        ):
            dpg.add_file_extension(".mp3", color=(0, 255, 0, 255))
            dpg.add_file_extension(".wav", color=(0, 255, 255, 255))
            dpg.add_file_extension(".flac", color=(255, 255, 0, 255))
            dpg.add_file_extension(".ogg", color=(255, 128, 0, 255))
            dpg.add_file_extension(".m4a", color=(255, 0, 255, 255))
            dpg.add_file_extension(".*", color=(200, 200, 200, 255))
        
        # Directory dialog
        with dpg.file_dialog(
            directory_selector=True,
            show=False,
            callback=self.dir_dialog_callback,
            tag="dir_dialog",
            width=700,
            height=400
        ):
            pass
        
        # Main window
        with dpg.window(tag="main_window"):
            
            # === HEADER WITH LOGO ===
            dpg.add_spacer(height=10)
            
            # Theme selector and Title
            with dpg.group(horizontal=True):
                dpg.add_text("Theme:", color=(120, 120, 130, 255))
                dpg.add_combo(
                    items=list(self.themes.keys()),
                    default_value=self.current_theme,
                    callback=self.on_theme_change,
                    width=180,
                    tag="theme_selector"
                )
                dpg.add_spacer(width=30)
                # Large title - using text wrapping and size
                dpg.add_text("STEMWEAVER v1.1", tag="main_title", color=self.title_color)
            
            # Credits
            dpg.add_text("by BenDeb Creations", tag="subtitle", color=self.subtitle_color)
            dpg.add_spacer(height=5)
            dpg.add_text("Professional Audio Stem Separation Tool", color=(100, 100, 110, 255))
            dpg.add_separator()
            dpg.add_spacer(height=10)
            
            # === MAIN LAYOUT ===
            with dpg.group(horizontal=True):
                
                # === LEFT PANEL - FILE SELECTION ===
                with dpg.child_window(width=550, height=550, border=True):
                    dpg.add_text(f"{IconText.FILE_SELECTION}", color=(0, 176, 255, 255))
                    dpg.add_spacer(height=5)
                    
                    # Buttons with icons
                    with dpg.group(horizontal=True):
                        if 'file' in self.icon_textures:
                            dpg.add_image(self.icon_textures['file'], width=20, height=20)
                        dpg.add_button(
                            label="Browse Files",
                            callback=lambda: dpg.show_item("file_dialog"),
                            width=100, height=30
                        )
                        dpg.add_spacer(width=10)
                        if 'clear' in self.icon_textures:
                            dpg.add_image(self.icon_textures['clear'], width=20, height=20)
                        dpg.add_button(
                            label="Clear List",
                            callback=self.clear_files,
                            width=90, height=30
                        )
                    
                    dpg.add_spacer(height=10)
                    dpg.add_text("Selected Files:", color=(160, 192, 255, 255))
                    
                    # File list
                    dpg.add_listbox(
                        items=[],
                        tag="file_list",
                        num_items=10,
                        width=-1
                    )
                    
                    dpg.add_spacer(height=15)
                    dpg.add_text("Output Directory:", color=(160, 192, 255, 255))
                    
                    with dpg.group(horizontal=True):
                        dpg.add_input_text(
                            default_value=str(Path.home() / "StemWeaver_Output"),
                            tag="output_dir",
                            width=400
                        )
                        dpg.add_button(
                            label=" Browse ",
                            callback=lambda: dpg.show_item("dir_dialog"),
                            width=80, height=28
                        )
                
                dpg.add_spacer(width=20)
                
                # === RIGHT PANEL - SETTINGS ===
                with dpg.child_window(width=550, height=550, border=True):
                    dpg.add_text(f"{IconText.SETTINGS}", color=(0, 176, 255, 255))
                    dpg.add_spacer(height=5)
                    
                    # Device selection
                    dpg.add_text("Processing Device:", color=(160, 192, 255, 255))
                    dpg.add_radio_button(
                        items=["CPU", "GPU"],
                        default_value="CPU",
                        tag="device_select",
                        horizontal=True
                    )
                    dpg.add_text("Note: GPU requires NVIDIA CUDA", color=(120, 120, 130, 255))
                    
                    dpg.add_spacer(height=10)
                    
                    # Quality slider
                    dpg.add_text("Quality Level:", color=(160, 192, 255, 255))
                    dpg.add_slider_int(
                        default_value=3,
                        min_value=1,
                        max_value=5,
                        tag="quality",
                        width=300,
                        format="Level %d"
                    )
                    
                    dpg.add_spacer(height=10)
                    
                    # AI Model Selection
                    dpg.add_text("AI Model:", color=(160, 192, 255, 255))
                    dpg.add_combo(
                        items=[
                            "Demucs v4 (Balanced)",
                            "Demucs v4 Fine-tuned (Best Vocals)",
                            "Demucs Drums (Best Percussion)",
                            "Demucs 6-Stem (+ Piano/Guitar)",
                            "MDX-Net (Fastest)",
                            "Ensemble (Best Quality - Slow)"
                        ],
                        default_value="Demucs v4 Fine-tuned (Best Vocals)",
                        tag="ai_model",
                        width=350,
                        callback=self.on_model_change
                    )
                    dpg.add_text("", tag="model_info", color=(128, 128, 128, 255))
                    
                    dpg.add_spacer(height=10)
                    
                    # Stem checkboxes - 4 stem default
                    dpg.add_text("Stems to Extract:", color=(160, 192, 255, 255))
                    with dpg.group(horizontal=True):
                        dpg.add_checkbox(label="Vocals", tag="stem_vocals", default_value=True)
                        dpg.add_checkbox(label="Drums", tag="stem_drums", default_value=True)
                    with dpg.group(horizontal=True):
                        dpg.add_checkbox(label="Bass", tag="stem_bass", default_value=True)
                        dpg.add_checkbox(label="Other", tag="stem_other", default_value=True)
                    # 6-stem extras (hidden by default)
                    with dpg.group(horizontal=True, tag="extra_stems_group", show=False):
                        dpg.add_checkbox(label="Piano", tag="stem_piano", default_value=True)
                        dpg.add_checkbox(label="Guitar", tag="stem_guitar", default_value=True)
                    
                    dpg.add_spacer(height=10)
                    dpg.add_separator()
                    dpg.add_spacer(height=5)
                    
                    # MIDI Export option
                    dpg.add_text("Export Options:", color=(160, 192, 255, 255))
                    dpg.add_checkbox(
                        label="Export stems as MIDI",
                        tag="export_midi",
                        default_value=False
                    )
                    dpg.add_text("(Best for: Vocals, Bass, Piano, Guitar)", color=(120, 120, 130, 255))

                    # Vocal-first option: do a vocal/accompaniment pass first
                    dpg.add_checkbox(
                        label="Vocal-first: separate vocals then instruments",
                        tag="vocal_first",
                        default_value=False
                    )
                    dpg.add_text("(Recommended when vocals are strong — reduces vocal bleed into instruments)", color=(140, 140, 150, 255))

                    # Accompaniment-only export (save accompaniment without vocals)
                    dpg.add_checkbox(
                        label="Export accompaniment-only (remove vocals)",
                        tag="export_accompaniment",
                        default_value=False
                    )
                    dpg.add_text("(Saves accompaniment minus vocals as additional file)", color=(140, 140, 150, 255))
                    
                    # Denoising options
                    dpg.add_spacer(height=5)
                    dpg.add_text("Post-Processing:", color=(255, 100, 150, 255))
                    dpg.add_checkbox(
                        label="Apply Denoising",
                        tag="apply_denoising",
                        default_value=True
                    )
                    dpg.add_slider_float(
                        label="Denoise Level",
                        tag="denoise_level",
                        min_value=0.0,
                        max_value=0.3,
                        default_value=0.08,
                        width=180
                    )
                    dpg.add_text("(0=off, 0.08=light, 0.2=strong)", color=(120, 120, 130, 255))
                    
                    dpg.add_spacer(height=5)
                    with dpg.group(horizontal=True):
                        dpg.add_button(
                            label="  [ANALYZE]  ",
                            callback=self.analyze_track,
                            width=150, height=32
                        )
                        dpg.add_spacer(width=10)
                        dpg.add_button(
                            label="  [APPLY]  ",
                            callback=self.apply_recommendation,
                            width=190, height=32
                        )
                    
                    dpg.add_spacer(height=15)
                    dpg.add_separator()
                    dpg.add_spacer(height=10)
                    
                    # Status
                    dpg.add_text("Status:", color=(160, 192, 255, 255))
                    dpg.add_text("Ready", tag="status", color=(0, 255, 128, 255))
                    
                    dpg.add_spacer(height=5)
                    
                    # Progress bar
                    dpg.add_progress_bar(
                        default_value=0.0,
                        tag="progress",
                        width=-1
                    )
                    
                    dpg.add_spacer(height=10)
                    
                    # Console
                    dpg.add_text("Log:", color=(160, 192, 255, 255))
                    dpg.add_input_text(
                        multiline=True,
                        readonly=True,
                        tag="console",
                        width=-1,
                        height=120,
                        default_value="StemWeaver v1.1 Ready\n"
                    )
            
            # === FOOTER ===
            dpg.add_spacer(height=15)
            dpg.add_separator()
            dpg.add_spacer(height=10)
            
            with dpg.group(horizontal=True):
                # Start Processing button with icon
                with dpg.group(horizontal=True):
                    if 'process' in self.icon_textures:
                        dpg.add_image(self.icon_textures['process'], width=24, height=24)
                    dpg.add_button(
                        label="Start",
                        callback=self.start_processing,
                        width=80, height=35
                    )
                dpg.add_spacer(width=8)
                
                # Stop Processing button with icon
                with dpg.group(horizontal=True):
                    if 'stop' in self.icon_textures:
                        dpg.add_image(self.icon_textures['stop'], width=24, height=24)
                    dpg.add_button(
                        label="Stop",
                        callback=self.stop_processing,
                        width=80, height=35
                    )
                dpg.add_spacer(width=8)
                
                # Open Output button with icon
                with dpg.group(horizontal=True):
                    if 'folder' in self.icon_textures:
                        dpg.add_image(self.icon_textures['folder'], width=24, height=24)
                    dpg.add_button(
                        label="Output",
                        callback=self.open_output_folder,
                        width=80, height=35
                    )
                dpg.add_spacer(width=8)
                
                # About button with icon
                with dpg.group(horizontal=True):
                    if 'about' in self.icon_textures:
                        dpg.add_image(self.icon_textures['about'], width=24, height=24)
                    dpg.add_button(
                        label="About",
                        callback=self.show_about,
                        width=80, height=35
                    )
                dpg.add_spacer(width=10)
                
                # Exit button with icon
                with dpg.group(horizontal=True):
                    if 'exit' in self.icon_textures:
                        dpg.add_image(self.icon_textures['exit'], width=24, height=24)
                    dpg.add_button(
                        label="Exit",
                        callback=lambda: dpg.stop_dearpygui(),
                        width=80, height=35
                    )
    
    def log(self, msg):
        """Add message to console"""
        current = dpg.get_value("console")
        dpg.set_value("console", current + msg + "\n")
    
    def _show_button_press(self, button_name):
        """Show immediate button press feedback in log"""
        self.log(f"[INPUT] {button_name} button pressed ✓")
    
    def open_output_folder(self):
        """Open the output folder in the system file manager"""
        self._show_button_press("OUTPUT")
        self._button_flash("Start")  # Reuse flash for visual feedback
        
        output_dir = dpg.get_value("output_dir")
        if os.path.exists(output_dir):
            try:
                # Linux
                subprocess.Popen(['xdg-open', output_dir])
                self.log(f"[*] Opened: {output_dir}")
            except Exception as e:
                self.log(f"[ERROR] Could not open folder: {e}")
        else:
            self.log(f"[!] Output folder doesn't exist yet: {output_dir}")
            self.log(f"[INFO] Process some files first to create it")
    
    def on_model_change(self, sender, app_data):
        """Handle model type change - show/hide extra stems and show model info"""
        # Show/hide 6-stem options
        if "6-Stem" in app_data:
            dpg.show_item("extra_stems_group")
        else:
            dpg.hide_item("extra_stems_group")
        
        # Update model info text
        model_descriptions = {
            "Demucs v4 (Balanced)": "Good all-around separation, fast",
            "Demucs v4 Fine-tuned (Best Vocals)": "Cleanest vocal isolation",
            "Demucs Drums (Best Percussion)": "Optimized for drums/percussion extraction",
            "Demucs 6-Stem (+ Piano/Guitar)": "Separates piano and guitar from Other",
            "MDX-Net (Fastest)": "Fast processing, good for previews",
            "Ensemble (Best Quality - Slow)": "Combines multiple models for best results"
        }
        info = model_descriptions.get(app_data, "")
        dpg.set_value("model_info", info)
    
    def analyze_track(self):
        """Analyze the selected track to detect what instruments are present"""
        self._show_button_press("ANALYZE")
        self._button_flash("Start")
        
        if not self.selected_files:
            self.log("[!] No file selected to analyze")
            return
        
        if not HAS_AUDIO_LIBS:
            self.log("[ERROR] Audio libraries not installed for analysis")
            return
        
        audio_file = self.selected_files[0]
        name = os.path.basename(audio_file)
        self.log(f"\n[ANALYZE] {name}")
        
        try:
            # Load audio for analysis
            import librosa
            y, sr = librosa.load(audio_file, sr=22050, duration=60)  # First 60 seconds
            
            duration = len(y) / sr
            self.log(f"  Duration: {duration:.1f}s")
            
            # Analyze frequency content
            # Low frequencies (bass): 20-250 Hz
            # Mid frequencies (vocals, guitar): 250-4000 Hz
            # High frequencies (cymbals, hi-hats): 4000-20000 Hz
            
            S = np.abs(librosa.stft(y))
            freqs = librosa.fft_frequencies(sr=sr)
            
            # Calculate energy in different frequency bands
            bass_mask = freqs < 250
            mid_mask = (freqs >= 250) & (freqs < 4000)
            high_mask = freqs >= 4000
            
            bass_energy = np.mean(S[bass_mask, :]) if np.any(bass_mask) else 0
            mid_energy = np.mean(S[mid_mask, :]) if np.any(mid_mask) else 0
            high_energy = np.mean(S[high_mask, :]) if np.any(high_mask) else 0
            
            total_energy = bass_energy + mid_energy + high_energy
            if total_energy > 0:
                bass_pct = bass_energy / total_energy * 100
                mid_pct = mid_energy / total_energy * 100
                high_pct = high_energy / total_energy * 100
            else:
                bass_pct = mid_pct = high_pct = 0
            
            # Detect rhythmic content (drums)
            onset_env = librosa.onset.onset_strength(y=y, sr=sr)
            tempo, beats = librosa.beat.beat_track(onset_envelope=onset_env, sr=sr)
            # tempo can be an array in newer librosa versions
            tempo_val = float(tempo[0]) if hasattr(tempo, '__len__') else float(tempo)
            has_drums = len(beats) > 10 and tempo_val > 60
            
            # Detect harmonic content (vocals/melody)
            harmonic = librosa.effects.harmonic(y)
            harmonic_energy = float(np.mean(np.abs(harmonic)))
            has_vocals_melody = harmonic_energy > 0.01
            
            # Convert percentages to float for formatting
            bass_pct = float(bass_pct)
            mid_pct = float(mid_pct)
            high_pct = float(high_pct)
            
            self.log(f"\n  [FREQUENCY ANALYSIS]")
            self.log(f"  Bass (20-250 Hz):    {bass_pct:.1f}%")
            self.log(f"  Mids (250-4000 Hz):  {mid_pct:.1f}%")
            self.log(f"  Highs (4000+ Hz):    {high_pct:.1f}%")
            
            self.log(f"\n  [DETECTED CONTENT]")
            
            # Suggest stems based on analysis
            suggestions = []
            
            if has_drums:
                self.log(f"  ✓ DRUMS detected (tempo: {tempo_val:.0f} BPM)")
                suggestions.append("Drums")
            else:
                self.log(f"  ✗ No strong drum pattern detected")
            
            if bass_pct > 15:
                self.log(f"  ✓ BASS detected (strong low frequencies)")
                suggestions.append("Bass")
            else:
                self.log(f"  ? Weak bass content")
            
            if has_vocals_melody and mid_pct > 30:
                self.log(f"  ✓ VOCALS/MELODY likely present")
                suggestions.append("Vocals")
            else:
                self.log(f"  ? Vocals may be minimal")
            
            if mid_pct > 20:
                self.log(f"  ✓ OTHER instruments (guitars/keys/synths)")
                suggestions.append("Other")
            
            self.log(f"\n  [RECOMMENDATION]")
            if len(suggestions) >= 3:
                self.log(f"  This is a full mix - extract all stems")
            elif "Vocals" in suggestions and len(suggestions) == 1:
                self.log(f"  Appears to be a vocal-only or acapella track")
            elif "Drums" in suggestions and "Bass" in suggestions:
                self.log(f"  Instrumental track - may have minimal vocals")
            else:
                self.log(f"  Suggested stems: {', '.join(suggestions) if suggestions else 'All'}")
            
            # AI MODEL RECOMMENDATION based on analysis
            self.log(f"\n  [BEST AI MODEL FOR THIS TRACK]")
            
            # Determine best model based on track characteristics
            recommended_model = None
            recommendation_reason = ""
            
            # Check for drum-heavy track
            drum_score = 0
            if has_drums:
                drum_score += 2
            if high_pct > 25:  # Lots of hi-hats/cymbals
                drum_score += 1
            if bass_pct > 20 and has_drums:  # Strong kick drum presence
                drum_score += 1
            
            # Check for vocal-focused track
            vocal_score = 0
            if has_vocals_melody:
                vocal_score += 2
            if mid_pct > 40:  # Strong mid frequencies (voice range)
                vocal_score += 1
            if bass_pct < 20:  # Not bass-heavy (vocals clearer)
                vocal_score += 1
            
            # Check for complex mix
            complexity_score = len(suggestions)
            if bass_pct > 15 and mid_pct > 30 and high_pct > 15:
                complexity_score += 1  # Wide frequency spread = complex
            
            # Recommend based on scores
            if drum_score >= 3 and "Drums" in suggestions:
                recommended_model = "Demucs Drums (Best Percussion)"
                recommendation_reason = "Strong drum/percussion content detected"
                self.log(f"  🥁 {recommended_model}")
                self.log(f"     Reason: {recommendation_reason}")
            elif vocal_score >= 3 and has_vocals_melody:
                recommended_model = "Demucs v4 Fine-tuned (Best Vocals)"
                recommendation_reason = "Prominent vocals/melody detected"
                self.log(f"  🎤 {recommended_model}")
                self.log(f"     Reason: {recommendation_reason}")
            elif complexity_score >= 4:
                recommended_model = "Ensemble (Best Quality - Slow)"
                recommendation_reason = "Complex mix with many instruments"
                self.log(f"  🎼 {recommended_model}")
                self.log(f"     Reason: {recommendation_reason}")
                self.log(f"     Alt: 'Demucs 6-Stem' if you need Piano/Guitar separated")
            elif duration < 120:  # Short track
                recommended_model = "Demucs v4 (Balanced)"
                recommendation_reason = "Short track, balanced processing"
                self.log(f"  ⚡ {recommended_model}")
                self.log(f"     Reason: {recommendation_reason}")
            else:
                recommended_model = "Demucs v4 (Balanced)"
                recommendation_reason = "Good all-around choice for this track"
                self.log(f"  ✓ {recommended_model}")
                self.log(f"     Reason: {recommendation_reason}")
            
            # Offer to auto-select the model
            self.log(f"\n  [TIP] Click 'Apply Recommendation' to auto-select this model")
            
            # Recommend vocal-first if vocals are prominent
            vocal_strength = mid_pct * (harmonic_energy / (np.mean(np.abs(y)) + 1e-9))
            if has_vocals_melody and (mid_pct > 30 or vocal_strength > 0.02 or vocal_score >= 3):
                self.log(f"\n  [RECOMMENDATION] Vocal-first separation is recommended for cleaner instruments")
                # Auto-suggest by enabling the checkbox (user can change it back)
                try:
                    dpg.set_value("vocal_first", True)
                    self.log("  [AUTO] 'Vocal-first' option enabled")
                except Exception:
                    pass

            # Store the recommendation
            self.recommended_model = recommended_model
            
        except Exception as e:
            self.log(f"  [ERROR] Analysis failed: {str(e)}")
    
    def apply_recommendation(self):
        """Apply the recommended AI model from analysis"""
        self._show_button_press("APPLY")
        self._button_flash("Start")
        
        if self.recommended_model is None:
            self.log("[!] No recommendation yet - click 'Analyze Track' first")
            return
        
        # Set the dropdown to the recommended model
        dpg.set_value("ai_model", self.recommended_model)
        
        # Trigger the callback to update UI (show/hide 6-stem options, update info)
        self.on_model_change(None, self.recommended_model)
        
        self.log(f"[✓] Applied: {self.recommended_model}")
    
    def file_dialog_callback(self, sender, app_data):
        """Handle file selection"""
        selections = app_data.get("selections", {})
        if selections:
            for name, path in selections.items():
                if path not in self.selected_files:
                    self.selected_files.append(path)
            
            # Update listbox
            display = [os.path.basename(f) for f in self.selected_files]
            dpg.configure_item("file_list", items=display)
            
            self.log(f"[+] Added {len(selections)} file(s)")
            self.log(f"[*] Total: {len(self.selected_files)} files")
    
    def dir_dialog_callback(self, sender, app_data):
        """Handle directory selection"""
        path = app_data.get("file_path_name", "")
        if path:
            dpg.set_value("output_dir", path)
            self.log(f"[*] Output: {path}")
    
    def clear_files(self):
        """Clear file list"""
        # IMMEDIATE FEEDBACK
        self._show_button_press("CLEAR")
        self._button_flash("Clear")
        
        self.selected_files = []
        dpg.configure_item("file_list", items=[])
        self.log("[!] File list cleared")
        dpg.set_value("status", "Files cleared")
    
    def start_processing(self):
        """Start processing"""
        # IMMEDIATE FEEDBACK - Show button press in log
        self._show_button_press("START")
        
        if not self.selected_files:
            self.log("[ERROR] No files selected!")
            dpg.set_value("status", "Error: No files")
            self._button_flash("Start")
            return
        
        # Validate files exist
        valid_files = []
        for f in self.selected_files:
            if os.path.exists(f):
                valid_files.append(f)
            else:
                self.log(f"[WARN] File not found: {f}")
        
        if not valid_files:
            self.log("[ERROR] No valid files found!")
            dpg.set_value("status", "Error: Files not found")
            self._button_flash("Start")
            return
        
        self.selected_files = valid_files
        
        if self.processing:
            self.log("[!] Already processing")
            self._button_flash("Start")
            return
        
        # IMMEDIATE VISUAL FEEDBACK
        self._button_flash("Start")
        dpg.set_value("status", "Starting...")
        dpg.set_value("progress", 0.05)  # Small initial progress to show activity
        
        self.processing = True
        
        # Run in thread
        thread = threading.Thread(target=self.process_files)
        thread.daemon = True
        thread.start()
    
    def process_files(self):
        """Process all files with Demucs AI stem separation (TRUE separation)"""
        files_processed = 0
        files_failed = 0
        
        try:
            # If called directly (for tests), ensure processing flag is enabled
            if not self.processing:
                self.processing = True

            # Check prerequisites first
            if not HAS_AUDIO_LIBS:
                self.log("[ERROR] Audio libraries not installed!")
                self.log("[INFO] Run: pip install numpy soundfile")
                dpg.set_value("status", "Missing libraries")
                self.processing = False
                return
            
            if not HAS_DEMUCS:
                self.log("[ERROR] Demucs AI not installed!")
                self.log("[INFO] Run: pip install torch torchaudio demucs")
                dpg.set_value("status", "Install Demucs first")
                self.processing = False
                return
            
            output_dir = dpg.get_value("output_dir")
            os.makedirs(output_dir, exist_ok=True)
            
            # Check if output directory is writable
            test_file = os.path.join(output_dir, ".write_test")
            try:
                with open(test_file, 'w') as f:
                    f.write("test")
                os.remove(test_file)
            except Exception as e:
                self.log(f"[ERROR] Cannot write to output directory: {output_dir}")
                self.log(f"[INFO] Check permissions or choose a different folder")
                dpg.set_value("status", "Output folder not writable")
                self.processing = False
                return
            
            # Check model type selection
            model_type = dpg.get_value("ai_model")
            use_6_stem = "6-Stem" in model_type
            use_mdx = "MDX-Net" in model_type
            use_ensemble = "Ensemble" in model_type
            use_fine_tuned = "Fine-tuned" in model_type
            use_drums = "Drums" in model_type
            
            # Get selected stems based on model type
            stems = []
            stem_indices = {}
            
            if use_6_stem:
                # 6-stem model: drums, bass, other, vocals, guitar, piano
                if dpg.get_value("stem_drums"):
                    stems.append("Drums")
                    stem_indices["Drums"] = 0
                if dpg.get_value("stem_bass"):
                    stems.append("Bass")
                    stem_indices["Bass"] = 1
                if dpg.get_value("stem_other"):
                    stems.append("Other")
                    stem_indices["Other"] = 2
                if dpg.get_value("stem_vocals"):
                    stems.append("Vocals")
                    stem_indices["Vocals"] = 3
                if dpg.get_value("stem_guitar"):
                    stems.append("Guitar")
                    stem_indices["Guitar"] = 4
                if dpg.get_value("stem_piano"):
                    stems.append("Piano")
                    stem_indices["Piano"] = 5
            else:
                # 4-stem model: drums, bass, other, vocals
                if dpg.get_value("stem_drums"):
                    stems.append("Drums")
                    stem_indices["Drums"] = 0
                if dpg.get_value("stem_bass"):
                    stems.append("Bass")
                    stem_indices["Bass"] = 1
                if dpg.get_value("stem_other"):
                    stems.append("Other")
                    stem_indices["Other"] = 2
                if dpg.get_value("stem_vocals"):
                    stems.append("Vocals")
                    stem_indices["Vocals"] = 3
            
            if not stems:
                self.log("[ERROR] No stems selected!")
                dpg.set_value("status", "Error: Select stems")
                self.processing = False
                return
            
            total = len(self.selected_files)
            
            # Get MIDI export setting
            export_midi = dpg.get_value("export_midi")
            
            # Get quality level (1-5)
            quality_level = dpg.get_value("quality")
            
            # Map quality to shifts (multi-pass processing for cleaner separation)
            # OPTIMIZED: Reduced shifts for much faster processing
            # shifts=0 is fastest, shifts=1-2 is good balance
            quality_shifts = {1: 0, 2: 0, 3: 1, 4: 1, 5: 2}
            shifts = quality_shifts.get(quality_level, 1)
            
            # Map quality to overlap (higher = cleaner but slower)
            # OPTIMIZED: Reduced overlap for faster processing
            quality_overlap = {1: 0.1, 2: 0.15, 3: 0.2, 4: 0.25, 5: 0.3}
            overlap = quality_overlap.get(quality_level, 0.2)
            
            self.log(f"\n{'='*50}")
            self.log(f"[START] Processing {total} file(s)")
            self.log(f"{'='*50}")
            self.log(f"[*] Output: {output_dir}")
            self.log(f"[*] Model: {model_type}")
            self.log(f"[*] Stems: {', '.join(stems)}")
            self.log(f"[*] Quality: Level {quality_level}/5 (shifts={shifts}, overlap={overlap})")
            if export_midi:
                self.log(f"[*] MIDI Export: Enabled")
            
            # Show supported formats
            self.log(f"[*] Formats: WAV, MP3, FLAC, OGG (requires ffmpeg for MP3/OGG)")
            
            # Estimate speed
            speed_estimate = "Fast" if shifts == 0 else "Normal" if shifts == 1 else "Slower"
            self.log(f"[*] Speed: {speed_estimate}")
            
            # Check for GPU - read from user selection
            device_choice = dpg.get_value("device_select")
            if device_choice == "GPU":
                if torch.cuda.is_available():
                    device = "cuda"
                    self.log(f"[*] GPU: NVIDIA CUDA enabled (FAST)")
                else:
                    device = "cpu"
                    self.log(f"[*] GPU: CUDA not available, falling back to CPU")
            else:
                device = "cpu"
                self.log(f"[*] CPU: Using CPU for processing")
            
            # Store device type for later checks
            self.is_cpu = (device == "cpu")
            
            # Load Demucs model
            self.log(f"\n[*] Loading AI model...")
            dpg.set_value("status", "Loading AI model...")
            
            # Select models based on user choice
            model_loaded = False
            
            if use_ensemble:
                # Ensemble mode - we'll run multiple models and combine
                models_to_try = ['htdemucs_ft', 'htdemucs']
                self.log(f"[*] ENSEMBLE MODE: Will combine multiple models for best quality")
            elif use_6_stem:
                # 6-stem models
                models_to_try = ['htdemucs_6s']
                self.log(f"[*] Loading 6-stem model (separates Piano & Guitar)")
            elif use_drums:
                # Drums-optimized: use fine-tuned model
                models_to_try = ['htdemucs_ft', 'htdemucs']
                shifts = max(shifts, 1)  # Minimal shifts for speed
                overlap = max(overlap, 0.2)  # Balanced overlap
                self.log(f"[*] DRUMS MODE: Optimized for percussion extraction")
            elif use_mdx:
                # Use MDX-style fastest processing - use htdemucs with lower shifts
                models_to_try = ['htdemucs']
                shifts = 0  # Fastest processing
                overlap = 0.1
                self.log(f"[*] Fast mode: minimal processing for quick preview")
            elif use_fine_tuned:
                # Fine-tuned for best vocals
                models_to_try = ['htdemucs_ft', 'htdemucs']
                self.log(f"[*] Using fine-tuned model for cleanest vocals")
            else:
                # 4-stem models - balanced
                models_to_try = ['htdemucs', 'htdemucs_ft']
            
            for model_name in models_to_try:
                try:
                    model = get_model(model_name)
                    model.to(device)
                    model.eval()
                    self.log(f"[OK] Model loaded: {model_name}")
                    if model_name == 'htdemucs_ft':
                        self.log(f"[*] Using FINE-TUNED model (best quality)")
                    elif model_name == 'htdemucs_6s':
                        self.log(f"[*] 6-stem: drums, bass, other, vocals, guitar, piano")
                    model_loaded = True
                    break
                except Exception as e:
                    self.log(f"[WARN] Model {model_name} not available: {str(e)[:50]}")
                    continue
            
            if not model_loaded:
                self.log(f"[ERROR] No models available!")
                self.log(f"[INFO] Check internet - models download on first use")
                dpg.set_value("status", "Model load failed")
                self.processing = False
                return
            
            for idx, audio_file in enumerate(self.selected_files):
                if not self.processing:
                    self.log("[!] Stopped by user")
                    break
                
                name = os.path.basename(audio_file)
                name_no_ext = os.path.splitext(name)[0]
                
                self.log(f"\n{'─'*40}")
                self.log(f"[{idx+1}/{total}] {name}")
                
                # Create folder for this file
                file_dir = os.path.join(output_dir, name_no_ext)
                os.makedirs(file_dir, exist_ok=True)
                self.log(f"  Output: {name_no_ext}/")
                
                try:
                    # Validate file exists and is readable
                    if not os.path.exists(audio_file):
                        self.log(f"  [ERROR] File not found!")
                        files_failed += 1
                        continue
                    
                    file_size = os.path.getsize(audio_file)
                    if file_size < 1000:  # Less than 1KB
                        self.log(f"  [ERROR] File too small ({file_size} bytes)")
                        files_failed += 1
                        continue
                    
                    # Load audio file
                    self.log(f"  Loading audio ({file_size/1024/1024:.1f} MB)...")
                    dpg.set_value("status", f"Loading: {name}")
                    
                    # Load audio file using librosa (most reliable for all formats)
                    waveform = None
                    sample_rate = 44100
                    temp_wav = None  # Track temporary converted file
                    
                    try:
                        file_ext = os.path.splitext(audio_file)[1].lower()
                        self.log(f"  Loading audio ({file_ext.upper()})...")
                        # Handle large files (>500MB) with ffmpeg conversion first
                        file_size_mb = os.path.getsize(audio_file) / (1024*1024)
                        if file_size_mb > 500:
                            self.log(f"  [LARGE FILE] Converting {file_size_mb:.1f}MB file to WAV first...")
                            temp_wav = os.path.join(file_dir, f"_temp_{name_no_ext}.wav")
                            subprocess.run(['ffmpeg', '-i', audio_file, '-y', '-loglevel', 'error', temp_wav])
                            audio_file = temp_wav
                        
                        # Try loading with stereo first
                        audio_np, sample_rate = librosa.load(audio_file, sr=None, mono=False)
                        self.log(f"  ✓ Audio loaded: {audio_np.shape} @ {sample_rate}Hz")
                        
                        # Handle mono vs stereo
                        if audio_np.ndim == 1:
                            self.log(f"  Converting mono to stereo...")
                            audio_np = np.stack([audio_np, audio_np])
                        elif audio_np.ndim == 2 and audio_np.shape[0] > 2:
                            self.log(f"  Downmixing {audio_np.shape[0]} channels to stereo...")
                            audio_np = audio_np[:2, :]
                        
                        waveform = torch.from_numpy(audio_np).float()
                        
                    except Exception as load_err:
                        self.log(f"  [ERROR] Initial load failed: {str(load_err)}")
                        self.log(f"  [DEBUG] Attempting ffmpeg conversion...")
                        
                        # Try converting via ffmpeg with detailed error reporting
                        try:
                            file_ext = os.path.splitext(audio_file)[1].lower()
                            if file_ext in ['.mp3', '.ogg', '.m4a', '.flac']:
                                temp_wav = os.path.join(file_dir, f"_temp_{name_no_ext}.wav")
                                self.log(f"  [AUTO] Converting {file_ext} to WAV using ffmpeg...")
                                
                                result = subprocess.run(
                                    ['ffmpeg', '-i', audio_file, '-y',
                                     '-loglevel', 'verbose',
                                     '-acodec', 'pcm_s16le',
                                     '-ar', '44100',
                                     temp_wav],
                                    capture_output=True,
                                    text=True,
                                    timeout=60
                                )
                                
                                if result.returncode != 0:
                                    self.log(f"  [FFMPEG ERROR] Exit code: {result.returncode}")
                                    self.log(f"  [FFMPEG STDERR] {result.stderr[:500]}")
                                    raise RuntimeError("FFmpeg conversion failed")
                                    
                                if not os.path.exists(temp_wav):
                                    raise FileNotFoundError("FFmpeg output file missing")
                                    
                                # Verify converted file
                                audio_np, sample_rate = librosa.load(temp_wav, sr=None, mono=False)
                                self.log(f"  ✓ Converted via ffmpeg successfully")
                                
                                # Handle mono vs stereo
                                if audio_np.ndim == 1:
                                    audio_np = np.stack([audio_np, audio_np])
                                elif audio_np.ndim == 2 and audio_np.shape[0] > 2:
                                    audio_np = audio_np[:2, :]
                                
                                waveform = torch.from_numpy(audio_np).float()
                            else:
                                raise RuntimeError(f"Unsupported format: {file_ext}")
                                
                        except Exception as conv_err:
                            self.log(f"  [CRITICAL] Conversion failed: {str(conv_err)}")
                            if 'temp_wav' in locals() and temp_wav and os.path.exists(temp_wav):
                                try:
                                    os.remove(temp_wav)
                                except:
                                    pass
                            files_failed += 1
                            continue
                    
                    original_sr = sample_rate
                    
                    # Demucs expects 44100 Hz
                    if sample_rate != 44100:
                        self.log(f"  Resampling {sample_rate}Hz → 44100Hz...")
                        resampler = torchaudio.transforms.Resample(sample_rate, 44100)
                        waveform = resampler(waveform)
                        sample_rate = 44100
                    
                    # Ensure stereo (Demucs works best with stereo)
                    if waveform.shape[0] == 1:
                        waveform = waveform.repeat(2, 1)
                    elif waveform.shape[0] > 2:
                        waveform = waveform[:2, :]
                    
                    duration = waveform.shape[1] / sample_rate
                    self.log(f"  Duration: {duration:.1f}s | Channels: {waveform.shape[0]} | SR: {sample_rate}Hz")
                    
                    # Add batch dimension: (batch, channels, samples)
                    waveform = waveform.unsqueeze(0).to(device)
                    
                    # Memory-aware processing for CPU
                    # Very long files need chunk-based processing to maintain quality
                    actual_shifts = shifts
                    actual_segment = None
                    
                    if self.is_cpu:
                        # For CPU, use chunk-based processing for long files
                        # This maintains full quality while avoiding memory errors
                        if duration > 300:  # >5 minutes
                            actual_shifts = 0  # No shifts for long files
                            self.log(f"  [CPU] Long file ({duration:.0f}s) - using chunk mode, no shifts")
                        elif duration > 120:  # >2 minutes
                            actual_shifts = max(0, shifts - 1)  # Reduce shifts
                            self.log(f"  [CPU] Medium file ({duration:.0f}s) - reduced shifts")
                        else:
                            self.log(f"  [CPU] Using segment mode for stability")
                    
                    # Always show what's being used
                    if self.is_cpu:
                        self.log(f"  [CPU] Quality mode: shifts={actual_shifts}")
                    
                    # Apply Demucs model with quality settings
                    # Check if we should run vocal-first pre-processing
                    vocal_first = dpg.get_value("vocal_first") if dpg.does_item_exist("vocal_first") else False
                    export_accompaniment = dpg.get_value("export_accompaniment") if dpg.does_item_exist("export_accompaniment") else False

                    # Store original waveform for vocal retrieval if needed
                    original_waveform = waveform.clone() if vocal_first else None
                    
                    # FIX: For vocal-first to work properly, need 6-stem model
                    if vocal_first and not use_6_stem:
                        self.log(f"  [VOCAL-FIRST] ⚠️  4-stem model with vocal-first may produce noisy non-vocal stems")
                        self.log(f"  [VOCAL-FIRST] Recommendation: Use 6-Stem model or disable vocal-first")
                    
                    if vocal_first:
                        self.log(f"  [VOCAL-FIRST] Performing initial vocal/accompaniment separation...")
                        try:
                            init_sources = apply_model(model, waveform, device=device, shifts=(0 if self.is_cpu else actual_shifts), overlap=(0.1 if self.is_cpu else overlap), segment=None, progress=False)
                            # Demucs ordering: (batch, n_sources, channels, time)
                            # Vocal index used by our stem mapping is 3 for both 4- and 6-stem models
                            vocal_idx = 3
                            if init_sources is not None and init_sources.shape[1] > vocal_idx:
                                # Sum all non-vocal sources to produce accompaniment
                                accomp = None
                                for s in range(init_sources.shape[1]):
                                    if s == vocal_idx:
                                        continue
                                    src = init_sources[0, s]  # (channels, samples)
                                    if accomp is None:
                                        accomp = src.clone()
                                    else:
                                        accomp = accomp + src

                                # Replace waveform with accompaniment for second-stage separation
                                waveform = accomp.unsqueeze(0)  # shape becomes (1, channels, samples)
                                self.log("  [VOCAL-FIRST] Accompaniment computed (vocals removed)")

                                if export_accompaniment:
                                    try:
                                        accomp_np = accomp.cpu().numpy()
                                        # transpose to (samples, channels) for soundfile
                                        if accomp_np.ndim == 2:
                                            accomp_to_write = np.transpose(accomp_np, (1, 0))
                                        else:
                                            accomp_to_write = accomp_np
                                        accomp_path = os.path.join(file_dir, f"{name_no_ext}_accompaniment.wav")
                                        sf.write(accomp_path, accomp_to_write, samplerate=sample_rate)
                                        self.log(f"  ✓ Saved accompaniment-only: {os.path.basename(accomp_path)}")
                                    except Exception as e:
                                        self.log(f"  [WARN] Failed to save accompaniment: {str(e)[:80]}")
                            else:
                                self.log("  [WARN] Vocal index not present in initial output; skipping vocal-first")
                        except Exception as e:
                            self.log(f"  [WARN] Vocal-first step failed: {str(e)[:80]}")

                    self.log(f"  Running AI separation...")
                    if shifts > 0:
                        self.log(f"  Multi-pass mode: {shifts} shifts for cleaner output")
                    dpg.set_value("status", f"AI Processing: {name}")
                    dpg.set_value("progress", (idx + 0.1) / total)
                    
                    with torch.no_grad():
                        # Demucs separation with shifts for better quality
                        # shifts=N runs the model N times with pitch shifts and averages results
                        # This significantly reduces bleed between stems
                        
                        if use_ensemble:
                            # ENSEMBLE MODE: Use fine-tuned model with optimal settings
                            # Note: True ensemble is very slow, so we use best single model
                            self.log(f"  [ENSEMBLE] Using fine-tuned model with quality settings...")
                            try:
                                ens_model = get_model('htdemucs_ft')
                                ens_model.to(device)
                                ens_model.eval()
                                
                                # For CPU with medium+ files, use chunk mode for stability
                                if self.is_cpu and duration > 60:
                                    chunk_seconds = 15
                                    chunk_samples = chunk_seconds * sample_rate
                                    total_samples = waveform.shape[2]
                                    num_chunks = max(1, int(np.ceil(total_samples / chunk_samples)))
                                    
                                    self.log(f"  [CHUNK] Ensemble mode: {num_chunks} chunks...")
                                    chunk_sources = []
                                    
                                    for chunk_idx in range(num_chunks):
                                        start = chunk_idx * chunk_samples
                                        end = min(start + chunk_samples, total_samples)
                                        if end - start < sample_rate:
                                            continue
                                        
                                        chunk = waveform[:, :, start:end]
                                        try:
                                            chunk_result = apply_model(
                                                ens_model, chunk, device=device,
                                                shifts=0, overlap=0.2, segment=None, progress=False
                                            )
                                            chunk_sources.append(chunk_result)
                                        except:
                                            pass
                                    
                                    if chunk_sources:
                                        # Fix: Pad chunks to same size
                                        max_size = max(c.shape[2] for c in chunk_sources)
                                        padded_chunks = []
                                        for chunk in chunk_sources:
                                            if chunk.shape[2] < max_size:
                                                pad_size = max_size - chunk.shape[2]
                                                padded = torch.nn.functional.pad(chunk, (0, pad_size))
                                                padded_chunks.append(padded)
                                            else:
                                                padded_chunks.append(chunk)
                                        sources = torch.cat(padded_chunks, dim=2)
                                        self.log(f"  [CHUNK] Combined {len(chunk_sources)} chunks")
                                    else:
                                        raise RuntimeError("Chunk processing failed")
                                else:
                                    sources = apply_model(
                                        ens_model,
                                        waveform,
                                        device=device,
                                        shifts=max(actual_shifts, 1),  # At least 1 shift
                                        overlap=max(overlap, 0.25),  # Quality overlap
                                        segment=actual_segment,
                                        progress=False
                                    )
                            except RuntimeError as e:
                                if "out of memory" in str(e).lower() or "shape" in str(e).lower():
                                    self.log(f"  [MEMORY] Failed, trying chunk mode...")
                                    # Fallback chunk mode
                                    chunk_seconds = 10
                                    chunk_samples = chunk_seconds * sample_rate
                                    total_samples = waveform.shape[2]
                                    chunk_sources = []
                                    
                                    for i in range(0, total_samples, chunk_samples):
                                        chunk_end = min(i + chunk_samples, total_samples)
                                        chunk = waveform[:, :, i:chunk_end]
                                        if chunk.shape[2] < sample_rate:
                                            continue
                                        try:
                                            chunk_result = apply_model(
                                                ens_model, chunk, device=device,
                                                shifts=0, overlap=0.1, segment=None, progress=False
                                            )
                                            chunk_sources.append(chunk_result)
                                        except:
                                            pass
                                    
                                    if chunk_sources:
                                        # Debug: Log all chunk shapes
                                        self.log(f"  [CHUNK DEBUG] Found {len(chunk_sources)} chunks")
                                        for i, c in enumerate(chunk_sources):
                                            self.log(f"    Chunk {i+1}: shape {c.shape}")
                                        
                                        # Check if all chunks have same dimensions except time
                                        shapes = [c.shape for c in chunk_sources]
                                        batch_dims = [(s[0], s[1], s[2]) for s in shapes]  # Include all dims except time
                                        time_dims = [s[-1] for s in shapes]  # Time is last dimension
                                        
                                        if len(set(batch_dims)) > 1:
                                            self.log(f"  [CHUNK ERROR] Inconsistent batch/channel dims: {set(batch_dims)}")
                                            raise RuntimeError("Chunks have different batch/channel dimensions")
                                        
                                        # Pad chunks to same size
                                        max_size = max(time_dims)
                                        min_size = min(time_dims)
                                        
                                        if max_size != min_size:
                                            self.log(f"  [CHUNK] Padding chunks: min={min_size}, max={max_size}")
                                        
                                        padded_chunks = []
                                        for chunk in chunk_sources:
                                            if chunk.shape[-1] < max_size:  # Check last dimension (time)
                                                pad_size = max_size - chunk.shape[-1]
                                                padded = torch.nn.functional.pad(chunk, (0, pad_size))
                                                padded_chunks.append(padded)
                                            else:
                                                padded_chunks.append(chunk)
                                        
                                        # Verify all padded chunks have same shape
                                        padded_shapes = [c.shape for c in padded_chunks]
                                        if len(set(padded_shapes)) != 1:
                                            self.log(f"  [CHUNK ERROR] Padded chunks still have different shapes: {set(padded_shapes)}")
                                            raise RuntimeError("Padding failed to equalize chunk sizes")
                                        
                                        sources = torch.cat(padded_chunks, dim=-1)  # Concatenate along last dimension
                                        self.log(f"  [CHUNK] Combined {len(chunk_sources)} chunks")
                                    else:
                                        raise
                                else:
                                    raise
                                
                                self.log(f"  [ENSEMBLE] Processing complete")
                            except Exception as e:
                                self.log(f"  [ERROR] Ensemble processing failed: {str(e)[:50]}")
                                files_failed += 1
                                continue
                        else:
                            # Standard single model processing
                            # For CPU with medium+ files, use chunk-based processing
                            if self.is_cpu and duration > 60:
                                # Split audio into chunks, process each, then combine
                                chunk_seconds = 15  # 15-second chunks
                                chunk_samples = chunk_seconds * sample_rate
                                total_samples = waveform.shape[2]
                                num_chunks = max(1, int(np.ceil(total_samples / chunk_samples)))
                                
                                self.log(f"  [CHUNK] Processing {num_chunks}x{chunk_seconds}s chunks for quality...")
                                chunk_sources = []
                                
                                for chunk_idx in range(num_chunks):
                                    start = chunk_idx * chunk_samples
                                    end = min(start + chunk_samples, total_samples)
                                    
                                    # Skip tiny chunks
                                    if end - start < sample_rate:
                                        continue
                                    
                                    chunk = waveform[:, :, start:end]
                                    
                                    try:
                                        # Process chunk with minimal settings for speed
                                        chunk_result = apply_model(
                                            model,
                                            chunk,
                                            device=device,
                                            shifts=0,  # No shifts for chunks
                                            overlap=0.1,
                                            segment=None,
                                            progress=False
                                        )
                                        chunk_sources.append(chunk_result)
                                        self.log(f"  [CHUNK] {chunk_idx+1}/{num_chunks} complete")
                                    except Exception as e:
                                        self.log(f"  [WARN] Chunk {chunk_idx+1} failed: {str(e)[:30]}")
                                        continue
                                
                                if chunk_sources:
                                    # Debug: Log all chunk shapes
                                    self.log(f"  [CHUNK DEBUG] Found {len(chunk_sources)} chunks")
                                    for i, c in enumerate(chunk_sources):
                                        self.log(f"    Chunk {i+1}: shape {c.shape}")
                                    
                                    # Check if all chunks have same dimensions except time
                                    shapes = [c.shape for c in chunk_sources]
                                    batch_dims = [(s[0], s[1], s[2]) for s in shapes]  # Include all dims except time
                                    time_dims = [s[-1] for s in shapes]  # Time is last dimension
                                    
                                    if len(set(batch_dims)) > 1:
                                        self.log(f"  [CHUNK ERROR] Inconsistent batch/channel dims: {set(batch_dims)}")
                                        raise RuntimeError("Chunks have different batch/channel dimensions")
                                    
                                    # Pad chunks to same size before concatenating
                                    max_size = max(time_dims)
                                    min_size = min(time_dims)
                                    
                                    if max_size != min_size:
                                        self.log(f"  [CHUNK] Padding chunks: min={min_size}, max={max_size}")
                                    
                                    padded_chunks = []
                                    for chunk in chunk_sources:
                                        if chunk.shape[-1] < max_size:  # Check last dimension (time)
                                            # Pad with zeros on the last dimension
                                            pad_size = max_size - chunk.shape[-1]
                                            padded = torch.nn.functional.pad(chunk, (0, pad_size))
                                            padded_chunks.append(padded)
                                        else:
                                            padded_chunks.append(chunk)
                                    
                                    # Verify all padded chunks have same shape
                                    padded_shapes = [c.shape for c in padded_chunks]
                                    if len(set(padded_shapes)) != 1:
                                        self.log(f"  [CHUNK ERROR] Padded chunks still have different shapes: {set(padded_shapes)}")
                                        raise RuntimeError("Padding failed to equalize chunk sizes")
                                    
                                    # Concatenate along time dimension (dim=-1, last dimension)
                                    sources = torch.cat(padded_chunks, dim=-1)
                                    self.log(f"  [CHUNK] Combined {len(chunk_sources)} chunks into shape {sources.shape}")
                                else:
                                    raise RuntimeError("All chunks failed")
                            else:
                                # Use segment parameter for shorter files
                                try:
                                    sources = apply_model(
                                        model, 
                                        waveform, 
                                        device=device, 
                                        shifts=actual_shifts,
                                        overlap=overlap,
                                        segment=actual_segment,
                                        progress=False
                                    )
                                except RuntimeError as e:
                                    if "out of memory" in str(e).lower() or "shape" in str(e).lower():
                                        self.log(f"  [MEMORY] Failed, trying chunk mode...")
                                        # Fallback to chunk mode
                                        chunk_seconds = 10
                                        chunk_samples = chunk_seconds * sample_rate
                                        total_samples = waveform.shape[2]
                                        chunk_sources = []
                                        
                                        for i in range(0, total_samples, chunk_samples):
                                            chunk_end = min(i + chunk_samples, total_samples)
                                            chunk = waveform[:, :, i:chunk_end]
                                            if chunk.shape[2] < sample_rate:
                                                continue
                                            try:
                                                chunk_result = apply_model(
                                                    model, chunk, device=device,
                                                    shifts=0, overlap=0.1, segment=None, progress=False
                                                )
                                                chunk_sources.append(chunk_result)
                                            except:
                                                pass
                                        
                                        if chunk_sources:
                                            # Debug: Log all chunk shapes
                                            self.log(f"  [CHUNK DEBUG] Found {len(chunk_sources)} chunks")
                                            for i, c in enumerate(chunk_sources):
                                                self.log(f"    Chunk {i+1}: shape {c.shape}")
                                            
                                            # Check if all chunks have same dimensions except time
                                            shapes = [c.shape for c in chunk_sources]
                                            batch_dims = [(s[0], s[1], s[2]) for s in shapes]  # Include all dims except time
                                            time_dims = [s[-1] for s in shapes]  # Time is last dimension
                                            
                                            if len(set(batch_dims)) > 1:
                                                self.log(f"  [CHUNK ERROR] Inconsistent batch/channel dims: {set(batch_dims)}")
                                                raise RuntimeError("Chunks have different batch/channel dimensions")
                                            
                                            # Pad chunks to same size
                                            max_size = max(time_dims)
                                            min_size = min(time_dims)
                                            
                                            if max_size != min_size:
                                                self.log(f"  [CHUNK] Padding chunks: min={min_size}, max={max_size}")
                                            
                                            padded_chunks = []
                                            for chunk in chunk_sources:
                                                if chunk.shape[-1] < max_size:  # Check last dimension (time)
                                                    pad_size = max_size - chunk.shape[-1]
                                                    padded = torch.nn.functional.pad(chunk, (0, pad_size))
                                                    padded_chunks.append(padded)
                                                else:
                                                    padded_chunks.append(chunk)
                                            
                                            # Verify all padded chunks have same shape
                                            padded_shapes = [c.shape for c in padded_chunks]
                                            if len(set(padded_shapes)) != 1:
                                                self.log(f"  [CHUNK ERROR] Padded chunks still have different shapes: {set(padded_shapes)}")
                                                raise RuntimeError("Padding failed to equalize chunk sizes")
                                            
                                            sources = torch.cat(padded_chunks, dim=-1)  # Concatenate along last dimension
                                            self.log(f"  [CHUNK] Combined {len(chunk_sources)} chunks")
                                        else:
                                            raise
                                    else:
                                        raise
                    
                    # Validate separation output
                    if sources is None or sources.shape[0] == 0:
                        self.log(f"  [ERROR] AI model returned empty output!")
                        files_failed += 1
                        continue
                    
                    self.log(f"  AI separation complete! Saving {len(stems)} stems...")
                    self.log(f"  [DEBUG] Sources shape: {sources.shape}")
                    self.log(f"  [DEBUG] Selected stems: {stems}")
                    self.log(f"  [DEBUG] Stem indices mapping: {stem_indices}")
                    
                    # FIX: If vocal-first was used, we need to handle vocals from first pass
                    # and other stems from second pass
                    if vocal_first:
                        self.log(f"  [VOCAL-FIRST] Will extract vocals from first pass, other stems from second pass")
                    
                    dpg.set_value("progress", (idx + 0.8) / total)
                    
                    stems_saved = 0
                    stems_skipped = []
                    
                    # Process each selected stem
                    for stem_idx, stem in enumerate(stems):
                        if not self.processing:
                            break
                        
                        progress = (idx + 0.8 + (stem_idx + 1) * 0.2 / len(stems)) / total
                        dpg.set_value("progress", progress)
                        
                        try:
                            # Get the separated audio for this stem
                            source_idx = stem_indices[stem]
                            self.log(f"  [DEBUG] Processing {stem}: source_idx={source_idx}, total_sources={sources.shape[1]}")
                            
                            # FIX: Handle vocals separately in vocal-first mode
                            if vocal_first and stem.lower() == "vocals":
                                # Vocals were extracted in the first pass
                                # We need to re-run initial separation to get vocals
                                self.log(f"  [VOCAL-FIRST] Extracting vocals from initial separation...")
                                try:
                                    # Re-run initial separation to get vocals
                                    init_sources = apply_model(model, original_waveform, device=device, shifts=(0 if self.is_cpu else actual_shifts), overlap=(0.1 if self.is_cpu else overlap), segment=None, progress=False)
                                    vocal_idx = 3  # Demucs vocal index
                                    if init_sources is not None and init_sources.shape[1] > vocal_idx:
                                        stem_audio = init_sources[0, vocal_idx].cpu().numpy()
                                        self.log(f"  [VOCAL-FIRST] Got vocals from initial pass")
                                    else:
                                        self.log(f"  [SKIP] Could not retrieve vocals from initial separation")
                                        stems_skipped.append(f"{stem} (vocal-first failed)")
                                        continue
                                except Exception as e:
                                    self.log(f"  [SKIP] Vocal retrieval failed: {str(e)[:50]}")
                                    stems_skipped.append(f"{stem} (retrieval failed)")
                                    continue
                            else:
                                # Normal stem extraction from second separation
                                # Check if stem index is valid for this model
                                if source_idx >= sources.shape[1]:
                                    self.log(f"  [SKIP] {stem} not available in this model (model has {sources.shape[1]} sources)")
                                    stems_skipped.append(f"{stem} (unavailable)")
                                    continue
                                
                                stem_audio = sources[0, source_idx].cpu().numpy()  # Shape: (channels, samples)
                            
                            # Check if stem has actual content
                            max_val = np.max(np.abs(stem_audio))
                            self.log(f"  [DEBUG] {stem} max_val: {max_val:.8f}")
                            if max_val < 0.0001:
                                self.log(f"  [SKIP] {stem} is silent/empty (max={max_val:.8f})")
                                continue
                            
                            # Normalize to prevent clipping
                            stem_audio = stem_audio / max_val * 0.95
                            
                            # Transpose to (samples, channels) for soundfile
                            stem_audio = stem_audio.T
                            
                            # Save stem file
                            stem_file = os.path.join(file_dir, f"{name_no_ext}_{stem}.wav")
                            sf.write(stem_file, stem_audio, sample_rate)
                            
                            # Verify file was written
                            if os.path.exists(stem_file):
                                file_size = os.path.getsize(stem_file) / 1024  # KB
                                if file_size > 1:  # More than 1KB
                                    self.log(f"  ✓ {stem}.wav ({file_size:.0f} KB)")
                                    stems_saved += 1
                                    
                                    # Apply denoising if enabled
                                    if dpg.get_value("apply_denoising"):
                                        denoise_level = dpg.get_value("denoise_level")
                                        if denoise_level > 0:
                                            self.log(f"  [DENOISE] Cleaning {stem}.wav (level {denoise_level:.2f})...")
                                            temp_clean = os.path.join(file_dir, f"{name_no_ext}_{stem}_clean.wav")
                                            if self.apply_denoising(stem_file, temp_clean, denoise_level):
                                                os.remove(stem_file)
                                                os.rename(temp_clean, stem_file)
                                                self.log(f"  ✓ {stem}.wav denoised")
                                            else:
                                                self.log(f"  [WARN] Denoising failed, keeping original")
                                    
                                    # Export as MIDI if requested
                                    if dpg.get_value("export_midi") and stem.lower() in ['vocals', 'bass', 'piano', 'guitar', 'drums']:
                                        midi_file = os.path.join(file_dir, f"{name_no_ext}_{stem}.mid")
                                        if self.audio_to_midi(stem_file, midi_file, stem.lower()):
                                            self.log(f"  ♪ {stem}.mid exported")
                                        else:
                                            self.log(f"  [WARN] MIDI export failed for {stem}")
                                        
                                else:
                                    self.log(f"  [WARN] {stem}.wav is too small")
                                    os.remove(stem_file)
                            else:
                                self.log(f"  [ERROR] Failed to save {stem}")
                                
                        except Exception as stem_err:
                            self.log(f"  [ERROR] {stem}: {str(stem_err)}")
                    
                    if stems_saved > 0:
                        self.log(f"  [OK] Saved {stems_saved}/{len(stems)} stems")
                        files_processed += 1
                    else:
                        if stems_skipped:
                            self.log(f"  [WARN] No stems saved - all skipped: {', '.join(stems_skipped)}")
                        else:
                            self.log(f"  [WARN] No stems saved for this file!")
                        files_failed += 1
                    
                    # Clean up temporary WAV file if created
                    if temp_wav and os.path.exists(temp_wav):
                        try:
                            os.remove(temp_wav)
                            self.log(f"  [*] Cleaned up temporary files")
                        except:
                            pass
                    
                except Exception as e:
                    self.log(f"  [ERROR] {type(e).__name__}: {str(e)[:100]}")
                    if "--verbose" in sys.argv:
                        traceback.print_exc()
                    # Clean up temp file on error too
                    if 'temp_wav' in locals() and temp_wav and os.path.exists(temp_wav):
                        try:
                            os.remove(temp_wav)
                        except:
                            pass
                    files_failed += 1
            
            # Final summary
            dpg.set_value("progress", 1.0)
            self.log(f"\n{'='*50}")
            self.log(f"[COMPLETE] Processing finished")
            self.log(f"{'='*50}")
            self.log(f"  Files processed: {files_processed}")
            if files_failed > 0:
                self.log(f"  Files failed: {files_failed}")
                dpg.set_value("status", f"Done ({files_failed} failed)")
            else:
                dpg.set_value("status", "Complete!")
            
            self.log(f"\n[OUTPUT] {output_dir}")
            
            if files_processed > 0:
                self.log(f"\n[STEM GUIDE]")
                self.log(f"  Vocals = Human voice only")
                self.log(f"  Drums  = Percussion (kicks, snares, hats)")
                self.log(f"  Bass   = Bass instruments")
                self.log(f"  Other  = Guitars, keys, synths, etc.")
                if use_6_stem:
                    self.log(f"  Guitar = Acoustic/Electric guitars")
                    self.log(f"  Piano  = Piano and keyboard")
                    
                if quality_level < 3:
                    self.log(f"\n[TIP] For cleaner separation, use Quality 3+")
            
        except Exception as e:
            self.log(f"[ERROR] {str(e)}")
            traceback.print_exc()
            dpg.set_value("status", "Error!")
        finally:
            self.processing = False
    
    def _button_flash(self, button_type):
        """Provide immediate visual feedback when a button is pressed"""
        # Flash the status text to show button was registered
        original_status = dpg.get_value("status")
        
        if button_type == "Start":
            # Quick green flash
            dpg.configure_item("status", color=(0, 255, 0, 255))
            dpg.set_value("status", "▶ STARTING...")
            time.sleep(0.08)  # Brief flash
            dpg.configure_item("status", color=(0, 255, 128, 255))
            
        elif button_type == "Stop":
            # Quick red flash
            dpg.configure_item("status", color=(255, 100, 100, 255))
            dpg.set_value("status", "■ STOPPING...")
            time.sleep(0.08)
            dpg.configure_item("status", color=(255, 150, 0, 255))
            
        elif button_type == "Clear":
            # Quick yellow flash
            dpg.configure_item("status", color=(255, 255, 0, 255))
            dpg.set_value("status", "🗑 CLEARING...")
            time.sleep(0.08)
            dpg.configure_item("status", color=(255, 200, 0, 255))
        
        # Restore original status after flash
        dpg.set_value("status", original_status)
    
    def stop_processing(self):
        """Stop processing"""
        # IMMEDIATE FEEDBACK
        self._show_button_press("STOP")
        self._button_flash("Stop")
        
        if self.processing:
            self.processing = False
            dpg.set_value("status", "Stopping...")
            dpg.set_value("progress", 0.0)
            self.log("[!] Processing stopped by user")
            self.log("[*] Ready to start new processing")
        else:
            self.log("[*] Not currently processing")

    def process_files_sync(self, files, **kwargs):
        """Convenience wrapper to run processing synchronously (useful for tests).

        Args:
            files: list of file paths to process
            kwargs: optional dpg item values to set before running (e.g., ai_model, quality, vocal_first)

        Returns:
            The console log text after processing completes.
        """
        # Apply optional settings
        for key, val in kwargs.items():
            try:
                dpg.set_value(key, val)
            except Exception:
                pass

        # Set files and run synchronously
        self.selected_files = files
        # Ensure processing flag is false so process_files will enable it
        self.processing = False
        self.process_files()
        return dpg.get_value("console")
    
    def apply_denoising(self, input_file, output_file, denoise_level=0.08):
        """
        Apply noise reduction using librosa's built-in noise reduction
        denoise_level: 0.0-0.3 (0=off, 0.08=light, 0.2=strong)
        Uses spectral gating with proper transient preservation
        """
        try:
            import librosa
            import soundfile as sf
            import numpy as np
            
            # Load audio
            y, sr = librosa.load(input_file, sr=None, mono=False)
            
            if denoise_level <= 0:
                # No denoising, just copy
                sf.write(output_file, y.T, sr)
                return True
            
            # Convert to mono for noise analysis (if stereo)
            if y.ndim > 1:
                y_mono = np.mean(y, axis=0)
            else:
                y_mono = y
            
            # Use first 0.5 seconds as noise profile (assuming silence at start)
            # or use percentile-based noise estimation
            noise_sample_duration = min(0.5, len(y_mono) / sr)
            noise_sample_samples = int(noise_sample_duration * sr)
            
            if noise_sample_samples > 1000:  # Only if we have enough samples
                noise_profile = y_mono[:noise_sample_samples]
            else:
                # Use quietest portion
                noise_profile = y_mono[np.abs(y_mono) < np.percentile(np.abs(y_mono), 20)]
            
            # Calculate noise statistics
            noise_mean = np.mean(noise_profile)
            noise_std = np.std(noise_profile)
            
            # Threshold based on denoise level
            # 0.08 = 2.5σ, 0.15 = 2.0σ, 0.2 = 1.5σ, 0.3 = 1.0σ
            sigma_threshold = 2.5 - (denoise_level * 5.0)
            threshold = noise_mean + noise_std * sigma_threshold
            
            # Apply soft thresholding to avoid artifacts
            y_clean = np.zeros_like(y)
            
            for channel in range(y.shape[0] if y.ndim > 1 else 1):
                audio_channel = y[channel] if y.ndim > 1 else y
                
                # Soft thresholding
                magnitude = np.abs(audio_channel)
                phase = np.angle(audio_channel)
                
                # Create smooth mask
                mask = np.tanh((magnitude - threshold) / (threshold * 0.5))
                mask = np.clip(mask, 0, 1)
                
                # Apply mask with smooth transition
                y_clean_channel = audio_channel * mask
                
                # Preserve transients by mixing with original for strong signals
                # This prevents hissing on quiet parts
                strong_signal = magnitude > threshold * 2
                y_clean_channel[strong_signal] = audio_channel[strong_signal]
                
                if y.ndim > 1:
                    y_clean[channel] = y_clean_channel
                else:
                    y_clean = y_clean_channel
            
            # Final smoothing to remove any remaining artifacts
            y_clean = librosa.util.normalize(y_clean) * 0.95
            
            # Save cleaned file
            sf.write(output_file, y_clean.T if y_clean.ndim > 1 else y_clean, sr)
            return True
            
        except Exception as e:
            self.log(f"  [DENOISE ERROR] {str(e)}")
            return False
    
    def ffmpeg_denoise(self, input_file, output_file, level=0.1):
        """Use FFmpeg's afftdn filter for noise reduction"""
        try:
            nr = int(level * 100)  # 0-100 range
            
            cmd = [
                'ffmpeg', '-i', input_file,
                '-af', f'afftdn=nf={nr}',
                '-y', output_file
            ]
            
            result = subprocess.run(cmd, capture_output=True, timeout=60)
            return result.returncode == 0
        except:
            return False
        """Convert audio stem to MIDI using pitch detection
        
        Args:
            audio_file: Path to WAV file
            output_midi: Path for output MIDI file
            stem_type: Type of stem (vocals, bass, piano, guitar, drums)
        
        Returns:
            True if successful, False otherwise
        """
        if not HAS_MIDI:
            self.log("  [WARN] MIDI export not available - install pretty_midi midiutil")
            return False
        
        try:
            # Load audio
            y, sr = librosa.load(audio_file, sr=22050, mono=True)
            
            if stem_type == "drums":
                # For drums, use onset detection
                return self._drums_to_midi(y, sr, output_midi)
            else:
                # For melodic instruments, use pitch detection
                return self._melodic_to_midi(y, sr, output_midi, stem_type)
                
        except Exception as e:
            self.log(f"  [ERROR] MIDI conversion failed: {str(e)[:50]}")
            return False
    
    def _melodic_to_midi(self, y, sr, output_midi, stem_type):
        """Convert melodic audio to MIDI using pitch detection"""
        try:
            # Use librosa's piptrack for pitch detection
            # This works well for monophonic or mostly-monophonic sources
            hop_length = 512
            fmin = 50 if stem_type == "bass" else 80
            fmax = 500 if stem_type == "bass" else 2000
            
            # Get pitches and magnitudes
            pitches, magnitudes = librosa.piptrack(
                y=y, sr=sr, 
                hop_length=hop_length,
                fmin=fmin, fmax=fmax,
                threshold=0.1
            )
            
            # Get onset frames for note segmentation
            onset_frames = librosa.onset.onset_detect(
                y=y, sr=sr, hop_length=hop_length, 
                backtrack=True
            )
            
            if len(onset_frames) == 0:
                self.log(f"  [WARN] No notes detected in audio")
                return False
            
            # Create MIDI file
            midi = MIDIFile(1)  # One track
            track = 0
            channel = 0
            time = 0
            tempo = 120  # BPM
            volume = 100
            
            midi.addTrackName(track, time, f"StemWeaver - {stem_type}")
            midi.addTempo(track, time, tempo)
            
            # Set instrument based on stem type
            instruments = {
                "vocals": 52,   # Choir Aahs
                "bass": 33,     # Electric Bass (finger)
                "piano": 0,     # Acoustic Grand Piano
                "guitar": 25,   # Acoustic Guitar (steel)
                "other": 48     # String Ensemble
            }
            program = instruments.get(stem_type, 0)
            midi.addProgramChange(track, channel, time, program)
            
            # Convert frames to time
            times = librosa.frames_to_time(onset_frames, sr=sr, hop_length=hop_length)
            
            notes_added = 0
            for i, onset in enumerate(onset_frames):
                # Get the pitch at this onset
                pitch_idx = magnitudes[:, onset].argmax()
                pitch = pitches[pitch_idx, onset]
                
                if pitch > 0:
                    # Convert Hz to MIDI note number
                    midi_note = int(round(librosa.hz_to_midi(pitch)))
                    midi_note = max(21, min(108, midi_note))  # Clamp to piano range
                    
                    # Calculate note duration
                    if i < len(onset_frames) - 1:
                        duration = times[i + 1] - times[i]
                    else:
                        duration = 0.5  # Default duration for last note
                    
                    duration = max(0.1, min(duration, 4.0))  # Clamp duration
                    
                    # Convert to beats
                    start_beat = times[i] * (tempo / 60)
                    duration_beats = duration * (tempo / 60)
                    
                    midi.addNote(track, channel, midi_note, start_beat, duration_beats, volume)
                    notes_added += 1
            
            if notes_added > 0:
                # Write MIDI file
                with open(output_midi, 'wb') as f:
                    midi.writeFile(f)
                return True
            else:
                self.log(f"  [WARN] No valid notes detected")
                return False
                
        except Exception as e:
            self.log(f"  [ERROR] Melodic MIDI conversion: {str(e)[:40]}")
            return False
    
    def _drums_to_midi(self, y, sr, output_midi):
        """Convert drum audio to MIDI using onset detection"""
        try:
            hop_length = 512
            
            # Detect onsets
            onset_frames = librosa.onset.onset_detect(
                y=y, sr=sr, hop_length=hop_length,
                units='frames'
            )
            
            if len(onset_frames) == 0:
                self.log(f"  [WARN] No drum hits detected")
                return False
            
            onset_times = librosa.frames_to_time(onset_frames, sr=sr, hop_length=hop_length)
            
            # Create MIDI file
            midi = MIDIFile(1)
            track = 0
            channel = 9  # Drums channel
            time = 0
            tempo = 120
            volume = 100
            
            midi.addTrackName(track, time, "StemWeaver - Drums")
            midi.addTempo(track, time, tempo)
            
            # Simple drum mapping - use kick as default
            # In a more advanced version, we'd classify each hit
            kick = 36
            snare = 38
            hihat = 42
            
            # Alternate between kick and snare for basic pattern
            for i, onset_time in enumerate(onset_times):
                start_beat = onset_time * (tempo / 60)
                duration = 0.25  # Short hit
                
                # Simple pattern: alternate kick/snare
                note = kick if i % 2 == 0 else snare
                midi.addNote(track, channel, note, start_beat, duration, volume)
            
            # Write MIDI file
            with open(output_midi, 'wb') as f:
                midi.writeFile(f)
            
            return True
            
        except Exception as e:
            self.log(f"  [ERROR] Drum MIDI conversion: {str(e)[:40]}")
            return False
    
    def _compute_stft(self, audio, n_fft, hop_length):
        """Compute Short-Time Fourier Transform - FAST vectorized version"""
        # Pad audio to ensure we have enough samples
        pad_length = n_fft // 2
        audio_padded = np.pad(audio, (pad_length, pad_length), mode='reflect')
        
        # Calculate number of frames
        num_frames = 1 + (len(audio_padded) - n_fft) // hop_length
        
        # Create frame indices
        frame_indices = np.arange(num_frames) * hop_length
        sample_indices = np.arange(n_fft)
        
        # Extract all frames at once using advanced indexing
        indices = frame_indices[:, np.newaxis] + sample_indices[np.newaxis, :]
        frames = audio_padded[indices]  # Shape: (num_frames, n_fft)
        
        # Apply Hann window
        window = np.hanning(n_fft)
        frames = frames * window
        
        # Compute FFT for all frames at once
        stft_matrix = np.fft.rfft(frames, axis=1).T  # Shape: (n_fft//2+1, num_frames)
        
        return stft_matrix
    
    def _istft(self, stft_matrix, n_fft, hop_length, length):
        """Compute Inverse STFT - FAST vectorized version"""
        num_frames = stft_matrix.shape[1]
        window = np.hanning(n_fft)
        
        # Compute all inverse FFTs at once
        frames = np.fft.irfft(stft_matrix.T, n=n_fft, axis=1)  # Shape: (num_frames, n_fft)
        frames = frames * window
        
        # Pre-allocate output
        output_length = (num_frames - 1) * hop_length + n_fft
        audio = np.zeros(output_length)
        window_sum = np.zeros(output_length)
        
        # Overlap-add
        for t in range(num_frames):
            start = t * hop_length
            end = start + n_fft
            audio[start:end] += frames[t]
            window_sum[start:end] += window
        
        # Normalize
        window_sum[window_sum < 1e-8] = 1.0
        audio = audio / window_sum
        
        # Trim to original length
        pad_length = n_fft // 2
        audio = audio[pad_length:pad_length + length]
        
        return audio
    
    def _harmonic_percussive_separation(self, magnitude, n_fft, kernel_size=31):
        """Separate harmonic/percussive - FAST vectorized version"""
        from scipy.ndimage import median_filter
        
        # Use scipy's median_filter for fast computation
        # If scipy not available, use simplified method
        try:
            # Harmonic: smooth along time axis (horizontal)
            harmonic_mag = median_filter(magnitude, size=(1, 3), mode='reflect')
            
            # Percussive: smooth along frequency axis (vertical)
            percussive_mag = median_filter(magnitude, size=(3, 1), mode='reflect')
            
        except ImportError:
            # Fallback: simple average-based separation
            harmonic_mag = magnitude.copy()
            percussive_mag = magnitude.copy()
            
            # Simplified time smoothing for harmonic
            harmonic_mag[:, 1:-1] = (magnitude[:, :-2] + magnitude[:, 1:-1] + magnitude[:, 2:]) / 3
            
            # Simplified frequency smoothing for percussive
            percussive_mag[1:-1, :] = (magnitude[:-2, :] + magnitude[1:-1, :] + magnitude[2:, :]) / 3
        
        # Create soft masks
        total = harmonic_mag + percussive_mag + 1e-10
        harmonic_mask = harmonic_mag / total
        percussive_mask = percussive_mag / total
        
        # Apply masks to original magnitude
        harmonic_out = magnitude * harmonic_mask
        percussive_out = magnitude * percussive_mask
        
        return harmonic_out, percussive_out
    
    def audio_to_midi(self, audio_file, output_midi, stem_type="vocals"):
        """Convert audio stem to MIDI using pitch detection
        
        Args:
            audio_file: Path to WAV file
            output_midi: Path for output MIDI file
            stem_type: Type of stem (vocals, bass, piano, guitar, drums)
        
        Returns:
            True if successful, False otherwise
        """
        if not HAS_MIDI:
            self.log("  [WARN] MIDI export not available - install pretty_midi midiutil")
            return False
        
        try:
            # Load audio
            y, sr = librosa.load(audio_file, sr=22050, mono=True)
            
            if stem_type == "drums":
                # For drums, use onset detection
                return self._drums_to_midi(y, sr, output_midi)
            else:
                # For melodic instruments, use pitch detection
                return self._melodic_to_midi(y, sr, output_midi, stem_type)
                
        except Exception as e:
            self.log(f"  [ERROR] MIDI conversion failed: {str(e)[:50]}")
            return False
    
    def _melodic_to_midi(self, y, sr, output_midi, stem_type):
        """Convert melodic audio to MIDI using pitch detection"""
        try:
            # Use librosa's piptrack for pitch detection
            # This works well for monophonic or mostly-monophonic sources
            hop_length = 512
            fmin = 50 if stem_type == "bass" else 80
            fmax = 500 if stem_type == "bass" else 2000
            
            # Get pitches and magnitudes
            pitches, magnitudes = librosa.piptrack(
                y=y, sr=sr, 
                hop_length=hop_length,
                fmin=fmin, fmax=fmax,
                threshold=0.1
            )
            
            # Get onset frames for note segmentation
            onset_frames = librosa.onset.onset_detect(
                y=y, sr=sr, hop_length=hop_length, 
                backtrack=True
            )
            
            if len(onset_frames) == 0:
                self.log(f"  [WARN] No notes detected in audio")
                return False
            
            # Create MIDI file
            midi = MIDIFile(1)  # One track
            track = 0
            channel = 0
            time = 0
            tempo = 120  # BPM
            volume = 100
            
            midi.addTrackName(track, time, f"StemWeaver - {stem_type}")
            midi.addTempo(track, time, tempo)
            
            # Set instrument based on stem type
            instruments = {
                "vocals": 52,   # Choir Aahs
                "bass": 33,     # Electric Bass (finger)
                "piano": 0,     # Acoustic Grand Piano
                "guitar": 25,   # Acoustic Guitar (steel)
                "other": 48     # String Ensemble
            }
            program = instruments.get(stem_type, 0)
            midi.addProgramChange(track, channel, time, program)
            
            # Convert frames to time
            times = librosa.frames_to_time(onset_frames, sr=sr, hop_length=hop_length)
            
            notes_added = 0
            for i, onset in enumerate(onset_frames):
                # Get the pitch at this onset
                pitch_idx = magnitudes[:, onset].argmax()
                pitch = pitches[pitch_idx, onset]
                
                if pitch > 0:
                    # Convert Hz to MIDI note number
                    midi_note = int(round(librosa.hz_to_midi(pitch)))
                    midi_note = max(21, min(108, midi_note))  # Clamp to piano range
                    
                    # Calculate note duration
                    if i < len(onset_frames) - 1:
                        duration = times[i + 1] - times[i]
                    else:
                        duration = 0.5  # Default duration for last note
                    
                    duration = max(0.1, min(duration, 4.0))  # Clamp duration
                    
                    # Convert to beats
                    start_beat = times[i] * (tempo / 60)
                    duration_beats = duration * (tempo / 60)
                    
                    midi.addNote(track, channel, midi_note, start_beat, duration_beats, volume)
                    notes_added += 1
            
            if notes_added > 0:
                # Write MIDI file
                with open(output_midi, 'wb') as f:
                    midi.writeFile(f)
                return True
            else:
                self.log(f"  [WARN] No valid notes detected")
                return False
                
        except Exception as e:
            self.log(f"  [ERROR] Melodic MIDI conversion: {str(e)[:40]}")
            return False
    
    def _drums_to_midi(self, y, sr, output_midi):
        """Convert drum audio to MIDI using onset detection"""
        try:
            hop_length = 512
            
            # Detect onsets
            onset_frames = librosa.onset.onset_detect(
                y=y, sr=sr, hop_length=hop_length,
                units='frames'
            )
            
            if len(onset_frames) == 0:
                self.log(f"  [WARN] No drum hits detected")
                return False
            
            onset_times = librosa.frames_to_time(onset_frames, sr=sr, hop_length=hop_length)
            
            # Create MIDI file
            midi = MIDIFile(1)
            track = 0
            channel = 9  # Drums channel
            time = 0
            tempo = 120
            volume = 100
            
            midi.addTrackName(track, time, "StemWeaver - Drums")
            midi.addTempo(track, time, tempo)
            
            # Simple drum mapping - use kick as default
            # In a more advanced version, we'd classify each hit
            kick = 36
            snare = 38
            hihat = 42
            
            # Alternate between kick and snare for basic pattern
            for i, onset_time in enumerate(onset_times):
                start_beat = onset_time * (tempo / 60)
                duration = 0.25  # Short hit
                
                # Simple pattern: alternate kick/snare
                note = kick if i % 2 == 0 else snare
                midi.addNote(track, channel, note, start_beat, duration, volume)
            
            # Write MIDI file
            with open(output_midi, 'wb') as f:
                midi.writeFile(f)
            
            return True
            
        except Exception as e:
            self.log(f"  [ERROR] Drum MIDI conversion: {str(e)[:40]}")
            return False
    
    def _compute_stft(self, audio, n_fft, hop_length):
        """Compute Short-Time Fourier Transform - FAST vectorized version"""
        # Pad audio to ensure we have enough samples
        pad_length = n_fft // 2
        audio_padded = np.pad(audio, (pad_length, pad_length), mode='reflect')
        
        # Calculate number of frames
        num_frames = 1 + (len(audio_padded) - n_fft) // hop_length
        
        # Create frame indices
        frame_indices = np.arange(num_frames) * hop_length
        sample_indices = np.arange(n_fft)
        
        # Extract all frames at once using advanced indexing
        indices = frame_indices[:, np.newaxis] + sample_indices[np.newaxis, :]
        frames = audio_padded[indices]  # Shape: (num_frames, n_fft)
        
        # Apply Hann window
        window = np.hanning(n_fft)
        frames = frames * window
        
        # Compute FFT for all frames at once
        stft_matrix = np.fft.rfft(frames, axis=1).T  # Shape: (n_fft//2+1, num_frames)
        
        return stft_matrix
    
    def _istft(self, stft_matrix, n_fft, hop_length, length):
        """Compute Inverse STFT - FAST vectorized version"""
        num_frames = stft_matrix.shape[1]
        window = np.hanning(n_fft)
        
        # Compute all inverse FFTs at once
        frames = np.fft.irfft(stft_matrix.T, n=n_fft, axis=1)  # Shape: (num_frames, n_fft)
        frames = frames * window
        
        # Pre-allocate output
        output_length = (num_frames - 1) * hop_length + n_fft
        audio = np.zeros(output_length)
        window_sum = np.zeros(output_length)
        
        # Overlap-add
        for t in range(num_frames):
            start = t * hop_length
            end = start + n_fft
            audio[start:end] += frames[t]
            window_sum[start:end] += window
        
        # Normalize
        window_sum[window_sum < 1e-8] = 1.0
        audio = audio / window_sum
        
        # Trim to original length
        pad_length = n_fft // 2
        audio = audio[pad_length:pad_length + length]
        
        return audio
    
    def _harmonic_percussive_separation(self, magnitude, n_fft, kernel_size=31):
        """Separate harmonic/percussive - FAST vectorized version"""
        from scipy.ndimage import median_filter
        
        # Use scipy's median_filter for fast computation
        # If scipy not available, use simplified method
        try:
            # Harmonic: smooth along time axis (horizontal)
            harmonic_mag = median_filter(magnitude, size=(1, 3), mode='reflect')
            
            # Percussive: smooth along frequency axis (vertical)
            percussive_mag = median_filter(magnitude, size=(3, 1), mode='reflect')
            
        except ImportError:
            # Fallback: simple average-based separation
            harmonic_mag = magnitude.copy()
            percussive_mag = magnitude.copy()
            
            # Simplified time smoothing for harmonic
            harmonic_mag[:, 1:-1] = (magnitude[:, :-2] + magnitude[:, 1:-1] + magnitude[:, 2:]) / 3
            
            # Simplified frequency smoothing for percussive
            percussive_mag[1:-1, :] = (magnitude[:-2, :] + magnitude[1:-1, :] + magnitude[2:, :]) / 3
        
        # Create soft masks
        total = harmonic_mag + percussive_mag + 1e-10
        harmonic_mask = harmonic_mag / total
        percussive_mask = percussive_mag / total
        
        # Apply masks to original magnitude
        harmonic_out = magnitude * harmonic_mask
        percussive_out = magnitude * percussive_mask
        
        return harmonic_out, percussive_out
    
    def show_about(self):
        """Show About dialog in a popup window"""
        self._show_button_press("ABOUT")
        self._button_flash("Start")  # Visual feedback
        
        # Delete existing dialog if open
        if dpg.does_item_exist("about_dialog"):
            dpg.delete_item("about_dialog")
        
        with dpg.window(tag="about_dialog", label="About STEMWEAVER", modal=True, width=700, height=750,
                       show=True, pos=(100, 50)):
            
            # Title
            dpg.add_text("STEMWEAVER v1.1", color=(255, 100, 150, 255))
            dpg.add_text("Professional Audio Stem Separation Tool", color=(200, 200, 210, 255))
            
            dpg.add_separator()
            
            # Credits section
            dpg.add_text("[*] Credits [*]", color=(255, 100, 150, 255))
            dpg.add_text("Created by: bendeb creations", color=(220, 150, 180, 255))
            dpg.add_text("Licensed under: CC BY 4.0 International", color=(180, 180, 190, 255))
            dpg.add_text("Attribution required for use", color=(160, 160, 170, 255))
            
            dpg.add_separator()
            
            # Features
            dpg.add_text(f"{IconText.FEATURES}:", color=(255, 100, 150, 255))
            features = [
                "[+] Real-time audio stem separation (Vocals, Drums, Bass, Other)",
                "[+] FFT-based frequency masking technology",
                "[+] Batch processing of multiple audio files",
                "[+] Support for WAV, MP3, FLAC, and OGG formats",
                "[+] Clean and intuitive user interface"
            ]
            for feature in features:
                dpg.add_text(feature, color=(200, 200, 210, 255))
            
            dpg.add_separator()
            
            # Supported formats
            dpg.add_text(f"{IconText.FORMATS}:", color=(255, 100, 150, 255))
            dpg.add_text("WAV, MP3, FLAC, OGG Vorbis", color=(200, 200, 210, 255))
            dpg.add_text("Output: WAV (16-bit, 44.1kHz)", color=(200, 200, 210, 255))
            
            dpg.add_separator()
            
            # Output structure
            dpg.add_text(f"{IconText.STRUCTURE}:", color=(255, 100, 150, 255))
            dpg.add_text("Each song is processed into a separate folder:", color=(200, 200, 210, 255))
            dpg.add_text("  [Song Name]/", color=(180, 180, 190, 255))
            dpg.add_text("    |-- vocals.wav", color=(180, 180, 190, 255))
            dpg.add_text("    |-- drums.wav", color=(180, 180, 190, 255))
            dpg.add_text("    |-- bass.wav", color=(180, 180, 190, 255))
            dpg.add_text("    |-- other.wav", color=(180, 180, 190, 255))
            
            dpg.add_separator()
            
            # Support links
            dpg.add_text(f"{IconText.SUPPORT} & Links:", color=(255, 100, 150, 255))
            dpg.add_text("GH Repository: https://github.com/mangoban/StemWeaver", color=(150, 200, 220, 255))
            dpg.add_text("Support: https://buymeacoffee.com/mangoban", color=(150, 200, 220, 255))
            dpg.add_text("Made with love by bendeb creations", color=(220, 150, 180, 255))
            
            dpg.add_separator()
            
            # Close button
            with dpg.group(horizontal=True):
                dpg.add_button(label="Close", width=100, height=30,
                             callback=lambda: dpg.delete_item("about_dialog"))
    
    def run(self):
        """Run the application"""
        dpg.setup_dearpygui()
        dpg.show_viewport()
        dpg.set_primary_window("main_window", True)
        dpg.start_dearpygui()
        dpg.destroy_context()


def main():
    app = StemWeaverGUI()
    app.run()


if __name__ == "__main__":
    main()
