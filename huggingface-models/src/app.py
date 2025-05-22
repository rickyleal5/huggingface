from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from transformers import pipeline
import os
import logging
from typing import Optional
import torch

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Model Server API")

# Get configuration from environment variables
MODEL_NAME = os.getenv("MODEL_NAME", "gpt2")
TASK = os.getenv("TASK", "text-generation")
PORT = int(os.getenv("PORT", "8000"))
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

# Initialize the model
model = None
try:
    logger.info(f"Loading model {MODEL_NAME} for task {TASK} on {DEVICE}")
    model = pipeline(
        TASK,
        model=MODEL_NAME,
        device=DEVICE,
        model_kwargs={"low_cpu_mem_usage": True}
    )
    logger.info("Model loaded successfully")
except Exception as e:
    logger.error(f"Error loading model: {e}")
    # Don't raise the exception, let the health check handle it

class TextRequest(BaseModel):
    text: str
    max_length: int = 50
    num_return_sequences: int = 1

class HealthResponse(BaseModel):
    status: str
    model: str
    task: str
    environment: str
    model_loaded: bool
    device: str

@app.get("/health", response_model=HealthResponse)
async def health_check():
    return {
        "status": "healthy" if model is not None else "unhealthy",
        "model": MODEL_NAME,
        "task": TASK,
        "environment": ENVIRONMENT,
        "model_loaded": model is not None,
        "device": DEVICE
    }

@app.get("/")
async def root():
    return {"message": "Model Server API", "docs": "/docs"}

@app.post("/models/{model_name}/generate")
async def generate_text(model_name: str, request: TextRequest):
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    if model_name != MODEL_NAME:
        raise HTTPException(status_code=400, detail=f"Model {model_name} not available. This server is running {MODEL_NAME}")
    
    try:
        result = model(
            request.text,
            max_length=request.max_length,
            num_return_sequences=request.num_return_sequences
        )
        return {"result": result}
    except Exception as e:
        logger.error(f"Error generating text: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    logger.info(f"Starting server in {ENVIRONMENT} environment on port {PORT}")
    uvicorn.run(app, host="0.0.0.0", port=PORT) 