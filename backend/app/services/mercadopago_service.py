"""
Serviço de Integração com MercadoPago
Suporta Web Checkout com checkout.js
"""

import os
from typing import Dict, Optional, List
from datetime import datetime
import json
import requests
from sqlalchemy.orm import Session


class MercadoPagoService:
    def __init__(self):
        self.access_token = os.getenv("MERCADOPAGO_ACCESS_TOKEN")
        self.client_id = os.getenv("MERCADOPAGO_CLIENT_ID")
        self.base_url = "https://api.mercadopago.com"
        self.webhook_url = os.getenv("WEBHOOK_URL", "http://localhost:8000")
        
        if not self.access_token:
            raise ValueError("MERCADOPAGO_ACCESS_TOKEN não configurado")

    def create_preference(
        self,
        user_id: str,
        username: str,
        email: str,
        plan: str,
        price: float,
        description: str = None,
    ) -> Dict:
        """
        Criar preferência de pagamento no MercadoPago
        
        Args:
            user_id: ID do usuário
            username: Nome de usuário
            email: Email do usuário
            plan: Tipo de plano (Basic, Standard, Premium)
            price: Valor em reais (ex: 15.00)
            description: Descrição do item
            
        Returns:
            Dict com preference_id e init_point para redirecionar
        """
        
        if not description:
            description = f"Plano {plan} - Nexus Premium"
        
        preference_data = {
            "items": [
                {
                    "title": f"Plano {plan} - Nexus Premium",
                    "description": description,
                    "quantity": 1,
                    "unit_price": price,
                }
            ],
            "payer": {
                "name": username,
                "email": email,
            },
            "back_urls": {
                "success": f"{self.webhook_url}/payments/success",
                "failure": f"{self.webhook_url}/payments/failure",
                "pending": f"{self.webhook_url}/payments/pending"
            },
            "auto_return": "approved",
            "external_reference": f"user_{user_id}_plan_{plan}",
            "metadata": {
                "user_id": str(user_id),
                "plan": plan,
                "email": email,
            },
            "payment_methods": {
                "installments": 1
            },
            "notification_url": f"{self.webhook_url}/payments/webhook"
        }
        
        headers = {
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": "application/json"
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/checkout/preferences",
                json=preference_data,
                headers=headers,
                timeout=10
            )
            response.raise_for_status()
            
            preference = response.json()
            return {
                "preference_id": preference.get("id"),
                "init_point": preference.get("init_point"),
                "sandbox_init_point": preference.get("sandbox_init_point"),
                "payment_url": preference.get("sandbox_init_point") or preference.get("init_point")
            }
            
        except requests.exceptions.RequestException as e:
            raise Exception(f"Erro ao criar preferência MercadoPago: {str(e)}")

    def get_payment_status(self, payment_id: str) -> Dict:
        """Obter status de um pagamento"""
        
        headers = {
            "Authorization": f"Bearer {self.access_token}",
        }
        
        try:
            response = requests.get(
                f"{self.base_url}/v1/payments/{payment_id}",
                headers=headers,
                timeout=10
            )
            response.raise_for_status()
            
            payment = response.json()
            return {
                "id": payment.get("id"),
                "status": payment.get("status"),
                "status_detail": payment.get("status_detail"),
                "amount": payment.get("transaction_amount"),
                "currency": payment.get("currency_id"),
                "payer_email": payment.get("payer", {}).get("email"),
                "external_reference": payment.get("external_reference"),
                "date_created": payment.get("date_created"),
                "date_approved": payment.get("date_approved"),
            }
            
        except requests.exceptions.RequestException as e:
            raise Exception(f"Erro ao obter status: {str(e)}")

    def process_webhook(self, webhook_data: Dict) -> Dict:
        """Processar webhook do MercadoPago"""
        
        try:
            if webhook_data.get("type") == "payment":
                payment_id = webhook_data.get("data", {}).get("id")
                
                if not payment_id:
                    return {"status": "error", "message": "Payment ID não encontrado"}
                
                payment_info = self.get_payment_status(payment_id)
                
                return {
                    "status": "ok",
                    "payment_id": payment_id,
                    "payment_status": payment_info.get("status"),
                    "external_reference": payment_info.get("external_reference"),
                }
            
            return {"status": "ok"}
            
        except Exception as e:
            return {"status": "error", "message": str(e)}

    def refund_payment(self, payment_id: str) -> Dict:
        """Reembolsar um pagamento"""
        
        headers = {
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": "application/json"
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/v1/payments/{payment_id}/refunds",
                headers=headers,
                timeout=10
            )
            response.raise_for_status()
            
            refund = response.json()
            return {
                "status": "ok",
                "refund_id": refund.get("id"),
                "amount": refund.get("amount"),
            }
            
        except requests.exceptions.RequestException as e:
            return {"status": "error", "message": str(e)}


def get_mercadopago_service() -> MercadoPagoService:
    """Dependency para injetar o serviço"""
    return MercadoPagoService()
