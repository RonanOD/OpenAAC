#!/bin/zsh

# Get the root folder from the user
echo "Enter the root folder:"
read root_folder

# Iterate over all directories in the root folder
for dir in "$root_folder"/*/
do
  # Remove trailing slash
  dir=${dir%/}

  echo "Uploading $dir..."

  # Run the Dart script with the directory path as an argument
  dart bin/cli.dart --pinecone_path="$dir"

  # Wait for the user to hit Enter before continuing
  echo "Press Enter to continue..."
  read
done