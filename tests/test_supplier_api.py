import uuid
from dataclasses import dataclass
from datetime import UTC, datetime

from app.infra.dependencies import get_supplier_service
from app.main import app
from app.services.errors import BusinessError, ErrorCode
from app.services.supplier_service import SupplierService

# ---------------------------------------------------------------------------
# Teste 1 — erro de negócio devolvido pelo service vira 404 na resposta HTTP
# ---------------------------------------------------------------------------

class _NotFoundSupplierService:
    """Dublê: nunca toca o banco, sempre devolve um erro de negócio pronto."""

    async def get_supplier(self, supplier_id, store_code):
        return BusinessError(ErrorCode.NOT_FOUND, f"Fornecedor '{supplier_id}' não encontrado")


def test_business_error_from_service_becomes_404(client):
    """Pega bugs onde o controller esquece de checar isinstance(result, BusinessError)
    e devolve 200 (ou deixa vazar uma exceção) em vez de traduzir o erro de negócio
    para o status HTTP correto. Não usa banco: o service inteiro é um dublê."""
    app.dependency_overrides[get_supplier_service] = lambda: _NotFoundSupplierService()

    response = client.get(
        f"/v1/suppliers/{uuid.uuid4()}",
        headers={"X-Store-Code": "10000001"},
    )

    assert response.status_code == 404
    body = response.json()
    assert body["data"] is None
    assert "não encontrado" in body["message"]


# ---------------------------------------------------------------------------
# Teste 2 — POST com campo desconhecido no corpo é rejeitado com 422
# ---------------------------------------------------------------------------

class _UnusedSupplierService:
    """Dublê que quebra o teste se for chamado - a validação deveria barrar
    a requisição ANTES do controller sequer pedir o service."""

    async def create_supplier(self, store_code, data):
        raise AssertionError("service não deveria ser chamado com corpo inválido")


def test_post_with_unknown_field_returns_422(client):
    """Pega bugs onde um DTO esquece extra='forbid' e aceita, silenciosamente,
    campos que não fazem parte do contrato da API, deixando dado não previsto
    passar batido para dentro do service."""
    app.dependency_overrides[get_supplier_service] = lambda: _UnusedSupplierService()

    response = client.post(
        "/v1/suppliers",
        headers={"X-Store-Code": "10000001"},
        json={
            "name": "Fornecedor Teste",
            "contact_phone": "11999999999",
            "campo_fantasma": True,
        },
    )

    assert response.status_code == 422


# ---------------------------------------------------------------------------
# Teste 3 — loja 10000002 não consegue ler recurso da loja 10000001
# ---------------------------------------------------------------------------

@dataclass
class _FakeSupplierRow:
    """Substitui o model do SQLAlchemy - só precisa ter os mesmos atributos
    que o SupplierResponseDTO lê via from_attributes."""

    id: uuid.UUID
    store_code: str
    name: str
    contact_phone: str
    is_active: bool = True
    created_at: datetime = None
    updated_at: datetime = None

    def __post_init__(self):
        now = datetime.now(UTC)
        self.created_at = self.created_at or now
        self.updated_at = self.updated_at or now


class _FakeSupplierRepository:
    """Dublê do repository: simula 'só existe um fornecedor, e ele pertence
    à loja 10000001' - sem tocar em banco nenhum."""

    def __init__(self, row: _FakeSupplierRow):
        self._row = row

    async def get_by_id(self, supplier_id, store_code):
        if supplier_id == self._row.id and store_code == self._row.store_code:
            return self._row
        return None

    async def get_by_phone(self, contact_phone, store_code):
        return None


def test_store_10000002_cannot_read_resource_from_store_10000001(client):
    """Pega bugs onde a query (aqui, o dublê do repository) esquece de filtrar
    por store_code - permitindo que a loja 10000002 leia um recurso que
    pertence à loja 10000001, só porque acertou o id."""
    owner_id = uuid.uuid4()
    fake_row = _FakeSupplierRow(
        id=owner_id,
        store_code="10000001",
        name="Fornecedor da Loja 1",
        contact_phone="11999999999",
    )
    fake_repository = _FakeSupplierRepository(fake_row)
    app.dependency_overrides[get_supplier_service] = lambda: SupplierService(fake_repository)

    response = client.get(
        f"/v1/suppliers/{owner_id}",
        headers={"X-Store-Code": "10000002"},
    )

    assert response.status_code == 404