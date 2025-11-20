#!/bin/bash

echo "======================================"
echo "DeepSeek OCR GPU Status Checker"
echo "======================================"

# Check NVIDIA driver and CUDA
echo "1. NVIDIA Driver Status:"
nvidia-smi

echo -e "\n2. GPU Memory Usage:"
nvidia-smi --query-gpu=index,name,memory.total,memory.used,memory.free,utilization.gpu --format=csv

echo -e "\n3. Processes Using GPU:"
nvidia-smi pmon -c 1

echo -e "\n4. Docker GPU Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -i gpu || echo "No GPU containers running"

echo -e "\n5. GPU 4 Specific Status:"
nvidia-smi -i 4 --query-gpu=index,name,memory.total,memory.used,memory.free,temperature.gpu,power.draw --format=csv

echo -e "\n6. Memory Recommendation:"
GPU4_FREE=$(nvidia-smi -i 4 --query-gpu=memory.free --format=csv,noheader,nounits | tr -d ' ')
echo "GPU 4 Free Memory: ${GPU4_FREE} MB"

if [ "$GPU4_FREE" -lt 8192 ]; then
    echo "⚠️  WARNING: GPU 4 has less than 8GB free memory. Consider:"
    echo "   - Stopping other GPU processes"
    echo "   - Using smaller BASE_SIZE and IMAGE_SIZE"
    echo "   - Checking for memory leaks"
else
    echo "✅ GPU 4 has sufficient memory for DeepSeek OCR"
fi

echo -e "\n======================================"