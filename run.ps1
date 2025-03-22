Write-Host "Starting VPN Server..."
Write-Host ""

# Check if Elixir is installed
if (-not (Get-Command elixir -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Elixir is not installed or not in PATH"
    Write-Host "Please install Elixir from https://elixir-lang.org/install.html"
    exit 1
}

# Check if dependencies are installed
Write-Host "Checking dependencies..."
mix deps.get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to get dependencies"
    exit 1
}

# Compile the project
Write-Host "Compiling project..."
mix compile
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to compile project"
    exit 1
}

# Start the VPN server
Write-Host ""
Write-Host "VPN Server is starting..."
Write-Host "Press Ctrl+C to stop the server"
Write-Host ""

# Start the server in the foreground
mix run --no-halt 