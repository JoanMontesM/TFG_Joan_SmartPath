# SmartPath: Generative AI and Universal Design for Learning to Enhance the Use of Technological Resources in Educational Settings
This bachelor’s thesis presents the development of an educational application that integrates generative artificial intelligence to facilitate the creation of multimodal content tailored to the needs of both teachers and students. The application allows teachers to generate summaries from PDF documents, which are automatically transcribed, interpreted, and transformed into three detailed summaries. These texts can be edited and validated by the teacher, and from them, complementary multimodal content such as images, audio (text-to-speech), and simplified versions of the text are generated to ensure comprehension.

To ensure the solution is truly useful and relevant, an in-depth research study was conducted with teachers and educational professionals. This research process made it possible to identify current needs and challenges related to the use of educational resources, especially regarding the creation of teaching materials that promote autonomous and inclusive learning. Based on this data, technological solutions have been designed to meet the real demands of teachers and students.

This work demonstrates how artificial intelligence can create innovative educational alternatives that respond to a wide range of needs, extending the scope of learning beyond the classroom. The tool is scalable and adaptive, representing an important step toward educational inclusion by promoting the creation of resources that can be used by students with diverse profiles and in various contexts.

## Project Structure:
Overview of the main folders and files in the application.
- `lib/`: All the application source code (UI, logic, service integration).
- `android/`: Project files for running the app on Android emulators or devices.
- `ios/`: Project files for running the app on iOS simulators or devices.

## Features:
Key functionalities that make SmartPath a powerful educational tool.
- **AI-Generated Summaries**: Extracts and simplifies summaries from uploaded PDF files using DeepSeek-R1 API.
- **Image Generation**: Uses the Imagen-3 model via Replicate API to generate high-quality images based on the summary content.
- **Fill-in-the-Gap & Quiz Exercises**: Creates interactive exercises to reinforce understanding.
- **Text-to-Speech (Catalan)**: Integrates a custom TTS model (executed locally via Docker) from Project Aina to vocalize content in Catalan.
- **Firebase Integration**:
  - User authentication
  - Secure media and data storage
  - Tracking user interactions and AI-generated resources

## Technologies Used:
- **Flutter + Dart**: Frontend+Backend development framework for building natively compiled apps.
- **DeepSeek API**: For AI-generated text (summaries, simplified content, prompt generation).
- **Replicate API**: For AI-generated images and (initially) text-to-speech models.
- **Docker + FastAPI**: For local TTS server deployment.
- **Firebase**: User management, Firestore database, and multimedia file storage.

## Development Setup
This app is the result of extensive research involving educators and pedagogical experts. Interviews and testing revealed specific needs regarding content customization, accessibility, and inclusion. These findings guided the design of a solution that is realistic, scalable, and truly useful in diverse educational contexts.
### Prerequisites
- Flutter SDK
- Dart SDK
- Android Studio
- Docker (for local TTS server)
- Firebase account & project
- API keys for DeepSeek and Replicate

## Educational Vision
SmartPath aligns with the principles of Universal Design for Learning (UDL) by providing:
- Multiple means of representation (text, images, audio).
- Adaptive difficulty levels for inclusive learning.
- AI-driven customization of learning content.
The app supports Catalan language learning tools, fostering digital inclusion and cultural identity in educational settings.

## Credits
Developed by Joan Montés Mora as part of a Final Degree Project in Audiovisual Systems Engineering.
