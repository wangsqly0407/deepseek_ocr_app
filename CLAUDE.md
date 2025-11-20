# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a modern OCR web application that combines DeepSeek-OCR model with a React frontend and FastAPI backend. The application provides 4 core OCR modes with advanced image processing capabilities and GPU acceleration.

## Common Commands

### Development and Deployment
```bash
# Start the full application (builds if needed)
docker compose up --build

# Start in detached mode
docker compose up -d

# Stop and rebuild from scratch
docker compose down
docker compose build --no-cache
docker compose up --build

# Use optimized restart script with GPU checks
./scripts/restart_service.sh

# Check GPU status and availability
./scripts/check_gpu_status.sh
```

### Debugging and Maintenance
```bash
# View backend logs
docker compose logs -f backend

# View all service logs
docker compose logs -f

# Check running containers
docker compose ps

# Execute into backend container
docker compose exec backend bash

# Access the API documentation
curl http://localhost:8000/docs
# or visit http://localhost:8000/docs in browser
```

### Environment Setup
```bash
# Copy environment configuration
cp .env.example .env

# Edit configuration (important for GPU and performance tuning)
vim .env
```

## Architecture Overview

### Frontend Architecture (React + Vite)
The frontend follows a component-based architecture with state management centralized in `App.jsx`:

- **App.jsx**: Main application component that manages OCR state, API communication, and coordinates between child components
- **ImageUpload.jsx**: Handles drag-and-drop file upload with 100MB limit support
- **ModeSelector.jsx**: Provides 4 OCR mode selection (Plain OCR, Describe, Find, Freeform)
- **ResultPanel.jsx**: Displays OCR results with HTML/Markdown rendering and bounding box visualization
- **AdvancedSettings.jsx**: Collapsible panel for processing parameters

Key frontend patterns:
- Uses Framer Motion for animations
- TailwindCSS for glass morphism design
- Axios for API communication with error handling
- State is passed as props from parent to children

### Backend Architecture (FastAPI + PyTorch)
The backend is a single-file FastAPI application (`main.py`) with these key sections:

- **Model Loading**: Lifespan context loads DeepSeek-OCR with GPU fallback logic
- **Prompt Builder**: Constructs prompts for different OCR modes
- **Grounding Parser**: Handles special bounding box format `<|ref|>label<|/ref|><|det|>[[coords]]<|/det|>`
- **API Endpoints**: `/api/ocr` for image processing, `/health` for status checks

Critical backend logic:
- GPU device selection with `CUDA_VISIBLE_DEVICES` environment variable
- Automatic CPU fallback when GPU initialization fails
- Coordinate scaling from normalized 0-999 to actual pixel dimensions
- Multi-bounding box support with proper parsing

### OCR Processing Pipeline

The application uses DeepSeek-OCR model with these processing characteristics:

1. **Dynamic Cropping**: Large images are automatically split into tiles for processing
2. **Coordinate System**: Model outputs normalized coordinates (0-999) that backend scales to image dimensions
3. **Memory Management**: GPU optimization with configurable parameters (`BASE_SIZE`, `IMAGE_SIZE`)
4. **Output Formats**: Supports plain text, HTML tables, and structured data with bounding boxes

### Container Architecture

The Docker setup uses multi-stage builds:

- **Backend**: `nvcr.io/nvidia/pytorch:24.07-py3` (CUDA 12.x compatible)
- **Frontend**: Node.js build stage + Nginx serving stage
- **GPU Configuration**: Forced to use GPU 4 to avoid conflicts, with memory optimization
- **Volume Mounting**: `/models` directory for persistent model storage

## Key Configuration

### Environment Variables (.env)
The application relies heavily on environment configuration:

```bash
# GPU Configuration (CRITICAL for production)
CUDA_VISIBLE_DEVICES=4          # Specifies which GPU to use
NVIDIA_VISIBLE_DEVICES=4        # Docker GPU device restriction
PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True,max_split_size_mb:128

# Performance Tuning
BASE_SIZE=800                   # Reduced from 1024 for memory efficiency
IMAGE_SIZE=512                  # Reduced from 640 for tile processing
CROP_MODE=true                  # Enable dynamic cropping for large images

# API Configuration
MODEL_NAME=/models/DeepSeek-OCR # Local model path (not HuggingFace)
HF_HOME=/models                 # Model cache directory
```

### Model Loading Strategy
The backend uses `local_files_only=True` to ensure only local model files are used, preventing downloads from HuggingFace. Models should be pre-downloaded to `/models/DeepSeek-OCR`.

## Development Guidelines

### Working with GPU Issues
- Always use `./scripts/check_gpu_status.sh` to verify GPU availability before deployment
- The application includes automatic CPU fallback - it will run even if GPU initialization fails
- GPU memory issues are common with large images; adjust `BASE_SIZE` and `IMAGE_SIZE` accordingly

### Testing OCR Functionality
- Use the `/docs` endpoint for interactive API testing
- Test different modes: plain_ocr, describe, find_ref, freeform
- Verify bounding box coordinate scaling with various image sizes
- Check both GPU and CPU modes by modifying environment variables

### Frontend Development
- The React app uses Vite for fast development builds
- Component props flow from App.jsx downward
- API responses are handled in App.jsx with state management
- Use `dangerouslySetInnerHTML` for HTML table rendering from model outputs

### Backend Modifications
- Model loading happens in the `lifespan` async context manager
- All OCR logic is contained in the single `main.py` file
- Prompt building logic supports the 4 core modes
- Grounding parsing handles multiple bounding box formats

## Troubleshooting

### Common GPU Issues
- **Driver Version**: Use NVIDIA Docker images compatible with host drivers (24.07 for CUDA 12.2)
- **Memory Allocation**: Enable `expandable_segments:True` for better GPU memory management
- **Device Conflicts**: The application is configured for GPU 4 to avoid conflicts with other processes

### Model Loading Problems
- Verify model files exist in `/models/DeepSeek-OCR/`
- Check that `local_files_only=True` is set in model loading
- Ensure proper permissions on model directory

### Performance Tuning
- Reduce `BASE_SIZE` and `IMAGE_SIZE` for memory-constrained environments
- Enable `CROP_MODE` for large images
- Monitor GPU memory usage with `nvidia-smi`

### Service Management
- Use the provided restart script which includes health checks
- The script automatically handles GPU availability scenarios
- Check both container status and API health endpoints during debugging

## Access Points

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health