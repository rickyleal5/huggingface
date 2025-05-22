FROM python:3.9-slim

# Add labels
LABEL org.opencontainers.image.title="Hugging Face GPT-2 Model Server"
LABEL org.opencontainers.image.description="A FastAPI server for serving GPT-2 model"
LABEL org.opencontainers.image.vendor="Hugging Face"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.source="https://github.com/your-org/huggingface"
LABEL org.opencontainers.image.version="1.0.0"

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    libopenblas0 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install dependencies
COPY ../../src/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY ../../src/ ./src/

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PORT=8000 \
    ENVIRONMENT=production \
    MODEL_NAME=gpt2 \
    TASK=text-generation

# Expose the port
EXPOSE ${PORT}

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

# Run the application
CMD ["python", "src/app.py"] 