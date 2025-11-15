# Real Life Applications App

An AI-powered educational Flutter application that helps students understand real-world applications of academic concepts through interactive chat with AI tutors.

## Features

- **Subject-Based Learning**: Interactive chat interface for various subjects
- **Multiple AI Providers**: Support for OpenRouter, OpenAI, Anthropic, and Google AI Studio
- **Chat History**: Save and manage conversation history
- **Settings Management**: Configure API keys and preferences
- **Cross-Platform**: Runs on Android, iOS, Web, Windows, macOS, and Linux

## Prerequisites

Before running this application, ensure you have the following installed:

### 1. Flutter SDK
- Download from: https://flutter.dev/docs/get-started/install
- Add Flutter to your PATH
- Run `flutter doctor` to verify installation

### 2. Python (3.8+)
- Download from: https://python.org/downloads/
- Ensure pip is installed

### 3. Git (for collaboration)
- Download from: https://git-scm.com/downloads

## Setup Instructions

### Backend Setup (Python Flask API)

1. **Navigate to backend directory:**
   ```bash
   cd real_life_app/backend
   ```

2. **Create virtual environment:**
   ```bash
   python -m venv venv
   ```

3. **Activate virtual environment:**
   - Windows: `venv\Scripts\activate`
   - macOS/Linux: `source venv/bin/activate`

4. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

5. **Configure API Key:**
   Edit `data/api_keys.json` and replace `your_openrouter_api_key_here` with your actual OpenRouter API key:
   ```json
   {
     "127.0.0.1": {
       "OpenRouter": {
         "api_key": "sk-or-v1-xxxxxxxxxxxxx",
         "updated_at": "2025-11-15T13:00:00.000000"
       }
     }
   }
   ```

### Frontend Setup (Flutter App)

1. **Navigate to project root:**
   ```bash
   cd real_life_app
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Check available devices:**
   ```bash
   flutter devices
   ```

## Running the Application

### Option 1: Using the Provided Batch Script

1. **Start backend server:**
   Double-click `start_backend.cmd` (Windows) or run:
   ```bash
   ./start_backend.cmd  # On Unix systems, might need different script
   ```

2. **Start Flutter app:**
   ```bash
   flutter run
   ```

### Option 2: Manual Startup

1. **Terminal 1 - Start Backend:**
   ```bash
   cd real_life_app/backend
   venv\Scripts\activate  # Windows
   # or: source venv/bin/activate  # macOS/Linux
   python chat_api.py
   ```
   The backend will start on `http://localhost:5001`

2. **Terminal 2 - Start Flutter App:**
   ```bash
   cd real_life_app
   flutter run
   ```

### Option 3: Run on Specific Platform

```bash
# Android
flutter run -d android

# iOS (macOS only)
flutter run -d ios

# Web
flutter run -d chrome

# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

## Configuration

### API Key Management

The app supports multiple AI providers. Configure your API keys in the `Settings` page of the app or directly in `backend/data/api_keys.json`.

Supported providers:
- **OpenRouter** (default)
- **OpenAI**
- **Anthropic (Claude)**
- **Google AI Studio**
- **LiteLLM**

### Environment Variables

The backend reads configuration from environment variables. Optionally create a `.env` file in the backend directory:

```
OPENROUTER_API_KEY=your_api_key_here
FLASK_ENV=development
FLASK_DEBUG=True
```

## Project Structure

```
real_life_app/
├── lib/                          # Flutter frontend code
│   ├── main.dart                 # App entry point
│   ├── settings_page.dart        # Settings configuration
│   ├── chat_history_page.dart    # Chat history interface
│   ├── theme_provider.dart       # App theming
│   └── ...
├── backend/                      # Python Flask backend
│   ├── chat_api.py              # Main API server
│   ├── data_storage.py          # Data persistence
│   ├── app.py                   # Alternative entry point
│   ├── requirements.txt         # Python dependencies
│   └── data/                    # Data storage (API keys, chat history)
├── android/                     # Android platform files
├── ios/                         # iOS platform files
├── web/                         # Web platform files
├── windows/                     # Windows platform files
├── macos/                       # macOS platform files
├── linux/                       # Linux platform files
└── pubspec.yaml                 # Flutter dependencies
```

## API Endpoints

The backend provides the following REST API endpoints:

- `POST /api/chat` - Send chat messages to AI
- `POST /api/keys` - Save API keys
- `GET /api/keys` - Get saved API keys
- `GET /api/history` - Get chat history
- `POST /api/history` - Save chat conversations

## Running on Another PC (Setup for Collaborators)

To run this app on another user's PC, they need to follow these steps:

### Prerequisites (Install on Collaborator's PC)
1. **Flutter SDK**: Download from https://flutter.dev/docs/get-started/install
2. **Python 3.8+**: Download from https://python.org/downloads
3. **Git**: Download from https://git-scm.com/downloads

### Setup Steps for Collaborator

1. **Clone the repository:**
   ```bash
   git clone https://github.com/krithik-create/cs_theory_to_irl.git
   cd cs_theory_to_irl
   ```

2. **Backend Setup:**
   ```bash
   cd backend
   python -m venv venv
   # Windows:
   venv\Scripts\activate
   # macOS/Linux:
   source venv/bin/activate

   pip install -r requirements.txt
   ```

3. **Configure API Key:**
   Get their own OpenRouter API key from https://openrouter.ai and edit `data/api_keys.json`:
   ```json
   {
     "127.0.0.1": {
       "OpenRouter": {
         "api_key": "sk-or-v1-YOUR_ACTUAL_API_KEY_HERE",
         "updated_at": "2025-11-15T13:00:00.000000"
       }
     }
   }
   ```

4. **Frontend Setup:**
   ```bash
   cd ..
   flutter pub get
   ```

5. **Run the Application:**
   - **Terminal 1** (Backend):
     ```bash
     cd backend
     # Activate virtual environment as above
     python chat_api.py
     ```
   - **Terminal 2** (Frontend):
     ```bash
     flutter run
     ```

### Important Notes for Collaborators

- **API Keys**: Each collaborator needs their own OpenRouter API key to use the AI features
- **Data Storage**: Chat history and API keys are stored locally on each user's machine
- **Network**: The backend runs on `localhost:5001` - ensure no firewall blocks this port
- **Platform Requirements**:
  - For Android: Android SDK and emulator/device
  - For iOS: macOS with Xcode (Apple devices only)
  - For Web: Chrome/Firefox
  - For Desktop: Native support for Windows/macOS/Linux

### Testing the Setup
- Open the app and go to Settings to verify API key configuration
- Try sending a test message to ensure backend communication works
- Check that chat history saves properly

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes and commit: `git commit -am 'Add new feature'`
4. Push to the branch: `git push origin feature-name`
5. Submit a pull request

## Troubleshooting

### Common Issues

1. **"Python not found"**: Ensure Python is installed and added to PATH
2. **"Flutter command not found"**: Add Flutter to your PATH environment variable
3. **Backend connection failed**: Ensure backend is running on port 5001
4. **API Key errors**: Check that your API key is correctly configured in `data/api_keys.json`

### Network Issues

- Ensure firewall allows connections on port 5001
- Check that both frontend and backend are running on the same network

## License

This project is private and not intended for public distribution.

## Getting Started with Flutter Development

For help getting started with Flutter development, view the [online documentation](https://docs.flutter.dev/), which offers tutorials, samples, guidance on mobile development, and a full API reference.
#   c s _ t h e o r y _ t o _ i r l  
 