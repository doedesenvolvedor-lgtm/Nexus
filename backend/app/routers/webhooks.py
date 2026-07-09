from fastapi import APIRouter

router = APIRouter(tags=["Webhooks"])


@router.post("/")
async def webhook(payload: dict):
    # Validar assinatura do provedor
    # Atualizar status da assinatura
    # Registrar pagamento
    return {"status": "ok"}
