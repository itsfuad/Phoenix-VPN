@echo off
echo Starting VPN Server...
echo.

REM Check if Elixir is installed
where elixir >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: Elixir is not installed or not in PATH
    echo Please install Elixir from https://elixir-lang.org/install.html
    pause
    exit /b 1
)

REM Check if dependencies are installed
echo Checking dependencies...
mix deps.get
if %errorlevel% neq 0 (
    echo Error: Failed to get dependencies
    pause
    exit /b 1
)

REM Compile the project
echo Compiling project...
mix compile
if %errorlevel% neq 0 (
    echo Error: Failed to compile project
    pause
    exit /b 1
)

REM Start the VPN server
echo.
echo VPN Server is starting...
echo Press Ctrl+C to stop the server
echo.
REM Start the server in the foreground
start /wait cmd /c "mix run --no-halt" 