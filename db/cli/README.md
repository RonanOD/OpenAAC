# OpenAAC DB CLI

OpenAAC uses a hosted pinecone vector database to store and retrieve the vector embeddings of AAC symbols.

The database is hosted on Pinecone and is accessible via the [pinecone](https://pub.dev/packages/pinecone) package.

The `cli.dart` program is used to upload the images to the database. You will need to have an account with Pinecone and OpenAI.

The `update_all_dirs.sh` script can be used to update all the directories in a directory full of sub-directories of AAC icons. It will call the `cli.dart` program for each sub-directory.
