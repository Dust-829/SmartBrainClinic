FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the backend source code
COPY . .

# Ensure Python can find the 'app' module
ENV PYTHONPATH=/app

# Default command (will be overridden by docker-compose for each microservice)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
