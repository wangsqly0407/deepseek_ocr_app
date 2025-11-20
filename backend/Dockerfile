# Backend Dockerfile - FastAPI + DeepSeek-OCR
FROM nvcr.io/nvidia/pytorch:24.07-py3

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    HF_HOME=/models

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

<<<<<<< Updated upstream
# Copy backend code
COPY *.py .
=======
# Copy backend code (only needed for initial build, will be overridden by volume mount)
COPY main.py .
>>>>>>> Stashed changes

EXPOSE 8000

# Use uvicorn with auto-reload for development
# --reload enables hot reloading when code changes
# --workers 1 is required when using --reload
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
