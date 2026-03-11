# Dockerfile (simple, production-ready)
FROM python:3.14-slim

# metadata
LABEL org.opencontainers.image.source="local"

# crear usuario no-root y preparar rutas
RUN useradd --create-home --shell /bin/bash appuser

WORKDIR /app

# variables útiles
ENV PYTHONUNBUFFERED=1
ENV PATH="/home/appuser/.local/bin:${PATH}"

# copiar requirements primero (cache layer)
COPY requirements.txt .

# instalar deps sin cache
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# copiar código
COPY . .

# si en settings.py tienes STATIC_ROOT = BASE_DIR / "static"
# recoger staticfiles (ejecutar como root para poder escribir)
WORKDIR /app/core
RUN python manage.py collectstatic --no-input

# crear carpeta y dar permisos a appuser
RUN mkdir -p /app/static && chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["gunicorn", "core.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3"]