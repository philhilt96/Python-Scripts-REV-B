from ctypes import pythonapi
import serial 
import serial.tools.list_ports
from subprocess import call
import os
import time
import tkinter as tk 
from tkinter.constants import DISABLED, E, END, HORIZONTAL, INSERT, NO, NONE, NORMAL, RIGHT
from tkinter import StringVar, filedialog as fd
from tkinter.ttk import Progressbar

# Root Window
root = tk.Tk()
root.geometry("650x400")
root.title("Test Vectors")
root.resizable(False, False)
root.grid_propagate(False)
root.grid_rowconfigure(0, weight=1)
root.grid_columnconfigure(0, weight=1)

####################
# Variables
####################
commString = "quick n dirty test vector version 1 02" # Comparison for connection check
errString = "Error occurred \r\n" # comparison for error check
modified_line_count = 0 # number of lines in modified.txt
err_count = 0 # number of errors 
vector_count = 0 # Vector Count
errors = [] # list for errors
vectors = [] # list to store lines of non whitespace/comments in vector text file
vector_line_count = 0 # number of vector lines in vector file
clicked = 0
progress_text = StringVar()
port_name = "none" 
ports = list(serial.tools.list_ports.comports())
class ser:
    is_open = False
directory = os.getcwd() # Current directory
text_file = "none"

####################
# Functions
####################

# Close window and terminate program
def close():
    if ser.is_open == True:
        ser.close()
    root.destroy()

# Display specified string to info box
def display(name, position, text):
    name["state"] = "normal"
    name.insert(position, text + '\n')
    name["state"] = "disabled"
    info_box.yview_moveto('1')
   
# determine port and check connection
def check_connection():
    display(info_box, INSERT, "INITIALIZE COMMUNICATION TO RS232...")
    root.update_idletasks()
    global port_name
    global ser
    # detect com port in use
    for port in ports:
        if port.description == 'Prolific USB-to-Serial Comm Port (' + port.name + ')' :
            port_name = port.name
    if port_name == 'none' :
        display(info_box, END, "NO CONNECTION DETECTED\nQUIT PROGRAM AND MAKE SURE DEVICE IS PLUGGED INTO COMPUTER\n")
    else :
        # Setup Serial
        ser = serial.Serial(port_name) 
        ser.xonxoff = True
        ser.baudrate = 115200
        ser.set_buffer_size(rx_size = 115200000, tx_size = 115200000) 
        ser.timeout=1
        time.sleep(1)
        ser.write(b'P')
        x = ser.read(38)
        if(str(x,'UTF-8') == commString):
            display(info_box, END, "CONNECTED TO {} SUCCESSFULLY\n".format(port_name))
            # Remove connection button
            connect_btn["state"] = "disabled"
            # Show file button
            file_btn["state"] = "normal"
        else :
            display(info_box, END, "CONNECTION FAILED\nQUIT PROGRAM AND CHECK CONNECTION\n")

# Select txt file and convert to modified.txt
def txt_select():
    global text_file
    #reset progress bar
    # progress_bar['value'] = 0
    # progress_text.set("0/0 Vectors Tested")
    # select file
    text_file = fd.askopenfilename(initialdir="{}/test_vectors".format(directory), title="Select file", filetypes=[("Text Files", "*.txt")])
    print(text_file)
    # make sure file was selected
    if text_file == "" :
        display(info_box, END, "NO FILE SELECTED")
        test_btn["state"] = "disabled"
        return
    else:
        display(info_box, END, "{} SELECTED".format(text_file))
        test_btn["state"] = "normal"
        test_btn["text"] = "Test Vectors"

