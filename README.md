# Open Augmentative and Alternative Communication

This project uses OpenAI Vector embeddings to translate a user's text/speech into easy to understand AAC symbols. This will assist communication between neurotypical and nonneurotypical users via mobile devices.

The OpenAAC app will use OpenAI generate embeddings to match symbols to text to convert natural language to AAC pictograms.

# Reason
My name is [Ronan O'Driscoll](https://ronanodriscoll.com/). I am a software developer with a mostly nonverbal autistic son. It is often a struggle to pass back and forth his iPad to communicate, so I thought I would create a universal mobile for me to also input his symbols. We use the Speak4Yourself app, but it is only available on iOS. I wanted to create a free, open source alternative that could be used on any mobile device.

OpenAAC can work with any AAC symbol set, the `db/` folder in this repo has a number of tools to prepare and upload these images as vector embeddings to the Pinecone online vector database.

The `app/open_aac` folder contains the Flutter app that will use the Pinecone database to match text to symbols.

## AAC Symbol Sets 
 * [Open Symbols library](https://www.opensymbols.org/) 
 * [Speak4Yourself](https://speakforyourself.org/)
   * Free download of the Speak4Yourself AAC symbols here: https://smartysymbols.com/download/free-speak-for-yourself-printable/

## Technology Stack
 * [Flutter](https://flutter.dev/): Cross platform mobile app framework
 * [Pinecone](https://pub.dev/packages/pinecone): Pinecone vector database
 * [Langchain](https://pub.dev/packages/langchain): LangChain provides a set of ready-to-use components for working with language models and the concept of chains, which allows to "chain" components together to formulate more advanced use cases around LLMs.
 * [OpenAI Embeddings](https://platform.openai.com/docs/guides/embeddings): OpenAI’s text embeddings measure the relatedness of text strings
