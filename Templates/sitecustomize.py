# When a 'sitecustomize.py' file is inside the folder FROM WHICH python.exe was executed 
# OR if the file is inside Lib\site-packages of a virtual environment(*), then it will run 
# every time the corresponding python.exe is executed.
#
# Q - What are we doing here?
# A  we are just configuring the use of tkinter (tcl/tk) in the environment (or outside of it), 
#     so that, WHEN the necessary folders are in the 'main' python (base_path)
#     of our PORTABLE installation (in the python-X.YY.Z-embed-amd64 subfolder)
#     then these folders will be placed in the python PATH by the mechanisms used here
#     and tkinter will be 'seen' in the virtual environment as well, and not just 
#     in the 'main' python located in the 'base' folder of the PORTABLE installation.
#   
# (*) for example, under the .\myenv\Lib\site-packages\ environment
#     PS:  'sitecustomize.py' does NOT need to be copied to EACH virtual-environment, it is only 
#           required in each 'python-X.YY.Z-embed-amd64' subfolder at the 'base' of the PORTABLE installation.
#           CAUTION... if a 'sitecustomize.py' is found in the environment Lib\site-packages, it 'shadows' 
#           (overwrites) the file 'sitecustomize.py' placed at the Python folder in the 'base_path'.
#           So, to customize a virtual environment, we use the 'Env-startup.pth' in the env Lib\site-packages      


# CHANGE the below flag if you want to DEBUG this script execution
debugging = False


import os
import sys
import site
from pathlib import Path


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



def debug(s):
    if debugging:
        print(s)


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
    debug(f"VT processing enabled? = {mode!r} ==> {supported}")
    
    # NOW ensure the ENABLE_VIRTUAL_TERMINAL_PROCESSING flag is SET
    h = GetStdHandle(STD_OUTPUT_HANDLE)
    mode = wintypes.DWORD()
    if GetConsoleMode(h, ctypes.byref(mode)):
        new_mode = mode.value | ENABLE_VIRTUAL_TERMINAL_PROCESSING
        if not SetConsoleMode(h, new_mode):
            print(ctypes.WinError(ctypes.get_last_error()))
            
    supported, mode = console_supports_vt()
    debug(f"VT processing enabled? = {mode!r} ==> {supported}")


    
def has_file(path, file):
    file_path = path / file
    if file_path.exists() and file_path.is_file():
        return True
    else:
        return False
    

# --- FUNCTION TO GET THE BASE python.exe PATH (outside of virtual envs) ---
def get_base_path():
    """Reads and returns the base path (home) of the embedded environment in the venv's pyvenv.cfg file."""
    # (It contains the path of the BASE python executable, e.g.: C:\PORTABLEPYTHON4WINDOWS\python-3.13.8-embed-amd64)
    # ----------------------------------------
    # If there is no 'pyenv.cfg', we assume it is the python.exe at the base path of the PORTABLE folder (not a virtual env)
    base_path = Path(sys.prefix)
    cfg_exists = False
    cfg_file = base_path / 'pyvenv.cfg'
    if cfg_file.exists(): 
        cfg_exists = True
        home_found=False
#        with open(cfg_file, 'r') as f:
        # By default, python's 'open()' function uses the NATIVE OS codepage, usually "cp-1252" on Windows...
        # but we know the CFG is generated in UTF-8, so we must TELL python to "treat" it as UTF-8! 
        with open(cfg_file, 'r', encoding='utf-8-sig') as f:  
            for line in f:
                if line.startswith('home ='):
                    base_path = Path(line.split('=')[1].strip())
                    if not os.path.exists(base_path):
                        raise FileExistsError(FG_RED + BG_BLACK + "ERROR - The directory set in the 'home' entry of the activated virtual pyenv.cfg file does NOT exist." + RST_CLR)
                    home_found = True
            if not home_found:            
                raise FileExistsError("ERROR - The pyenv.cfg file of the activated virtual environment does not have the 'home' entry.")
    if cfg_exists:
        bg_color = BG_LGRAY
    else: 
        bg_color = BG_YELLOW
    debug(FG_BLACK + bg_color  + " This 'sitecustomize.py' is running from: " + str(base_path) + RST_CLR)
    return (base_path, cfg_exists)
# ----------------------------------------


debug ("Executing 'sitecustomize.py'...")

# If 'Windows Terminal' is NOT set as the default terminal application, then the common  
# CMD console is used, which does NOT support ANSI-RGB by default. Let's enable it. 
ensure_console_supports_ANSI_RGB()

base_path, cfg_exists = get_base_path()
exe_path = os.path.dirname(sys.executable)


if  cfg_exists:
    print(FG_WHITE + BG_DGREEN  + "*** PORTABLE Python *** at virtual environm.: " + exe_path + RST_CLR)
else:
    print(FG_WHITE + BG_DPURPLE + "*** PORTABLE Python *** at the 'base' folder: " + exe_path + RST_CLR)


# Presents 'locale' and 'console codepage'; it is important for the user to know what is active upon startup.
try:
    import ctypes
    current_codepage = ctypes.windll.kernel32.GetConsoleCP()
except Exception as e:
    print(e)
    current_codepage = "1252" #<-- this is 'ANSI'; it's better than the default '850', for Portuguese/Spanish... see XCOPY output

