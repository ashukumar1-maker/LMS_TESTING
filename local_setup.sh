#!/bin/bash

# Local Development Setup Script
# This script sets up the development environment for the fullstack template

set -e  # Exit on error

echo "🚀 Starting local development setup..."
echo ""

# Check if we're in the project root
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

# 1. Backend Setup
echo "📦 Installing backend dependencies..."
cd backend
if ! command -v uv &> /dev/null; then
    echo "❌ Error: uv is not installed. Please install it first:"
    echo "   curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi
uv sync
echo "✅ Backend dependencies installed"
echo ""

# 2. Frontend Setup
cd ../frontend
echo "📦 Installing frontend dependencies..."
if ! command -v yarn &> /dev/null; then
    echo "⚠️  Warning: yarn is not installed. Attempting to use npm..."
    npm install
else
    yarn install
fi
echo "✅ Frontend dependencies installed"
echo ""

# 3. Pre-commit Hooks Setup
cd ..
echo "🔧 Installing pre-commit hooks..."
cd backend && uv run pre-commit install && cd ..
echo "✅ Pre-commit hooks installed"
echo ""

# 4. Summary
echo "✨ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Start the development environment:"
echo "     docker-compose up -d"
echo ""
echo "  2. Access the application:"
echo "     - Frontend: http://localhost:3000"
echo "     - Backend API: http://localhost:8000"
echo "     - API Docs: http://localhost:8000/docs"
echo ""
echo "  3. (Optional) Test pre-commit hooks:"
echo "     uv run pre-commit run --all-files"
echo ""
