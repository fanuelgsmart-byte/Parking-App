FROM python:3.11-slim

WORKDIR /app

# System deps for OpenCV
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Copy AI library sources
COPY alpr_libs/ ./alpr_libs/

# Install AI libraries from local source
RUN pip install --no-cache-dir \
    "alpr_libs/fast-plate-ocr/fast-plate-ocr-master[onnx]" \
    "alpr_libs/open-image-models/open-image-models-main[onnx]" \
    "alpr_libs/fast-alpr/fast-alpr-master[onnx]"

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app source
COPY app/ ./app/

# Create directories
RUN mkdir -p captured_images

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
