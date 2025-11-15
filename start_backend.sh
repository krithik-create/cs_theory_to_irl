#!/bin/bash

# Cross-platform backend startup script for macOS/Linux
cd "$(dirname "$0")/backend"

# Function to activate virtual environment
activate_venv() {
    local venv_name=$1
    local venv_path=$venv_name

    # Check for bin/activate (Unix/Linux style)
    if [ -f "$venv_path/bin/activate" ]; then
        source "$venv_path/bin/activate"
        echo "Activated virtual environment: $venv_name"
        return 0
    # Check for Scripts/activate (Windows style)
    elif [ -f "$venv_path/Scripts/activate" ]; then
        source "$venv_path/Scripts/activate"
        echo "Activated virtual environment: $venv_name (Windows style)"
        return 0
    fi
    return 1
}

# Activate virtual environment if it exists (check multiple common names)
if activate_venv "venv"; then
    : # Already activated and echoed
elif activate_venv ".venv"; then
    : # Already activated and echoed
elif activate_venv "env"; then
    : # Already activated and echoed
elif activate_venv "virtualenv"; then
    : # Already activated and echoed
else
    echo "Warning: No virtual environment found (checked: venv, .venv, env, virtualenv)"
    echo "Using system Python - consider creating a virtual environment with: python3 -m venv venv"
fi

# Install requirements if not already installed
echo "Installing Python dependencies..."
pip install -r requirements.txt || pip3 install -r requirements.txt

# Start the chat API server on port 5001
echo "Starting backend server on http://localhost:5001"
python chat_api.py || python3 chat_api.py
