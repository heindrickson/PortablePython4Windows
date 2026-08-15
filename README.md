# [PortablePython4Windows](https://github.com/heindrickson/PortablePython4Windows)
A bunch of scripts to help create a portable installation of Python and create and use virtual environments in it (everything PORTABLE) 
<br><br>

# Why?
Because other portable solutions are less flexible, especially for developers who need to work with multiple Python versions, use virtual environments, and want to easily move everything from one computer to another. 
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

**Step 4** : Now you can run the 'ACTIVATE_CONSOLE-for-env.cmd' script to activate any virtual environment, open its console and do what you like (install packages, code/test/run python programs etc)

**Step 5** : Repeat steps 2 to 4 to install other Python versions and create more virtual environments, if you want.

### Optional actions
**Optional 1**: If your 'base' PORTABLE folder is on a pluggable device, then you can plug it into any computer and use it there. If the mapped device (Drive) is different in that computer, then the situation will be the same as in Optional 2.

**Optional 2**: You can move your 'base' PORTABLE folder (or rename it) if you want. After that, the first time you run the 'ACTIVATE_CONSOLE-for-env.cmd' script, you'll be warned to execute the script 'RECONFIGURE-env.cmd', to adjust the virtual environment's 'pyenv.cfg' and some other files. The same thing will happen with the other virtual environments, so it might be easier to adjust ALL of them at once by running the 'Reconfigure-ALL-envs.cmd' script :)

**Optional 3**: After running the 'ACTIVATE_CONSOLE-for-env.cmd' script for the first time, a shortcut named 'PyWinCMD - Activate_CONSOLE-for-env' will be created. You can use this shortcut to launch the [PywinCMD](https://github.com/tagwato/PyWinCMD) tool if the target computer where you intend to use your PORTABLE Python has restrictions on using the native CMD prompt.
<br><br>

# Using a PORTABLE virtual environment within VSCode 
You can activate and use your PORTABLE virtual environments in VSCode.  
To do this, ensure that VS Code is installed on the computer OR install the portable version of VSCode via the script 'Install_Portable_VSCode (optional).cmd' (to learn more about portable VSCode, see: https://code.visualstudio.com/docs/setup/portable).  

Then, complete steps 1 to 4 describe in the section 'How to use' above, that is: download the FULL zip package from this repository, unzip it, add a python version and create at least one virtual environment (e.g., 'myenv').  
You can now drag and drop any folder containing source code onto the 'RUN_VSCODE_with_Portable_Envs.cmd' script.  
VSCode will be launched and the source code folder will become the current working folder.  

To activate your virtual environment in VSCode:  
- press Ctrl+Shift+P
- in the menu that appears, search for  "Python: select interpreter"  and click on that option
- wait a few seconds until a list of virtual environments is displayed  
- locate your PORTABLE virtual environment in that list and select it  
- Confirm that the name of your PORTABLE virtual environment appears at the bottom right of the VS Code window.  
<br><br>

# Distributing an application via PortablePython4Windows
Follow the instructions below:
- Download the "Templates/MyAPP_Template.zip" file from this repository and unzip it.
- Rename the unzipped folder to your app's name — for example, 'MyBeautifulApp'
- INSIDE that folder, follow steps 1 to 4 described in the section 'How to use' above, that is: download the FULL zip package from this repository, unzip it, add a python version and create at least one virtual environment (e.g., 'myenv').
- Activate your portable virtual environment using the 'ACTIVATE_CONSOLE-for-env.cmd' script and use pip to install any libraries required for your application.
- At this point, the 'MyBeautifulApp' folder structure should look something like this:  
```
   C:\
   └───MyBeautifulApp
       ├───RUN_APP.cmd
       ├───APP
       │   └───src
       │       └─── main.py  
       └───PortablePython4Windows-1.0.2
           ├───Envs
           │   └───myenv
           ├───python-3.14.6-embed-amd64
           ├───PyWinCMD-2.0.0
           └───Templates
```
- Now, replace the contents of the 'main.py' file with the actual source code of your application.  
- Add any other files, resources, etc., as needed  
- IF necessary, adjust the 'RUN_APP.cmd' script (usually, you just need to modify the line that executes 'main.py').
- Test the 'RUN_APP.cmd' script. Once everything is working correctly, compress the entire 'MyBeautifulApp' folder into a ZIP file.
- Done! your application is now PORTABLE. One can now simply decompress the ZIP file on another computer and run the 'RUN_APP.cmd' script from the new location.
<br><br>

# License
PortablePython4Windows is licensed for use, modification and distribution under the terms of the MIT License.

Note that PyWinCMD and Python, as well as the Microsoft tools used in this 'solution', have their own licenses.
<br><br>

