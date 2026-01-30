FROM rayproject/ray:2.53.0-py312

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies
RUN uv pip install --system -r pyproject.toml

# Copy application code and model
COPY . .

# Expose ports: 8000 (Serve), 8265 (Dashboard), 8080 (Metrics)
EXPOSE 8000 8265 8080

# The command to start Ray and Serve will be handled by docker-compose
