# PortablePython4Windows
A bunch of scripts to help create a portable installation of Python and create and use virtual environments in it (everything PORTABLE) 
<br><br>

# Why?
Because other portable solutions are less flexible, especially for developers who need to work with multiple Python versions, using virtual environments, and want to easily move everything from one computer to another. 
<br><br>

# Features  
- install multiple Python versions in the same portable folder
- create virtual environments bound to any Python version added to the portable folder
- activate any virtual environment and open and use its 'console'
- install/remove pip packages in any virtual environment
- distribute Python programs in a completely open manner
- and, of course, move the entire portable folder to other locations or other computers
<br><br>

# How to use
**Step 1** : Download this repository and extract in any folder (may be a removable USB pendrive). That will be the 'base' PORTABLE folder

**Step 2** : Run the 'ADD_Portable_Python_version.cmd' script, to add a Python version to the PORTABLE folder

**Step 3** : If you skipped the creation of a virtual environment at the final stages of the previous script, then run the 'CREATE_or_REcreate-env.cmd' script to have one created

**Step 4** : Now you can run the 'ACTIVATE_CONSOLE-for-env.cmd' script to activate the environment you wish, open its console and do what you like

**Step 5** : Repeat steps 2 to 4 to install other Python verions and create more virtual environments, if you want

**Step 6** (optional): If your 'base' PORTABLE folder is in a plugged device, you can plug it in any computer and use it there. If the mapped device (Drive) is different there, then the situation will be the same as in Step 7

**Step 7** (optional): You can rename/move your 'base' PORTABLE folder to another 'path' if you wish. The first time you try to activate a virtual environment, you'll be warned to execute the script 'RECONFIGURE-env.cmd', to adjust its 'pyenv.cfg' and some other files.
<br><br>

# License
PortablePython4Windows is licensed for use, modification and distribution under the terms of the MIT License.
Note that PyWinCMD and Python, as well as the Microsoft tools used in this 'solution', have their own licenses.
<br><br>

