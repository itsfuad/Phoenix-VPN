#!/bin/bash

echo "Starting VPN Server..."
echo

# Check if Elixir is installed
if ! command -v elixir &> /dev/null; then
    echo "Error: Elixir is not installed"
    echo "Please install Elixir from https://elixir-lang.org/install.html"
    exit 1
fi

# Check if dependencies are installed
echo "Checking dependencies..."
mix deps.get
if [ $? -ne 0 ]; then
    echo "Error: Failed to get dependencies"
    exit 1
fi

# Compile the project
echo "Compiling project..."
mix compile
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile project"
    exit 1
fi

# Start the VPN server
echo
echo "VPN Server is starting..."
echo "Press Ctrl+C to stop the server"
echo
# Use exec to replace the shell with the VPN server process
exec mix run --no-halt 