#***** IMPORTANT EXPLANATION *****
# It is very RELEVANT to know that the locale DOES NOT influence the console codepage nor vice-versa !!!
# That is, when python calls a CMD and something is printed on the console, it is using the 'codepage', which can be different from the 'locale' !
# Q - And which of these pieces of information is used for Python file I/O?  
# A - it's the 'locale', which is cp-1252/ANSI, by default on Windows.
# In short, the codepage set in the CMD console that started Python does NOT affect the open(), read() and write() done in python.
# Q - So, when doing file I/O in Python, is there no need to specify 'encoding'? 
# A - You might need to, because cp-1252 is 'ANSI', this is NOT UTF-8... WHEREAS python literals generated in VScode/Notepad++ are UTF-8.
from locale import getlocale
debug(f"Op. System 'locale' at startup: {FG_YELLOW}{getlocale()}{RST_CLR} <<== This defines the DEFAULT encoding of I/O done IN python!")
debug(f"Op. System console 'codepage' at startup: {FG_YELLOW}{current_codepage}{RST_CLR} <<== This defines the encoding of I/O done ONLY ON the Console")

debug("base_path: " + str(base_path))

if base_path:

    portable_folder = str(base_path.parent)
    debug("portable_folder: " + portable_folder)


    # 1. Identify the host computer's User Site-Packages directory
    host_user_site = site.getusersitepackages()
    debug("Host_user_site (will be disabled while running the PORTABLE site): " + host_user_site)

    # 2. Remove it from sys.path if the bug caused it to leak in
    if host_user_site in sys.path:
        debug("    Removed from sys.path")
        sys.path.remove(host_user_site)
    else:
        debug("    Not in sys.path")

    # 3. Disable the feature so it cannot be called later
    site.ENABLE_USER_SITE = False

    '''
    print('----------------')
    for i, p in enumerate(sys.path):
        print(i, p.encode("unicode_escape"))
    print('----------------')
    '''

    # THIS is the Nuclear Option for 100% Strict Isolation ---
    # We want to guarantee absolutely that NO host paths (like Windows Registry injections) are hiding in sys.path,
    # so we scrub sys.path to only allow paths that physically reside inside our PORTABLE installation.
    clean_path = []
    for p in sys.path:
        # Keep the path if it belongs to the portable folder
        if p.startswith(portable_folder)  or p == '.' or p == '.\\':
            debug("Keeping: " + p)
            clean_path.append(p)
        else:
            debug("EXCLUDED: " + p)
    sys.path = clean_path


    # The steps above suffice for the python.exe at the BASE portable folder (outside of virtual envs). 
    # BUT NOT for the python.exe called when a virtual-environment IS activated !
    # In that case, the following steps are ALSO necessary:

    if cfg_exists:  # Indicates that the executing python is in a virtual environment

        # 4. Add the 'main' python (BASE python) folders to sys.path, as they are necessary for tkinter.
        # The below guarantees that the Python "tkinter" module (Lib/tkinter/__init__.py) is found.
        base_lib_path = base_path / 'Lib'
        if base_lib_path.is_dir():
            debug("base_lib_path: " + str(base_lib_path))
            sys.path.insert(0,str(base_lib_path))
        # The below guarantees that the DLLs/_tkinter.pyd file is found.
        base_dlls_path = base_path / 'DLLs'  
        if base_dlls_path.is_dir():
            debug("base_dlls_path: " + str(base_dlls_path))
            sys.path.insert(0,str(base_dlls_path))   
        # The below guarantees that the tcl/tk*.lib and tcl*.lib files are found.
        base_tcl_path = base_path / 'tcl'  
        if base_tcl_path.is_dir():
            debug("base_tcl_path: " + str(base_tcl_path))
            sys.path.insert(0,str(base_tcl_path))           
        
        # 5. Configure Tcl/Tk environment variables
        tcl_path = base_path / 'tcl'
        if not tcl_path.is_dir():  # if it doesn't find tcl in Base, tries in Base/Lib
            tcl_path = base_path / 'Lib' / 'tcl'
        debug("tcl_path: " + str(tcl_path))        
        if tcl_path.is_dir():
            tcl_subfolder = next((f for f in tcl_path.iterdir() if f.name.startswith('tcl') 
                                and "." in f.name and f.is_dir() and has_file(f, "init.tcl")), None)
            tk_subfolder = next((f for f in tcl_path.iterdir() if f.name.startswith('tk') 
                                and "." in f.name and f.is_dir() and has_file(f, "tk.tcl")), None)
            debug("tcl_subfolder: " + str(tcl_subfolder))        
            debug("tk_subfolder: " + str(tk_subfolder))        
            
            if tcl_subfolder and tcl_subfolder.is_dir():
                os.environ['TCL_LIBRARY'] = str(tcl_subfolder)
                debug('TCL_LIBRARY set to ' + str(tcl_subfolder))
            else:
                debug('Could NOT set TCL_LIBRARY :(')         
                                            
            if tk_subfolder and tk_subfolder.is_dir():
                os.environ['TK_LIBRARY'] = str(tk_subfolder)
                debug('TK_LIBRARY set to ' + str(tk_subfolder))
            else:
                debug('Could NOT set TK_LIBRARY :(')         
            
debug("End of sitecustomize.py")