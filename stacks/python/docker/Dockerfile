# syntax=docker/dockerfile:1
# agent-kit: Python app — deps in a venv layer, run as non-root.
FROM python:3.12-slim AS build
ENV PIP_NO_CACHE_DIR=1 PYTHONDONTWRITEBYTECODE=1
WORKDIR /app
RUN python -m venv /venv
ENV PATH=/venv/bin:$PATH
COPY requirements.txt ./
RUN pip install -r requirements.txt
COPY . .

FROM python:3.12-slim AS runtime
ENV PATH=/venv/bin:$PATH PYTHONUNBUFFERED=1
RUN useradd --uid 10001 --no-create-home app
WORKDIR /app
COPY --from=build /venv /venv
COPY --from=build --chown=app:app /app /app
USER app
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
