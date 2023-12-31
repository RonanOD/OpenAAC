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

 ## Installation
  1. Install Flutter: https://flutter.dev/docs/get-started/install
  2. Create a Pinecone account: https://www.pinecone.io/
  3. Create an OpenAI API account: https://platform.openai.com/
  4. Clone this repo
  5. Follow instructions in the `db/` folder to create a Pinecone database and upload your AAC symbols.
  6. Use `flutter` in the `app/open_aac` folder to run the app locally.
  7. Install on your android device by connecting it to the computer using `flutter install`. See [this page](https://docs.flutter.dev/deployment/android#install-an-apk-on-a-device) for more details.

## Usage
  1. Open the app
  2. Click on the settings icon in the top right corner.
  3. Enter your OpenAI and Pinecone API keys, along with Pinecone Project ID and Environment.
  4. Hit Save
  5. Return to the main screen
  6. Enter a sentence in the text box
  7. Press the search button
  8. The app will return a list of symbols matching the text
  9. The Clear button next to the text box will clear the text and symbols

## Future Goals
 * Better integration with a number of AAC symbol sets
 * Allow users to upload their own symbol sets
 * Offline mode, so that the app can be used without an internet connection and/or Pinecone database.
 * Text to speech option: A button to read out the text using the device's text to speech engine. This would also highlight the symbols as they are spoken.
 * Make freely available on the Google Play Store and Apple App Store