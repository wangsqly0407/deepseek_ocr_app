#!/bin/bash

echo "======================================"
echo "DeepSeek OCR Service Restart Script"
echo "======================================"

# Function to check GPU status
check_gpu_status() {
    echo "🔍 Checking GPU status..."

    # Check if nvidia-smi is available
    if ! command -v nvidia-smi &> /dev/null; then
        echo "❌ nvidia-smi not found. NVIDIA drivers not installed or not in PATH."
        return 2
    fi

    # Check driver version
    DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | head -1)
    echo "📊 NVIDIA Driver Version: ${DRIVER_VERSION}"

    # Check GPU 4 specifically
    if nvidia-smi -i 4 &> /dev/null; then
        GPU4_FREE=$(nvidia-smi -i 4 --query-gpu=memory.free --format=csv,noheader,nounits | tr -d ' ')
        GPU4_TOTAL=$(nvidia-smi -i 4 --query-gpu=memory.total --format=csv,noheader,nounits | tr -d ' ')
        GPU4_NAME=$(nvidia-smi -i 4 --query-gpu=name --format=csv,noheader,nounits)

        echo "🎯 GPU 4: ${GPU4_NAME}"
        echo "💾 Memory: ${GPU4_FREE} MB free / ${GPU4_TOTAL} MB total"

        # Calculate required memory (need at least 6GB for DeepSeek-OCR)
        REQUIRED_MEMORY=6144

        if [ "$GPU4_FREE" -lt "$REQUIRED_MEMORY" ]; then
            echo "⚠️  WARNING: GPU 4 has insufficient memory (<${REQUIRED_MEMORY}MB free)"
            echo "   Current: ${GPU4_FREE}MB free, Required: ${REQUIRED_MEMORY}MB"
            echo "   Consider stopping other processes or using CPU mode"
            return 1
        else
            echo "✅ GPU 4 has sufficient memory for DeepSeek-OCR"
            return 0
        fi
    else
        echo "❌ GPU 4 not found or not accessible"
        echo "   Available GPUs:"
        nvidia-smi --query-gpu=index,name --format=csv,noheader | sed 's/^/     /'
        return 2
    fi
}

# Function to stop existing containers
stop_containers() {
    echo "🛑 Stopping existing containers..."
    docker-compose down
    echo "✅ Containers stopped"
}

# Function to clean up GPU memory
cleanup_gpu() {
    echo "🧹 Cleaning up GPU memory..."
    # Kill any lingering Python processes using GPU
    pkill -f "python.*main.py" 2>/dev/null || true

    # Wait a moment for cleanup
    sleep 3
    echo "✅ GPU cleanup completed"
}

# Function to start services
start_services() {
    echo "🚀 Starting DeepSeek OCR services..."

    # Check GPU status again
    GPU_STATUS=$(check_gpu_status)
    GPU_EXIT_CODE=$?

    echo "$GPU_STATUS"

    case $GPU_EXIT_CODE in
        0)
            echo "✅ GPU 4 is available, starting with GPU support"
            docker-compose up -d
            ;;
        1|2)
            echo "⚠️  GPU 4 is not available, but will start services anyway"
            echo "   Service will automatically fallback to CPU mode if needed"
            docker-compose up -d
            ;;
        *)
            echo "❌ Unknown GPU status, but proceeding with service startup"
            docker-compose up -d
            ;;
    esac

    echo "⏳ Waiting for services to start..."
    sleep 15  # Give more time for model loading

    # Check if backend is running
    if docker-compose ps backend | grep -q "Up"; then
        echo "✅ Services started successfully!"
        echo "📊 Checking recent container logs:"
        docker-compose logs --tail=30 backend

        # Additional health check
        echo "🔍 Checking service health..."
        sleep 5
        if curl -s http://localhost:8000/health > /dev/null 2>&1; then
            echo "✅ Backend health check passed!"
        else
            echo "⚠️  Backend health check failed, but container is running"
            echo "   Check logs for more details"
        fi
    else
        echo "❌ Services failed to start. Checking logs..."
        docker-compose logs backend
        exit 1
    fi
}

# Main execution
main() {
    echo "Starting DeepSeek OCR service restart process..."

    # Step 1: Check current GPU status
    if ! check_gpu_status; then
        echo "⚠️  GPU 4 has insufficient memory. Proceeding with cleanup..."
    fi

    # Step 2: Stop existing containers
    stop_containers

    # Step 3: Clean up GPU memory
    cleanup_gpu

    # Step 4: Check GPU status again
    echo "🔍 Checking GPU status after cleanup..."
    check_gpu_status

    # Step 5: Start services
    start_services

    echo "🎉 DeepSeek OCR service restart completed!"
    echo "📱 Frontend: http://localhost:3000"
    echo "🔧 Backend API: http://localhost:8000"
    echo "📚 API Docs: http://localhost:8000/docs"
}

# Run main function
main