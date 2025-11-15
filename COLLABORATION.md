# 🤝 Collaboration Guide: Real Life Applications App

Welcome! This guide explains how to collaborate on this AI-powered educational Flutter application.

## 📋 Overview

The **Real Life Applications App** helps students understand real-world applications of academic concepts through interactive chat with AI tutors. It uses Flutter for the frontend and Python Flask for the backend.

## 🚀 Quick Start for Collaborators

### 1. Prerequisites
Install these before starting:
- **Flutter SDK** ([Installation Guide](https://flutter.dev/docs/get-started/install))
- **Python 3.8+** ([Download](https://python.org/downloads))
- **Git** ([Download](https://git-scm.com/downloads))

### 2. Clone the Repository
```bash
git clone https://github.com/krithik-create/cs_theory_to_irl.git
cd cs_theory_to_irl
```

### 3. Get Your API Key
**Each collaborator needs their own OpenRouter API key:**
1. Go to [https://openrouter.ai/keys](https://openrouter.ai/keys)
2. Create a free account and generate an API key
3. Copy the key (starts with `sk-or-v1-`)

### 4. Configure API Key
Edit `backend/data/api_keys.json`:
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

### 5. Run the Application

**Terminal 1: Start Backend**
```bash
# Windows:
start_backend.cmd

# macOS/Linux (first time):
chmod +x start_backend.sh && ./start_backend.sh

# macOS/Linux (subsequent times):
./start_backend.sh
```

**Terminal 2: Start Flutter App**
```bash
flutter pub get  # Install dependencies (first time only)
flutter run      # Run on default device
```

## 🛠️ Detailed Setup Instructions

### Backend Setup (Python Flask)
The startup scripts handle this automatically, but manually:

```bash
cd backend

# Create virtual environment (if using venv name)
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Start server
python chat_api.py
```

### Frontend Setup (Flutter)
```bash
# From repository root
flutter pub get  # Install Flutter packages
flutter run      # Run app
```

### Platform-Specific Running
```bash
# Android device/emulator
flutter run -d android

# iOS simulator (macOS only)
flutter run -d ios

# Web browser
flutter run -d chrome

# Desktop apps
flutter run -d windows  # Windows
flutter run -d macos    # macOS
flutter run -d linux    # Linux
```

## 📂 Project Structure
```
├── lib/                          # Flutter frontend code
│   ├── main.dart                 # App entry point
│   ├── settings_page.dart        # API key configuration
│   ├── chat_history_page.dart    # Chat history interface
│   └── theme_provider.dart       # App theming
├── backend/                      # Python Flask backend
│   ├── chat_api.py              # Main AI chat server (port 5001)
│   ├── data_storage.py          # Local data persistence
│   ├── app.py                   # Alternative server (port 5000)
│   ├── requirements.txt         # Python dependencies
│   └── data/                    # Local data storage (EXCLUDED from Git)
├── android/, ios/, web/         # Platform-specific files
├── windows/, macos/, linux/     # Desktop platform files
├── start_backend.cmd            # Windows startup script
├── start_backend.sh             # macOS/Linux startup script
└── pubspec.yaml                 # Flutter dependencies
```

## 🔧 Technical Details

### Virtual Environment Detection
The startup scripts automatically detect common virtual environment names:
- `venv` (default/most common)
- `env`
- `.venv`
- `virtualenv`

If no virtual environment found, scripts warn you and use system Python.

### API Configuration
- **Default Provider**: OpenRouter (supports multiple AI models)
- **Port**: Backend runs on `localhost:5001`
- **Data Storage**: Chat history and API keys stored locally per user
- **Supported Providers**: OpenRouter, OpenAI, Anthropic, Google AI Studio, LiteLLM

### Security Notes
- API keys are **never committed** to Git (excluded in `.gitignore`)
- Each collaborator uses their own API key
- Chat history stays local to each machine

## 🐛 Troubleshooting

### Common Issues

**"Flutter command not found"**
```
# Add Flutter to your PATH
# Windows: Check Flutter installation folder
# macOS/Linux: export PATH="$PATH:`pwd`/flutter/bin"
```

**"Python not found" or "pip not found"**
```
# Ensure Python 3.8+ is installed and in PATH
# Windows: Reinstall Python and check "Add to PATH"
# macOS: Use python3/pip3 commands
```

**"API key not configured"**
```
# Check backend/data/api_keys.json file
# Ensure your OpenRouter API key is correctly entered
# Restart backend after changing API key
```

**"Port 5001 already in use"**
```
# Kill process using port 5001, or change port in chat_api.py
# Find process: netstat -ano | findstr :5001 (Windows)
# Kill process: taskkill /PID <PID> /F (Windows)
```

**"Virtual environment not activated"**
```
# Scripts detect common venv names automatically
# Or manually activate: source venv/bin/activate (Linux/macOS)
# Or manually activate: venv\Scripts\activate (Windows)
```

**Flutter Build Errors**
```
flutter clean  # Clear build cache
flutter pub get  # Reinstall dependencies
flutter doctor  # Check Flutter setup
```

**Backend Connection Failed**
```
# Ensure backend is running on localhost:5001
# Check firewall isn't blocking port 5001
# Try different port if 5001 is unavailable
```

### Getting Help
1. Check this documentation first
2. Look at existing issues on GitHub
3. Test with minimal setup (just backend, then just frontend)
4. Verify all prerequisites are correctly installed

## 🤝 How to Contribute

### Development Workflow
1. **Fork** the repository on GitHub
2. **Clone** your fork locally
3. Create a **feature branch**: `git checkout -b feature-name`
4. **Make changes** and test thoroughly
5. **Commit** your changes: `git commit -m "Add feature description"`
6. **Push** to your fork: `git push origin feature-name`
7. Create a **Pull Request** on the main repository

### Code Guidelines
- Test on multiple platforms (Android, Web, Desktop)
- Ensure API keys work with different providers
- Keep virtual environment flexibility
- Update documentation for any new features
- Follow Flutter and Python best practices

### Communication
- Create GitHub issues for bugs or feature requests
- Use descriptive commit messages
- Keep pull request descriptions clear
- Tag relevant collaborators for reviews

## 📞 Support

If you run into issues:
1. Check this guide
2. Search existing GitHub issues
3. Create a new issue with:
   - Your operating system
   - Flutter version (`flutter doctor`)
   - Python version (`python --version`)
   - Exact error messages
   - Steps to reproduce

**Happy collaborating! 🚀**
