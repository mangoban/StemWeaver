"""
UI Styling Module for StemWeaver
Provides comprehensive styling for all UI components
"""

import tkinter as tk
from tkinter import ttk
import sv_ttk

class UIStyler:
    """Centralized UI styling class"""
    
    def __init__(self, root):
        self.root = root
        self.style = ttk.Style()
        
        # Configure theme
        self._configure_theme()
        
        # Style all components
        self._style_buttons()
        self._style_entries()
        self._style_listboxes()
        self._style_comboboxes()
        self._style_checkbuttons()
        self._style_radiobuttons()
        self._style_labels()
        self._style_frames()
        self._style_notebooks()
        self._style_progressbars()
        self._style_scrollbars()
        self._style_treeviews()
        
    def _configure_theme(self):
        """Configure the base theme"""
        # Set dark theme
        sv_ttk.set_theme("dark")
        
        # Set global color palette
        self.root.tk_setPalette(
            background=BG_COLOR,
            foreground=FG_COLOR,
            highlightColor=ACCENT_COLOR,
            selectBackground=LISTBOX_SELECT_BG,
            selectForeground=LISTBOX_SELECT_FG,
            activeBackground=BUTTON_HOVER_BG,
            activeForeground=FG_COLOR
        )
        
    def _style_buttons(self):
        """Style all button components"""
        self.style.configure('TButton',
            background=BUTTON_BG,
            foreground=BUTTON_FG,
            borderwidth=BUTTON_BORDER_WIDTH,
            relief=BUTTON_RELIEF,
            focuscolor='none',
            padding=(8, 4),
            font=(MAIN_FONT_NAME, 10)
        )
        
        self.style.map('TButton',
            background=[('active', BUTTON_HOVER_BG),
                       ('pressed', BUTTON_ACTIVE_BG)],
            foreground=[('active', BUTTON_FG),
                       ('pressed', BUTTON_FG)]
        )
        
        # Custom button styles
        self.style.configure('Primary.TButton',
            background=ACCENT_COLOR,
            foreground=BUTTON_FG,
            borderwidth=BUTTON_BORDER_WIDTH,
            relief=BUTTON_RELIEF,
            focuscolor='none',
            padding=(12, 6),
            font=(MAIN_FONT_NAME, 10, 'bold')
        )
        
        self.style.map('Primary.TButton',
            background=[('active', '#0090e0'),
                       ('pressed', '#0080d0')],
            foreground=[('active', BUTTON_FG),
                       ('pressed', BUTTON_FG)]
        )
        
        self.style.configure('Secondary.TButton',
            background='#3a5f8f',
            foreground=BUTTON_FG,
            borderwidth=BUTTON_BORDER_WIDTH,
            relief=BUTTON_RELIEF,
            focuscolor='none',
            padding=(8, 4),
            font=(MAIN_FONT_NAME, 10)
        )
        
        self.style.map('Secondary.TButton',
            background=[('active', '#4a7faf'),
                       ('pressed', '#2a4f6f')],
            foreground=[('active', BUTTON_FG),
                       ('pressed', BUTTON_FG)]
        )
        
    def _style_entries(self):
        """Style all entry components"""
        self.style.configure('TEntry',
            background=ENTRY_BG,
            foreground=ENTRY_FG,
            borderwidth=ENTRY_BORDER_WIDTH,
            relief='solid',
            fieldbackground=ENTRY_BG,
            insertcolor=ENTRY_FG,
            font=(MAIN_FONT_NAME, 10)
        )
        
        self.style.map('TEntry',
            background=[('readonly', COMBOBOX_READONLY_BG)],
            foreground=[('readonly', ENTRY_FG)]
        )
        
    def _style_listboxes(self):
        """Style all listbox components"""
        self.style.configure('TListbox',
            background=LISTBOX_BG,
            foreground=LISTBOX_FG,
            borderwidth=LISTBOX_BORDER_WIDTH,
            relief='solid',
            selectbackground=LISTBOX_SELECT_BG,
            selectforeground=LISTBOX_SELECT_FG,
            font=(MAIN_FONT_NAME, 10)
        )
        
    def _style_comboboxes(self):
        """Style all combobox components"""
        self.style.configure('TCombobox',
            background=COMBOBOX_BG,
            foreground=COMBOBOX_FG,
            borderwidth=COMBOBOX_BORDER_WIDTH,
            relief='solid',
            fieldbackground=COMBOBOX_BG,
            arrowcolor=COMBOBOX_ARROW_COLOR,
            font=(MAIN_FONT_NAME, 10)
        )
        
        self.style.map('TCombobox',
            background=[('readonly', COMBOBOX_READONLY_BG)],
            foreground=[('readonly', COMBOBOX_FG)]
        )
        
        # Custom combobox dropdown style
        self.style.configure('ComboboxDropdown.TCombobox',
            background=COMBOBOX_BG,
            foreground=COMBOBOX_FG,
            borderwidth=COMBOBOX_BORDER_WIDTH,
            relief='solid',
            font=(MAIN_FONT_NAME, 10)
        )
        
    def _style_checkbuttons(self):
        """Style all checkbutton components"""
        self.style.configure('TCheckbutton',
            background=CHECKBUTTON_BG,
            foreground=CHECKBUTTON_FG,
            selectcolor=CHECKBUTTON_SELECT_COLOR,
            borderwidth=0,
            focuscolor='none',
            font=(MAIN_FONT_NAME, 10)
        )
        
    def _style_radiobuttons(self):
        """Style all radiobutton components"""
        self.style.configure('TRadiobutton',
            background=RADIOBUTTON_BG,
            foreground=RADIOBUTTON_FG,
            selectcolor=RADIOBUTTON_SELECT_COLOR,
            borderwidth=0,
            focuscolor='none',
            font=(MAIN_FONT_NAME, 10)
        )
        
    def _style_labels(self):
        """Style all label components"""
        self.style.configure('TLabel',
            background=LABEL_BG,
            foreground=LABEL_FG,
            font=(MAIN_FONT_NAME, 10)
        )
        
        # Custom label styles
        self.style.configure('Title.TLabel',
            background=LABEL_BG,
            foreground=LABEL_TITLE_FG,
            font=(MAIN_FONT_NAME, 14, 'bold')
        )
        
        self.style.configure('Subtitle.TLabel',
            background=LABEL_BG,
            foreground=LABEL_SUBTITLE_FG,
            font=(MAIN_FONT_NAME, 12)
        )
        
        self.style.configure('Header.TLabel',
            background=LABEL_BG,
            foreground=LABEL_TITLE_FG,
            font=(MAIN_FONT_NAME, 16, 'bold')
        )
        
    def _style_frames(self):
        """Style all frame components"""
        self.style.configure('TFrame',
            background=FRAME_BG,
            borderwidth=FRAME_BORDER_WIDTH,
            relief='solid'
        )
        
        # Custom frame styles
        self.style.configure('Card.TFrame',
            background=FRAME_BG,
            borderwidth=FRAME_BORDER_WIDTH,
            relief='solid',
            bordercolor=FRAME_BORDER_COLOR
        )
        
        self.style.configure('Panel.TFrame',
            background=FRAME_BG,
            borderwidth=0,
            relief='flat'
        )
        
    def _style_notebooks(self):
        """Style all notebook components"""
        self.style.configure('TNotebook',
            background=NOTEBOOK_BG,
            borderwidth=NOTEBOOK_BORDER_WIDTH,
            relief='solid',
            tabposition='nw'
        )
        
        self.style.configure('TNotebook.Tab',
            background=NOTEBOOK_TAB_BG,
            foreground=NOTEBOOK_TAB_FG,
            borderwidth=1,
            relief='solid',
            focuscolor='none',
            padding=(12, 6),
            font=(MAIN_FONT_NAME, 10)
        )
        
        self.style.map('TNotebook.Tab',
            background=[('selected', NOTEBOOK_TAB_ACTIVE_BG),
                       ('active', NOTEBOOK_TAB_BG)],
            foreground=[('selected', NOTEBOOK_TAB_ACTIVE_FG),
                       ('active', NOTEBOOK_TAB_FG)]
        )
        
    def _style_progressbars(self):
        """Style all progressbar components"""
        self.style.configure('TProgressbar',
            background=PROGRESSBAR_FG,
            troughcolor=PROGRESSBAR_BG,
            borderwidth=0,
            relief='flat',
            font=(MAIN_FONT_NAME, 10)
        )
        
    def _style_scrollbars(self):
        """Style all scrollbar components"""
        self.style.configure('TScrollbar',
            background=SCROLLBAR_BG,
            troughcolor=SCROLLBAR_TROUGH,
            borderwidth=0,
            relief='flat',
            arrowcolor=SCROLLBAR_ARROW
        )
        
        self.style.map('TScrollbar',
            background=[('active', SCROLLBAR_ARROW)]
        )
        
    def _style_treeviews(self):
        """Style all treeview components"""
        self.style.configure('Treeview',
            background=LISTBOX_BG,
            foreground=LISTBOX_FG,
            borderwidth=LISTBOX_BORDER_WIDTH,
            relief='solid',
            rowheight=25,
            font=(MAIN_FONT_NAME, 10)
        )
        
        self.style.configure('Treeview.Heading',
            background=NOTEBOOK_TAB_BG,
            foreground=NOTEBOOK_TAB_FG,
            borderwidth=1,
            relief='solid',
            font=(MAIN_FONT_NAME, 10, 'bold')
        )
        
        self.style.map('Treeview',
            background=[('selected', LISTBOX_SELECT_BG)],
            foreground=[('selected', LISTBOX_SELECT_FG)]
        )
        
    def create_modern_button(self, parent, text, command=None, style='TButton'):
        """Create a modern-styled button"""
        btn = ttk.Button(parent, text=text, command=command, style=style)
        return btn
        
    def create_modern_entry(self, parent, show=None):
        """Create a modern-styled entry"""
        entry = ttk.Entry(parent, style='TEntry', show=show)
        return entry
        
    def create_modern_listbox(self, parent, height=10):
        """Create a modern-styled listbox"""
        listbox = tk.Listbox(parent,
            activestyle='dotbox',
            font=(MAIN_FONT_NAME, 10),
            foreground=LISTBOX_FG,
            background=LISTBOX_BG,
            selectbackground=LISTBOX_SELECT_BG,
            selectforeground=LISTBOX_SELECT_FG,
            exportselection=0,
            height=height
        )
        return listbox
        
    def create_modern_combobox(self, parent, values=None, state='readonly'):
        """Create a modern-styled combobox"""
        combobox = ttk.Combobox(parent,
            values=values,
            state=state,
            style='TCombobox',
            font=(MAIN_FONT_NAME, 10)
        )
        return combobox
        
    def create_modern_checkbutton(self, parent, text, variable=None):
        """Create a modern-styled checkbutton"""
        checkbutton = ttk.Checkbutton(parent,
            text=text,
            variable=variable,
            style='TCheckbutton',
            font=(MAIN_FONT_NAME, 10)
        )
        return checkbutton
        
    def create_modern_label(self, parent, text, style='TLabel'):
        """Create a modern-styled label"""
        label = ttk.Label(parent, text=text, style=style)
        return label
        
    def create_modern_frame(self, parent, style='TFrame'):
        """Create a modern-styled frame"""
        frame = ttk.Frame(parent, style=style)
        return frame

# Import constants
from .constants import *

# Global styler instance
_styler_instance = None

def get_styler():
    """Get the global styler instance"""
    global _styler_instance
    return _styler_instance

def initialize_ui_styling(root):
    """Initialize UI styling globally"""
    global _styler_instance
    _styler_instance = UIStyler(root)
    return _styler_instance