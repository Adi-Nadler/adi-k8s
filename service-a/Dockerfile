# syntax=docker/dockerfile:1

# Use a minimal Python image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements first to leverage Docker layer caching
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Expose to HTTP
EXPOSE 80

# Copy the application code
COPY app.py ./

# ENV values
ENV AVG_INTERVAL=10
ENV API_URL="https://api.coinbase.com/v2/prices/BTC-USD/spot"
ENV DATA_PATH="data.amount"

# Health check for Docker container (checks a local endpoint)
HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost:8080/health || exit 1

# Run the application
CMD ["python", "-u", "app.py"]
