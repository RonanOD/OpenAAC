# OpenAAC DB CLI

OpenAAC uses a hosted vector database (pinecone or supabase) to store and retrieve the vector embeddings of AAC symbols.

If the database is hosted on Pinecone, it is accessible via the [pinecone](https://pub.dev/packages/pinecone) package.

If on supabase, the [supabase](https://pub.dev/packages/supabase_flutter) package is used.

The [OpenAI Embeddings API](https://platform.openai.com/docs/guides/embeddings) generates the vectors.

The `cli.dart` program is used to upload the images to the database and to test lookup. 

The `update_all_dirs.sh` script can be used to update all the directories in a directory full of sub-directories of AAC icons. It will call the `cli.dart` program for each sub-directory.
