.PHONY: help install run test lint typecheck check up down logs

help:
	@echo "Comandos disponiveis:"
	@echo "  make install    - instala as dependencias no ambiente virtual ativo"
	@echo "  make run        - sobe a API com uvicorn --reload"
	@echo "  make test       - roda os testes automatizados"
	@echo "  make lint       - roda o ruff (linter)"
	@echo "  make typecheck  - roda o mypy (checagem de tipos)"
	@echo "  make check      - roda lint + typecheck + test, em sequencia"
	@echo "  make up         - sobe o banco de dados via docker compose"
	@echo "  make down       - derruba o banco de dados"
	@echo "  make logs       - mostra os logs do banco (confirma o seed)"

install:
	pip install -r requirements.txt

run:
	uvicorn app.main:app --reload

test:
	pytest -v

lint:
	ruff check .

typecheck:
	mypy app

check: lint typecheck test

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs postgres