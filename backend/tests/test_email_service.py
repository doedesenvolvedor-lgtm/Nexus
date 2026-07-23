"""Testes unitários para o serviço de email."""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

import pytest
from unittest.mock import patch, MagicMock

# Configurar variáveis de ambiente para teste
os.environ["SMTP_SERVER"] = "smtp.test.com"
os.environ["SMTP_PORT"] = "587"
os.environ["SMTP_USER"] = "test@test.com"
os.environ["SMTP_PASSWORD"] = "test-password"
os.environ["SMTP_SECURITY"] = "starttls"
os.environ["SMTP_FROM_EMAIL"] = "noreply@nexus.test"
os.environ["SMTP_FROM_NAME"] = "Nexus Test"
os.environ["FRONTEND_URL"] = "http://localhost:3000"
os.environ["FRONTEND_RESET_PASSWORD_URL"] = "http://localhost:3000/reset-password"
os.environ["APP_NAME"] = "Nexus Test"

from app.services.email_service import EmailService, EMAIL_PATTERN


class TestEmailValidation:
    def test_valid_email(self):
        """Testa validação de email válido."""
        assert EMAIL_PATTERN.match("user@example.com") is not None
        assert EMAIL_PATTERN.match("user.name+tag@example.co.uk") is not None
        assert EMAIL_PATTERN.match("user_name@sub.example.com") is not None

    def test_invalid_email(self):
        """Testa validação de email inválido."""
        assert EMAIL_PATTERN.match("invalid-email") is None
        assert EMAIL_PATTERN.match("@example.com") is None
        assert EMAIL_PATTERN.match("user@") is None
        assert EMAIL_PATTERN.match("user@.com") is None

    def test_is_valid_email_method(self):
        """Testa método is_valid_email."""
        service = EmailService()
        assert service.is_valid_email("user@example.com") is True
        assert service.is_valid_email("invalid") is False
        assert service.is_valid_email("") is False

    def test_email_too_long(self):
        """Testa email muito longo."""
        service = EmailService()
        long_email = "a" * 250 + "@example.com"
        assert service.is_valid_email(long_email) is False


class TestEmailService:
    def setup_method(self):
        self.service = EmailService()

    def test_enabled_with_config(self):
        """Testa se serviço está habilitado com configuração."""
        assert self.service.enabled is True

    def test_disabled_without_config(self):
        """Testa se serviço está desabilitado sem configuração."""
        service = EmailService()
        service.server = None
        service.user = None
        service.password = None
        assert service.enabled is False

    @patch("smtplib.SMTP")
    def test_send_email_success(self, mock_smtp):
        """Testa envio de email com sucesso."""
        mock_client = MagicMock()
        mock_smtp.return_value.__enter__.return_value = mock_client
        
        result = self.service.send_email(
            to_email="user@example.com",
            subject="Test Subject",
            body="Test Body",
        )
        
        assert result is True
        mock_client.send_message.assert_called_once()

    @patch("smtplib.SMTP")
    def test_send_email_with_html(self, mock_smtp):
        """Testa envio de email com conteúdo HTML."""
        mock_client = MagicMock()
        mock_smtp.return_value.__enter__.return_value = mock_client
        
        result = self.service.send_email(
            to_email="user@example.com",
            subject="Test",
            body="Plain text",
            html_body="<h1>HTML</h1>",
        )
        
        assert result is True

    @patch("smtplib.SMTP")
    def test_send_email_retry_on_failure(self, mock_smtp):
        """Testa retry automático em caso de falha."""
        mock_client = MagicMock()
        mock_client.send_message.side_effect = [
            Exception("Temporary error"),
            None,  # Success on second try
        ]
        mock_smtp.return_value.__enter__.return_value = mock_client
        
        result = self.service.send_email(
            to_email="user@example.com",
            subject="Test",
            body="Test",
        )
        
        assert result is True
        assert mock_client.send_message.call_count == 2

    @patch("smtplib.SMTP")
    def test_send_email_final_failure(self, mock_smtp):
        """Testa falha final após todas as tentativas."""
        mock_client = MagicMock()
        mock_client.send_message.side_effect = Exception("Persistent error")
        mock_smtp.return_value.__enter__.return_value = mock_client
        
        result = self.service.send_email(
            to_email="user@example.com",
            subject="Test",
            body="Test",
        )
        
        assert result is False

    def test_send_welcome_email(self):
        """Testa envio de email de boas-vindas."""
        with patch.object(self.service, 'send_email', return_value=True) as mock_send:
            result = self.service.send_welcome_email(
                to_email="user@example.com",
                username="TestUser",
            )
            assert result is True
            mock_send.assert_called_once()
            args = mock_send.call_args[1]
            assert "Bem-vindo" in args["subject"]
            assert "TestUser" in args["body"]

    def test_send_password_reset_email(self):
        """Testa envio de email de reset de senha."""
        with patch.object(self.service, 'send_email', return_value=True) as mock_send:
            result = self.service.send_password_reset_email(
                to_email="user@example.com",
                reset_token="test-token-123",
            )
            assert result is True
            mock_send.assert_called_once()
            args = mock_send.call_args[1]
            assert "redefinição" in args["subject"]
            assert "test-token-123" in args["body"]

    def test_send_payment_receipt_email(self):
        """Testa envio de recibo de pagamento."""
        with patch.object(self.service, 'send_email', return_value=True) as mock_send:
            result = self.service.send_payment_receipt_email(
                to_email="user@example.com",
                plan="Premium",
                amount=39.90,
                payment_id="pay-123",
                status="approved",
            )
            assert result is True
            args = mock_send.call_args[1]
            assert "recibo" in args["subject"].lower()
            assert "Premium" in args["body"]
            assert "39.90" in args["body"]
