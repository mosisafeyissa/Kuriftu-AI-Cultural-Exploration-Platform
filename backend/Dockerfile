# ── Backend Dockerfile ──────────────────────────────────────────────────────
FROM python:3.12-slim

# Prevents Python from writing .pyc files and buffers stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install system-level build dependencies, then clean up apt cache
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy only requirements first so Docker can cache this layer
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application source
COPY . .

# Pre-create volume mount points with correct ownership
RUN mkdir -p /app/db /app/media /app/staticfiles \
    && addgroup --system django \
    && adduser --system --ingroup django django \
    && chown -R django:django /app

USER django

# Expose the Gunicorn port
EXPOSE 8000

# Default startup; docker-compose overrides this with migrate + collectstatic first
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3"]
