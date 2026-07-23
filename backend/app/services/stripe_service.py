"""
Serviço de Integração com Stripe
Stub preparado para implementação futura.
"""

import logging

logger = logging.getLogger(__name__)


class StripeService:
    """Serviço para processamento de pagamentos via Stripe."""

    def __init__(self):
        self.api_key = None  # Configurar via variável de ambiente STRIPE_API_KEY
        self.webhook_secret = None  # Configurar via STRIPE_WEBHOOK_SECRET

    def create_checkout(self, plan: str, price: float, user_id: str, email: str) -> dict:
        """
        Cria sessão de checkout no Stripe.
        """
        if not self.api_key:
            logger.warning("Stripe nao configurado. STRIPE_API_KEY nao definida.")
            return {
                "checkout_url": None,
                "session_id": None,
                "error": "Stripe nao configurado",
            }
        return {
            "checkout_url": f"https://checkout.stripe.com/pay/{user_id}",
            "session_id": f"cs_{user_id}",
        }

    def verify(self, session_id: str) -> dict:
        """
        Verifica status de uma sessao de checkout.
        """
        return {
            "session_id": session_id,
            "status": "pending",
            "message": "Stripe nao configurado - verificacao simulada",
        }


def get_stripe_service() -> StripeService:
    """Retorna instancia do servico Stripe."""
    return StripeService()
