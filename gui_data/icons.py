#!/usr/bin/env python3
"""
StemWeaver Icons - Simple text-based icon set
Reliable icons for the UI - no emoji dependencies
"""

class Icons:
    """Simple text icons for UI elements"""
    
    # Navigation & Actions
    PLAY = ">"
    PAUSE = "||"
    STOP = "[]"
    FOLDER = "[F]"
    FOLDER_OPEN = "[O]"
    FILE = "[FILE]"
    FILE_AUDIO = "[AUDIO]"
    REFRESH = "[R]"
    SETTINGS = "[S]"
    INFO = "[i]"
    CLOSE = "[X]"
    
    # Status indicators
    SUCCESS = "[OK]"
    ERROR = "[ERROR]"
    WARNING = "[WARN]"
    PROCESSING = "[...]"
    DONE = "[DONE]"
    CHECKMARK = "[✓]"
    
    # Audio/Music
    MUSIC = "[♪]"
    MUSIC_NOTE = "♪"
    VOCALS = "[VOC]"
    DRUMS = "[DRUMS]"
    BASS = "[BASS]"
    GUITAR = "[GUITAR]"
    PIANO = "[PIANO]"
    HEADPHONES = "[♪]"
    SPEAKER = "[♪]"
    WAVEFORM = "[WAVE]"
    
    # UI Elements
    MENU = "[≡]"
    SEARCH = "[?]"
    DOWNLOAD = "[↓]"
    UPLOAD = "[↑]"
    EXPORT = "[→]"
    IMPORT = "[←]"
    ANALYZE = "[ANALYZE]"
    
    # Social
    GITHUB = "💻"
    PAYPAL = "💳"
    HEART = "❤️"
    STAR = "⭐"
    
    # Misc
    ARROW_RIGHT = "▶"
    ARROW_LEFT = "◀"
    ARROW_UP = "▲"
    ARROW_DOWN = "▼"
    BULLET = "•"
    SEPARATOR = "│"
    LIGHTNING = "⚡"
    FIRE = "🔥"
    ROCKET = "🚀"
    GEAR = "⚙️"
    TOOLS = "🛠️"
    MAGIC = "✨"
    
    @staticmethod
    def get_icon(name: str, default="❓") -> str:
        """Get icon by attribute name"""
        return getattr(Icons, name.upper(), default)


class IconButtons:
    """Icon-labeled buttons for common actions"""
    
    # Button labels with icons
    PLAY = "> Play"
    PAUSE = "|| Pause"
    STOP = "[] Stop"
    BROWSE = "[O] Browse Files"
    CLEAR = "[X] Clear"
    PROCESS = "[>] Process"
    SETTINGS = "[S] Settings"
    ABOUT = "[i] About"
    EXIT = "[X] Exit"
    CLOSE = "[X] Close"
    OK = "[OK] OK"
    CANCEL = "[X] Cancel"
    ANALYZE = "[?] Analyze"
    APPLY = "[✓] Apply"
    SAVE = "[↓] Save"
    LOAD = "[↑] Load"
    EXPORT = "[→] Export"
    

class IconText:
    """Icon-prefixed text labels"""
    
    SUCCESS_MSG = "[OK] Success"
    ERROR_MSG = "[ERROR] Error"
    WARNING_MSG = "[WARN] Warning"
    INFO_MSG = "[i] Info"
    PROCESSING_MSG = "[...] Processing"
    
    FILE_SELECTION = "[O] File Selection"
    SETTINGS = "[S] Settings"
    OUTPUT = "[→] Output"
    FEATURES = "[*] Features"
    FORMATS = "[FILE] Formats"
    STRUCTURE = "[≡] Structure"
    SUPPORT = "[♥] Support"
    
    # Audio-specific
    VOCALS = "[VOC] Vocals"
    DRUMS = "[DRUMS] Drums"
    BASS = "[BASS] Bass"
    OTHER = "[OTHER] Other"
    GUITAR = "[GUITAR] Guitar"
    PIANO = "[PIANO] Piano"


def create_icon_button_label(icon: str, text: str, padding: bool = True) -> str:
    """Create a formatted icon button label"""
    if padding:
        return f"  {icon} {text}  "
    return f"{icon} {text}"


def create_icon_text_label(icon: str, text: str) -> str:
    """Create a formatted icon text label"""
    return f"{icon} {text}"
