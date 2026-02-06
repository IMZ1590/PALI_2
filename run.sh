#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "========================================================"
echo "  PALI 2 Launcher (Linux)"
echo "========================================================"

error_exit() {
    echo ""
    echo "[ERROR] $1"
    read -p "Press Enter to exit..."
    exit 1
}

# 1. Kill any existing process on port 7777 (from old run.sh)
if command -v lsof &> /dev/null; then
    FORCE_KILL=$(lsof -t -i:7777)
    if [ ! -z "$FORCE_KILL" ]; then
        echo "[INFO] Killing process on port 7777: $FORCE_KILL"
        kill -9 $FORCE_KILL
    fi
fi

# 2. Check Python
if ! command -v python3 &> /dev/null; then
    error_exit "Python3 is not installed. Please install python3."
fi

# 3. Check/Create venv (Robust Method from PALI.sh)
if [ ! -f "venv/bin/pip" ]; then
    echo "[INFO] Creating virtual environment..."
    rm -rf venv
    python3 -m venv venv > /dev/null 2>&1
    
    if [ ! -f "venv/bin/pip" ]; then
        echo "[WARN] Standard venv creation failed. Retrying with workaround..."
        python3 -m venv --without-pip venv || error_exit "Failed to create bare venv."
        
        echo "[INFO] Downloading pip bootstrapper..."
        GET_PIP_URL="https://bootstrap.pypa.io/get-pip.py"
        if command -v curl &> /dev/null; then
            curl -sL "$GET_PIP_URL" -o get-pip.py
        elif command -v wget &> /dev/null; then
            wget -q "$GET_PIP_URL" -O get-pip.py
        else
            error_exit "Need 'curl' or 'wget' installed to download pip."
        fi
        
        echo "[INFO] Installing pip manually..."
        ./venv/bin/python get-pip.py > /dev/null 2>&1
        rm get-pip.py
    fi
    echo "[INFO] Installing dependencies..."
    ./venv/bin/pip install -r requirements.txt || error_exit "Failed to install libraries."
else
    # Verify existing env
    ./venv/bin/python -c "import fastapi" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "[INFO] Repairing dependencies..."
        ./venv/bin/pip install -r requirements.txt || error_exit "Failed to repair libraries."
    fi
fi

# 4. Launch with Browser Open
echo "[INFO] Starting Backend..."
echo "[NOTE] The browser will open automatically."
echo "[INFO] Close this window to stop application (Ctrl+C)."

# Open browser in background
(sleep 3 && (xdg-open "http://localhost:7777" || open "http://localhost:7777" || echo "Please open http://localhost:7777 manually")) &

# Run in FOREGROUND
./venv/bin/python backend/main.py
