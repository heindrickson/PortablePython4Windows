# [PortablePython4Windows](https://github.com/heindrickson/PortablePython4Windows)
A bunch of scripts to help create a portable installation of Python and create and use virtual environments in it (everything PORTABLE) 
<br><br>

# Why?
Because other portable solutions are less flexible, especially for developers who need to work with multiple Python versions, using virtual environments, and want to easily move everything from one computer to another. 
<br><br>

# Features  
- install multiple Python versions in the same PORTABLE folder
- create virtual environments bound to any Python version added to the PORTABLE folder
- activate any virtual environment and open and use its 'console'
- install/remove pip packages in any virtual environment
- complete isolation between your PORTABLE virtual environments and any Python installation on the local computer. Additionally, you will be notified by a white-on-green message each time you run python.exe after activating a PORTABLE environment, preventing any confusion with the local Python installation
- distribute Python programs in a completely open manner
- and, of course, move the entire portable folder to other locations or to other computers
<br><br>

# How to use
**Step 1** : Download this repository and extract in any folder (may be a removable USB device/pen drive). That will be the 'base' PORTABLE folder

**Step 2** : Run the 'ADD_Portable_Python_version.cmd' script, to add a Python version to the 'base' PORTABLE folder

**Step 3** : If you skipped the creation of a virtual environment at the final stages of the previous script, then run the 'CREATE_or_REcreate-env.cmd' script and create a virtual environment

**Step 4** : Now you can run the 'ACTIVATE_CONSOLE-for-env.cmd' script to activate the environment you wish, open its console and do what you like (install packages, code/test/run python programs etc)

**Step 5** : Repeat steps 2 to 4 to install other Python versions and create more virtual environments, if you want.

### Optional actions
**Optional 1**: If your 'base' PORTABLE folder is on a pluggable device, then you can plug it into any computer and use it there. If the mapped device (Drive) is different in that computer, then the situation will be the same as in Optional 2.

**Optional 2**: You can rename/move your 'base' PORTABLE folder to another 'path' if you wish. After that, the first time you run the 'ACTIVATE_CONSOLE-for-env.cmd' script, you'll be warned to execute the script 'RECONFIGURE-env.cmd', to adjust the virtual environment's 'pyenv.cfg' and some other files. The same thing will happen with the other virtual environments, so it might be easier to adjust ALL of them at once by running the 'Reconfigure-ALL-envs.cmd' script :)

**Optional 3**: You can activate and use your PORTABLE virtual environments in VSCode. Just drag and drop some source code folder onto the 'RUN_VSCODE_with_Envs.cmd' script and follow the instructions on the screen.

**Optional 4**: After running the script for the first time, a shortcut named 'PyWinCMD - Activate_CONSOLE-for-env' will be created. You can use this shortcut to launch the [PywinCMD](https://github.com/tagwato/PyWinCMD) tool if the target computer where you intend to use your PORTABLE Python has restrictions on using the native CMD.
<br><br>

# License
PortablePython4Windows is licensed for use, modification and distribution under the terms of the MIT License.

Note that PyWinCMD and Python, as well as the Microsoft tools used in this 'solution', have their own licenses.
<br><br>

