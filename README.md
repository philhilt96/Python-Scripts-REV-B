# Python-Scripts-REV-B

This folder contains a working version of the Python program to run test vectors on the R232. 
For the program to run successfully git bash should be installed, which can be installed here: https://git-scm.com/downloads
VS Code is recommended if running from terminal. To set bash to default terminal follow directions here:
https://stackoverflow.com/questions/42606837/how-do-i-use-bash-on-windows-from-the-visual-studio-code-integrated-terminal

~~There are two ways~~ to run the program:

- ~~In the dist folder, click on __main__.exe~~

- From a bash terminal make sure the path is inside \<Python Scripts Rev B\> and run 'python \_\_main\_\_.py'

For the most part the gui should guide you through use, but general usage is as follows:
A connection must be made with the 'Check Connection' button before anything can be done. If no connection is made,
or if the connection is interrupted at any time, the program must be restarted to work.
Once a connection is made a file is selected with the 'Select File' button and then vectors can be tested
with the 'Test Vectors' button. The 'Clear Window' button erases text in the window and the 'Quit' button terminates the program.
