import logging
import os
from typing import Optional

import firebase_admin
from firebase_admin import credentials, messaging

logger = logging.getLogger(__name__)


class FirebaseService:
    """Serviço para integração com Firebase Cloud Messaging"""

    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self):
        if not self._initialized:
            self._initialize_firebase()
            self._initialized = True

    def _initialize_firebase(self):
        """Inicializa Firebase Admin SDK"""
        try:
            # Verificar se Firebase já foi inicializado
            try:
                firebase_admin.get_app()
                logger.info("Firebase já estava inicializado")
                return
            except ValueError:
                pass

            # Buscar arquivo de credenciais
            cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH")
            if not cred_path:
                logger.warning("FIREBASE_CREDENTIALS_PATH não configurado. Firebase será ignorado.")
                return

            if not os.path.exists(cred_path):
                logger.warning(f"Arquivo Firebase não encontrado: {cred_path}")
                return

            # Inicializar Firebase
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            logger.info("Firebase inicializado com sucesso")
        except Exception as e:
            logger.error(f"Erro ao inicializar Firebase: {e}")

    def send_notification(
        self,
        device_token: str,
        title: str,
        body: str,
        data: Optional[dict] = None,
        apns_priority: str = "10",
    ) -> bool:
        """
        Envia notificação para um dispositivo específico

        Args:
            device_token: Token do dispositivo
            title: Título da notificação
            body: Corpo da notificação
            data: Dados adicionais (opcional)
            apns_priority: Prioridade para iOS (opcional)

        Returns:
            True se enviado com sucesso, False caso contrário
        """
        try:
            message = messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                data=data or {},
                token=device_token,
                apns=messaging.APNSConfig(
                    headers={
                        "apns-priority": apns_priority,
                    },
                ),
                android=messaging.AndroidConfig(
                    priority="high",
                ),
            )

            response = messaging.send(message)
            logger.info(f"Notificação enviada: {response}")
            return True
        except Exception as e:
            logger.error(f"Erro ao enviar notificação: {e}")
            return False

    def send_multicast(
        self,
        device_tokens: list[str],
        title: str,
        body: str,
        data: Optional[dict] = None,
    ) -> dict:
        """
        Envia notificação para múltiplos dispositivos

        Args:
            device_tokens: Lista de tokens
            title: Título da notificação
            body: Corpo da notificação
            data: Dados adicionais (opcional)

        Returns:
            Dicionário com contagens (success, failure)
        """
        try:
            message = messaging.MulticastMessage(
                notification=messaging.Notification(title=title, body=body),
                data=data or {},
                tokens=device_tokens,
                apns=messaging.APNSConfig(
                    headers={
                        "apns-priority": "10",
                    },
                ),
                android=messaging.AndroidConfig(
                    priority="high",
                ),
            )

            response = messaging.send_multicast(message)
            logger.info(
                f"Notificações em lote: {response.success_count} sucesso, {response.failure_count} falha"
            )

            return {
                "success": response.success_count,
                "failure": response.failure_count,
                "responses": response.responses,
            }
        except Exception as e:
            logger.error(f"Erro ao enviar notificações em lote: {e}")
            return {"success": 0, "failure": len(device_tokens), "responses": []}

    def is_initialized(self) -> bool:
        """Verifica se Firebase está inicializado"""
        try:
            firebase_admin.get_app()
            return True
        except ValueError:
            return False
