# ---- Estágio 1: builder ----
# Instala as dependências num ambiente virtual isolado. As ferramentas de
# build usadas aqui não são copiadas para o estágio final.
FROM python:3.11-slim AS builder

WORKDIR /app

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt


# ---- Estágio 2: runtime ----
# Imagem final, enxuta: só o Python, o venv já pronto, e o código da aplicação.
FROM python:3.11-slim AS runtime

# Usuário sem privilégios de administrador, dedicado a rodar a aplicação.
RUN useradd --create-home --uid 1000 appuser

WORKDIR /app

# Copia só o ambiente virtual já pronto do estágio anterior (sem compilador,
# sem cache de build).
COPY --from=builder /opt/venv /opt/venv

# Copia o código da aplicação já com o dono correto (evita um chown separado).
COPY --chown=appuser:appuser app ./app

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# A partir daqui, tudo roda como appuser, não root.
USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
