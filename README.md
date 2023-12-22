# Open Augmentative and Alternative Communication

This project uses Generative AI to allow better communication with Neuro-atypical users via mobile devices.

The OpenAAC app will use OpenAI generate embeddings to match symbols to text to convert natural language to AAC pictograms.

## AAC Symbol Sets 
 * [Open Symbols library](https://www.opensymbols.org/) 
 * [Speak4Yourself](https://speakforyourself.org/)
   * Free download of the Speak4Yourself AAC symbols here: https://smartysymbols.com/download/free-speak-for-yourself-printable/

## Technology Stack
 * [Flutter](https://flutter.dev/): Cross platform mobile app framework
 * [Pinecone](https://pub.dev/packages/pinecone): Pinecone vector database
 * [Langchain](https://pub.dev/packages/langchain): LangChain provides a set of ready-to-use components for working with language models and the concept of chains, which allows to "chain" components together to formulate more advanced use cases around LLMs.
 * [OpenAI Embeddings](https://platform.openai.com/docs/guides/embeddings): OpenAI’s text embeddings measure the relatedness of text strings
