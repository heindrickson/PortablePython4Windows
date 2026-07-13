

import sys
import os


def _check_base_python(env_root_path):
    cfg_exists = False
    cfg_file = env_root_path + '\\' + 'pyVEnv.cfg'
    if os.path.exists(cfg_file):  
        cfg_exists = True
        home_key_found=False
        base_python_exists=False
        # By default, python's 'open()' function uses the NATIVE OS codepage, usually "cp-1252" on Windows...
        # but we know the CFG is generated in UTF-8, so we must TELL python to "treat" it as UTF-8! 
        with open(cfg_file, 'r', encoding='utf-8-sig') as f:  
            for line in f:
                line = line.lower().strip()
                if line.startswith('home =') or line.startswith('home='):
                    home_key_found = True
                    base_python_path = line.split('=')[1].strip()
                    if os.path.exists(base_python_path):
                       base_python_exists = True
    return (cfg_exists, home_key_found, base_python_path, base_python_exists)


# Get the virtual environment root folder:
env_root_path = sys.prefix
cfg_exists, home_key_found, base_python_path, base_python_exists = _check_base_python(env_root_path)
if not base_python_exists:

    def ensure_console_supports_ANSI_RGB():
        import ctypes
        from ctypes import wintypes

        kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)

        STD_OUTPUT_HANDLE = -11
        
        # Virtual terminal sequences are ANSI control character sequences that can control cursor 
        # movement, console color, and other operations when written to the output stream
        ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004

        GetStdHandle = kernel32.GetStdHandle
        GetStdHandle.argtypes = [wintypes.DWORD]
        GetStdHandle.restype = wintypes.HANDLE

        GetConsoleMode = kernel32.GetConsoleMode
        GetConsoleMode.argtypes = [
            wintypes.HANDLE,
            ctypes.POINTER(wintypes.DWORD),
        ]
        GetConsoleMode.restype = wintypes.BOOL

        SetConsoleMode = kernel32.SetConsoleMode
        SetConsoleMode.argtypes = [
            wintypes.HANDLE,
            wintypes.DWORD,
        ]
        SetConsoleMode.restype = wintypes.BOOL

        def console_supports_vt():

            h = GetStdHandle(STD_OUTPUT_HANDLE)

            if h == wintypes.HANDLE(-1).value:
                print(ctypes.WinError(ctypes.get_last_error()))
                return False, None            

            mode = wintypes.DWORD()

            if not GetConsoleMode(h, ctypes.byref(mode)):
                # Not a console (stdout redirected to a file/pipe?)
                return False, None

            return bool(mode.value & ENABLE_VIRTUAL_TERMINAL_PROCESSING), mode.value
        #End-of console_supports_vt()

        supported, mode = console_supports_vt()
        
        # NOW ensure the ENABLE_VIRTUAL_TERMINAL_PROCESSING flag is SET
        h = GetStdHandle(STD_OUTPUT_HANDLE)
        mode = wintypes.DWORD()
        if GetConsoleMode(h, ctypes.byref(mode)):
            new_mode = mode.value | ENABLE_VIRTUAL_TERMINAL_PROCESSING
            if not SetConsoleMode(h, new_mode):
                print(ctypes.WinError(ctypes.get_last_error()))
                
        supported, mode = console_supports_vt()
    #End-of-function
    
    # Some ANSI colors (RGB)
    # See more at:   https://en.wikipedia.org/wiki/ANSI_escape_code
    #         AND:   https://rgbcolorpicker.com/
    #         and:   https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797  <<-- has codes for bold, blink, italic etc.
    #  \x1b[38;2;r;g;bm  <<--- foreground template
    #  \x1b[48;2;r;g;bm  <<--- background template
    #--------  FOREGROUND
    FG_WHITE =  "\x1b[38;2;255;255;255m"  
    FG_BLACK =  "\x1b[38;2;0;0;0m"  
    FG_RED   =  "\x1b[38;2;255;0;0m"  
    FG_GREEN =  "\x1b[38;2;0;255;0m"  
    FG_BLUE  =  "\x1b[38;2;0;0;255m"  
    FG_YELLOW=  "\x1b[38;2;255;255;0m"
    FG_PURPLE=  "\x1b[38;2;255;0;255m"
    FG_CYAN  =  "\x1b[38;2;0;255;255m"
    FG_ORANGE =  "\x1b[38;2;255;180;0m"
    FG_DGRAY =  "\x1b[38;2;80;80;80m"
    FG_LGRAY =  "\x1b[38;2;128;128;128m"
    #--------  BACKGROUND
    BG_WHITE =  "\x1b[48;2;255;255;255m"  
    BG_BLACK =  "\x1b[48;2;0;0;0m"  
    BG_RED   =  "\x1b[48;2;255;0;0m"  
    BG_GREEN =  "\x1b[48;2;0;255;0m"  
    BG_DGREEN = "\x1b[48;2;0;105;0m"
    BG_BLUE  =  "\x1b[48;2;0;0;255m"  
    BG_YELLOW=  "\x1b[48;2;255;255;0m"
    BG_PURPLE=  "\x1b[48;2;255;0;255m"
    BG_DPURPLE = "\x1b[48;2;105;0;105m"
    BG_WASHED_PURPLE=  "\x1b[48;2;240;185;250m"
    BG_CYAN  =  "\x1b[48;2;0;255;255m"
    BG_ORANGE =  "\x1b[48;2;255;180;0m"
    BG_WASHED_ORANGE =  "\x1b[48;2;224;211;162m"
    BG_DGRAY =  "\x1b[48;2;80;80;80m"
    BG_LGRAY =  "\x1b[48;2;128;128;128m"
    BG_CARMIN = "\x1b[48;2;72;0;0m"

    #--------- RESET -----
    RST_CLR =  "\x1b[0m"   #<<---- this DOES NOT reset bold, italic, blink, but there are other reset codes, see 3rd link above
        
    ensure_console_supports_ANSI_RGB()

    if not cfg_exists:
        print(FG_RED + BG_BLACK  + 
f'''CAUTION - The 'pyenv.cfg' file for this virtual environment was not found in:
          {env_root_path} 
        ''' +  RST_CLR)
    elif not base_python_exists:
        print(FG_RED + BG_BLACK  + 
f'''CAUTION - The 'base' folder of the Python version associated with this virtual environment was not found at:
          {base_python_path} ''' +  RST_CLR)
        
    print(FG_YELLOW + BG_BLACK  + "The use of this virtual environment is NOT advisable!")
    print(FG_YELLOW + BG_BLACK  + "Please add the required 'base' Python version by running the script 'ADD_Portable_Python_version.cmd'" + RST_CLR)
    
#End-if
