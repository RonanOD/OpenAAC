"""
Using Mac OS shortcuts to generate OCR output (see shortcuts.png), gather the images
in a directory to match the text of the OCR output.

This python script takes a file directory as input. It will split the contents of the text file 
by the | character. The generated array should match text to file name. 
By add ".png" to the name, it will rename the image file in the same directory to
the text value, replacing spaces with underscores.
"""

import os
import glob

# Get the subdirectory name from the user
subdirectory = input("Enter the subdirectory name: ")

# Get all txt files in the subdirectory
txt_files = glob.glob(os.path.join(subdirectory, "*.txt"))

for txt_file in txt_files:
    with open(txt_file, 'r') as f:
        content = f.read()
        content = content.replace("\r","") # strip out carriage returns
        content = content.replace("\n","") # strip out carriage returns
        tokens = content.split('|')
        words = tokens[:len(tokens)//2]
        names = tokens[len(tokens)//2:]
        
        for i in range(len(words)):
            image_name = names[i] + ".png"
            new_name = words[i].strip().replace(" ", "_") + ".png"
            os.rename(os.path.join(subdirectory, image_name), os.path.join(subdirectory, new_name))
            print("Renamed " + image_name + " to " + new_name)