# Test Vectors
def test_vectors():
    global file
    global modified_line_count
    global vector_count
    global vector_line_count
    global vectors
    global errors
    global err_count
    global clicked
    clicked += 1
     # Run perl script to generate mopdified.txt
    try:
        call(["perl", "convert_tv.pl", text_file])
        display(info_box, END, "{} SUCCESSFULLY CONVERTED TO MODIFIED.TXT".format(text_file))            
    except:
        display(info_box, END, "{} WAS NOT CONVERTED, MAKE SURE PERL IS INSTALLED".format(text_file))  
    # Disable buttons while testing
    file_btn["state"] = "disabled"
    quit_btn["state"] = "disabled"
    test_btn["state"] = "disabled"
    # Open file for reading
    file = open("modified.txt","r")
    for line in file:
	    modified_line_count += 1
    # Calculate number of test vectors
    vector_count = int(modified_line_count / 4)
    display(info_box, END, "\n{} Vectors".format(vector_count))
    file.close()
    root.update_idletasks()
    # store line numbers from test vector file
    with open(text_file, "r") as file :
    	for line in file :
    		if line[0] == '0' :
    			vector_line_count += 1
    			vectors.append(vector_line_count)
    		else :
    			vectors.append(0)
    # open file to show bytes
    file = open("modified.txt","r")
    entire_file = bytes(file.read(),'utf-8')
    display(info_box, END, "WRITING DATA...")
    root.update_idletasks()
    bytes_written = ser.write(entire_file)
    display(info_box, END, "SUCCESS W/ {} BYTES".format(bytes_written))
    root.update_idletasks()
    display(info_box, END, "READING DATA...")
    file.close()
    root.update_idletasks()
    # add errors
    if clicked <= 1:
        for i in range(modified_line_count+1):
            if str(ser.readline(17),'utf-8') == errString:
	            err_count += 1
	            errors.append(i)
    elif clicked > 1:
        for i in range(modified_line_count+1):
            if str(ser.readline(17),'utf-8') == errString:
	            err_count += 1
	            errors.append(i+1)
    # assigns corresponding errors to line numbers in vector text file
    for i in range(len(errors)) :
    	for j in range(len(vectors)) :
    		if errors[i] / 4 == vectors[j] :
    			errors[i] = j + 1
    # show errors
    if err_count > 0 :
    	display(info_box, END,"-----------------")
    	display(info_box, END,"ERROR COUNT = {}".format(err_count))
    	display(info_box, END, "-----------------")
    	for error in range(len(errors)) :
    		display(info_box, END, "ERROR ON LINE {}".format(errors[error]))
    else :
        display(info_box, END,"-----------------")
        display(info_box, END, "NO ERRORS")
        display(info_box, END, "-----------------")
    # Retest option with same txt file
    test_btn["state"] = "normal"
    test_btn["text"] = "Test"
    # Reset variables
    modified_line_count = 0
    err_count = 0 
    vector_count = 0 
    errors = [] 
    vectors = [] 
    vector_line_count = 0 
    clear_btn["state"] = "normal"
    file_btn["state"] = "normal"
    quit_btn["state"] = "normal"

# Clear test vectors from window
def clear_test():
    info_box["state"] = "normal"
    info_box.delete(3.0, tk.END)
    display(info_box, END, "\n")
    info_box["state"] = "disabled"

####################
# User Interface
####################

# Display Information
info_box = tk.Text(root, state=DISABLED)
info_box.grid(row=0, column=0, sticky="nsew", padx=10, pady=5)

# Scrollbar
scroll = tk.Scrollbar(info_box, command=info_box.yview)
scroll.pack(fill=tk.Y, side=tk.RIGHT)
info_box["yscrollcommand"] = scroll.set

# Progress container
progress = tk.Frame(root)
progress.grid(row=1, column=0,sticky="nsew", padx=10, pady=5)

# Progressbar
progress_bar = Progressbar(progress, orient=HORIZONTAL, mode='determinate')
progress_bar.pack(side=tk.LEFT)

# Progressbar label
progress_label = tk.Label(progress, textvariable=progress_text)
progress_label.pack(side=tk.LEFT, padx=15)

# Button parent container
btns = tk.Frame(root)
btns.grid(row=2, column=0, sticky="nsew", padx=5)

# Test Button
test_btn = tk.Button(btns, text="Test Vectors", bg="SpringGreen4", fg="white", state=DISABLED, command=test_vectors)
test_btn.pack(padx=5, pady=5, side=tk.LEFT)

# Select File Button
file_btn = tk.Button(btns, text="Select File", bg="light steel blue", state=DISABLED, command=txt_select)
file_btn.pack(pady=5, side=tk.LEFT)

# Clear test info from window
clear_btn = tk.Button(btns, text="Clear Window", bg="light steel blue", state=DISABLED, command=clear_test)
clear_btn.pack(padx=5, pady=5, side=tk.LEFT)

# Quit Program
quit_btn = tk.Button(btns, text="Quit", bg="red3", fg="white", command=close)
quit_btn.pack(padx=5, pady=5, side=tk.RIGHT)

# Check Connection
connect_btn = tk.Button(btns, text="Check Connection",bg="light steel blue", command=check_connection)
connect_btn.pack(padx=5, pady=5, side=tk.RIGHT)

def run():  
    root.mainloop()