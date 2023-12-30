# OpenAAC DB

OpenAAC uses a hosted pinecone vector database to store and retrieve the vector embeddings of the symbols.
The database is hosted on Pinecone and is accessible via the [pinecone](https://pub.dev/packages/pinecone) package.

## Setup
You will need AAC symbols in the form of images to upload to the database. Each tile needs to be titled with the word 
it depicts followed by the image extension. I.e. `eye.png` where it is an eye icon. 

If you have a set of images arranged in grids, you can use the [imageMagick](https://imagemagick.org/index.php) `convert` and `mogrify` commands to split the images into tiles. 

If you need to remove the top 308 pixels from the image, you can use the following command on all the screenshots in the current directory:

```bash
mogrify *.png -crop 2160x1312+0+308
```

For example, with an image that is 2160 × 1312 pixels and is a grid of
15 x 8 tiles, you can use the following shell script to split all the images into tiles,
each in their own subdirectory:

```bash
#!/bin/bash

for file in *.png
do
  # Remove the file extension
  base_name=$(basename "$file" .png)

  # Create a subdirectory and copy the file into it
  mkdir "$base_name"
  cp "$file" "$base_name"

  # Change into the subdirectory and run the ImageMagick command
  cd "$base_name"
  convert "$file" -crop 15x8@ +repage output%02d.png

  # Change back to the parent directory
  cd ..
done
```

In each image's subdirectory, this will create 150 tiles named `output00.png` to `output149.png`. You can then rename them to the correct name.

The files must be named in the format `word.png` where `word` is the word the tile depicts. Make sure they are all contained in a single folder, for example `\images`.

## Upload
To upload the images to the database, you can use the `cli.dart` script. You will need to have an account with
Pinecone and OpenAI. Run the following command to upload the images:

```bash
dart bin/cli.dart --path=images
```

## Test
To test the embeddings, you can use the `test.dart` script as follows:

```bash
dart bin/test.dart -t
```

This will split your query into words and search for the embeddings of each word. It will then return the top result for each word.

### TODO
 - Use an LLM to searc for the embeddings as described in [this article](https://docs.pinecone.io/docs/langchain#creating-a-vector-store-and-querying) 