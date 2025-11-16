@echo off
cd real_life_app\backend

REM Activate virtual environment if it exists (check multiple common names)
if exist venv\Scripts\activate.bat (
    call venv\Scripts\activate.bat
    echo Activated virtual environment: venv
) else if exist env\Scripts\activate.bat (
    call env\Scripts\activate.bat
    echo Activated virtual environment: env
) else if exist .venv\Scripts\activate.bat (
    call .venv\Scripts\activate.bat
    echo Activated virtual environment: .venv
) else if exist virtualenv\Scripts\activate.bat (
    call virtualenv\Scripts\activate.bat
    echo Activated virtual environment: virtualenv
) else if exist venv\Scripts\activate (
    REM Fallback to bash-style activation on Windows
    call venv\Scripts\activate
    echo Activated virtual environment: venv
) else (
    echo Warning: No virtual environment found (checked: venv, env, .venv, virtualenv)
    echo Using system Python - consider creating a virtual environment with: python -m venv venv
)

REM Install requirements if not already installed
pip install -r requirements.txt

REM Start the chat API server on port 5001
python chat_api.py

pause
