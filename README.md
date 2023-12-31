# Open Augmentative and Alternative Communication App

![OpenAAC App](docs/lets_speak.png?raw=true)

AI can be used to help people communicate!

This project uses [OpenAI Vector embeddings](https://platform.openai.com/docs/guides/embeddings) to translate a user's text/speech into easy to understand [AAC](https://www.asha.org/public/speech/disorders/aac/) symbols. 

This will assist communication between neurotypical and nonneurotypical users via mobile devices.

The OpenAAC app will use OpenAI generated embeddings to match symbols to text to convert natural language to AAC pictograms.

# Background
My name is [Ronan O'Driscoll](https://ronanodriscoll.com/). I am a software developer with an autistic son. Through therapy and assisted communication tools, his ability to communicate has improved considerably from when he was largely non-verbal. However, it is often a struggle to pass back and forth his iPad to communicate via his AAC app. So I thought I would create a universal mobile app for me to also input his symbols. We use the Speak4Yourself, but it is only available on iOS. I wanted to create a free, open source alternative that could be used on any mobile device.

The OpenAAC App can work with any AAC symbol set, but you need to generate and upload them manually. The `db/` folder in this repo has a number of tools to prepare and upload and convert your images as vector embeddings to the Pinecone online vector database.

The `app/open_aac` folder contains the Flutter app that will use the Pinecone database to match text to symbols.

AI is a powerful tool. I hope this project can help people communicate better.

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
  2. Create a Pinecone account: https://www.pinecone.io/. You can use the free tier for this project.
  3. Create an OpenAI API account: https://platform.openai.com/. We will use the "text-embedding-ada-002" model which is priced very cheaply ($0.0001/1K tokens as of January 2024). See [this page](https://openai.com/pricing#language-models) for more details.
  4. Clone this repo
  5. Follow instructions in the `db/` folder to create a Pinecone database and upload your AAC symbols.
  6. Copy the generated icons to the `app/open_aac/assets/images` folder.
  7. Use `flutter` in the `app/open_aac` folder to run the app locally.
  8. Install on your android device by connecting it to the computer using `flutter install`. See [this page](https://docs.flutter.dev/deployment/android#install-an-apk-on-a-device) for more details.

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
 * Use a Large Language Model (LLM) to generate symbols when there are low confidence matches in the vector DB.
 * Better integration with other AAC symbol sets
 * Allow users to upload their own custom symbols
 * Offline mode, so that the app can be used without an internet connection and/or Pinecone database. Requires local vector database.
 * Text to speech option: A button to read out the text using the device's text to speech engine. This would also highlight the symbols as they are spoken.
 * Make freely available on the Google Play Store and Apple App Store