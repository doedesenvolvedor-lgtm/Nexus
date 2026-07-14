import logging
import re
import smtplib
import time
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import Iterable, Optional

from app.config import (
    APP_NAME,
    FRONTEND_RESET_PASSWORD_URL,
    FRONTEND_URL,
    SMTP_FROM_EMAIL,
    SMTP_FROM_NAME,
    SMTP_PASSWORD,
    SMTP_PORT,
    SMTP_RETRY_ATTEMPTS,
    SMTP_RETRY_DELAY,
    SMTP_SECURITY,
    SMTP_SERVER,
    SMTP_USER,
)

logger = logging.getLogger(__name__)

# Padrão de validação de e-mail
EMAIL_PATTERN = re.compile(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')


class EmailService:
    def __init__(self) -> None:
        self.server = SMTP_SERVER
        self.port = SMTP_PORT
        self.user = SMTP_USER
        self.password = SMTP_PASSWORD
        self.security = SMTP_SECURITY
        self.from_email = SMTP_FROM_EMAIL
        self.from_name = SMTP_FROM_NAME
        self.retry_attempts = SMTP_RETRY_ATTEMPTS
        self.retry_delay = SMTP_RETRY_DELAY

    @property
    def enabled(self) -> bool:
        return bool(self.server and self.user and self.password)

    @staticmethod
    def is_valid_email(email: str) -> bool:
        """Valida o formato de um endereço de e-mail."""
        if not email or len(email) > 254:
            return False
        return bool(EMAIL_PATTERN.match(email))

    def _connect(self) -> smtplib.SMTP:
        """Conecta ao servidor SMTP com retry automático."""
        security = (self.security or "starttls").strip().lower()
        attempt = 0
        last_error = None

        while attempt < self.retry_attempts:
            try:
                if security in {"ssl", "tls"}:
                    logger.debug(f"Conectando ao SMTP {self.server}:{self.port} com SSL")
                    client = smtplib.SMTP_SSL(self.server, self.port, timeout=10)
                else:
                    logger.debug(f"Conectando ao SMTP {self.server}:{self.port} com STARTTLS")
                    client = smtplib.SMTP(self.server, self.port, timeout=10)
                    if security == "starttls":
                        client.starttls()

                client.login(self.user, self.password)
                logger.debug(f"Autenticado com sucesso em {self.server}")
                return client

            except smtplib.SMTPException as e:
                last_error = e
                attempt += 1
                if attempt < self.retry_attempts:
                    wait_time = self.retry_delay * attempt
                    logger.warning(
                        f"Erro SMTP (tentativa {attempt}/{self.retry_attempts}): {str(e)}. "
                        f"Tentando novamente em {wait_time}s..."
                    )
                    time.sleep(wait_time)
            except Exception as e:
                last_error = e
                attempt += 1
                if attempt < self.retry_attempts:
                    wait_time = self.retry_delay * attempt
                    logger.warning(
                        f"Erro de conexão (tentativa {attempt}/{self.retry_attempts}): {str(e)}. "
                        f"Tentando novamente em {wait_time}s..."
                    )
                    time.sleep(wait_time)

        logger.error(f"Falha ao conectar ao SMTP após {self.retry_attempts} tentativas: {str(last_error)}")
        raise ConnectionError(f"Não foi possível conectar ao servidor SMTP: {str(last_error)}")

    def send_email(
        self,
        to_email: str,
        subject: str,
        body: str,
        html_body: Optional[str] = None,
    ) -> bool:
        """Envia um e-mail com retry automático e suporte a HTML."""
        if not self.enabled:
            logger.warning("SMTP não configurado. E-mail não será enviado para %s", to_email)
            return False

        # Validar e-mail
        if not self.is_valid_email(to_email):
            logger.error(f"E-mail inválido: {to_email}")
            return False

        logger.info(f"Preparando envio de e-mail para {to_email} com assunto: {subject}")

        # Criar mensagem MIME
        message = MIMEMultipart("alternative")
        message["Subject"] = subject
        message["From"] = f"{self.from_name} <{self.from_email}>"
        message["To"] = to_email

        # Adicionar versão de texto plano
        part1 = MIMEText(body, "plain", _charset="utf-8")
        message.attach(part1)

        # Adicionar versão HTML se fornecida
        if html_body:
            part2 = MIMEText(html_body, "html", _charset="utf-8")
            message.attach(part2)

        attempt = 0
        while attempt < self.retry_attempts:
            try:
                with self._connect() as smtp:
                    smtp.send_message(message)
                logger.info(f"E-mail enviado com sucesso para {to_email}")
                return True

            except smtplib.SMTPException as e:
                attempt += 1
                if attempt < self.retry_attempts:
                    wait_time = self.retry_delay * attempt
                    logger.warning(
                        f"Erro ao enviar e-mail para {to_email} "
                        f"(tentativa {attempt}/{self.retry_attempts}): {str(e)}. "
                        f"Tentando novamente em {wait_time}s..."
                    )
                    time.sleep(wait_time)
                else:
                    logger.error(
                        f"Falha ao enviar e-mail para {to_email} "
                        f"após {self.retry_attempts} tentativas: {str(e)}"
                    )

            except Exception as e:
                attempt += 1
                if attempt < self.retry_attempts:
                    wait_time = self.retry_delay * attempt
                    logger.warning(
                        f"Erro inesperado ao enviar e-mail para {to_email} "
                        f"(tentativa {attempt}/{self.retry_attempts}): {str(e)}. "
                        f"Tentando novamente em {wait_time}s..."
                    )
                    time.sleep(wait_time)
                else:
                    logger.error(
                        f"Falha ao enviar e-mail para {to_email} "
                        f"após {self.retry_attempts} tentativas: {str(e)}"
                    )

        return False

    def send_bulk_email(
        self,
        recipients: Iterable[str],
        subject: str,
        body: str,
        html_body: Optional[str] = None,
    ) -> int:
        """Envia e-mail para múltiplos destinatários."""
        logger.info(f"Iniciando envio em massa para {len(list(recipients))} destinatários")
        sent = 0
        failed = 0
        recipients_list = list(recipients)

        for idx, recipient in enumerate(recipients_list, 1):
            if self.send_email(recipient, subject, body, html_body):
                sent += 1
            else:
                failed += 1
            logger.info(f"Progresso: {idx}/{len(recipients_list)} e-mails processados")

        logger.info(
            f"Envio em massa concluído: {sent} enviados, {failed} falhados "
            f"(total: {len(recipients_list)})"
        )
        return sent

    def send_welcome_email(self, to_email: str, username: str | None) -> bool:
        """Envia e-mail de boas-vindas."""
        display_name = username or "usuário"
        subject = f"Bem-vindo ao {APP_NAME}!"
        body = (
            f"Olá, {display_name}!\n\n"
            f"Sua conta foi criada com sucesso no {APP_NAME}.\n"
            "Agora você já pode acessar a plataforma e aproveitar o conteúdo.\n\n"
            "Se você não reconhece este cadastro, responda este e-mail.\n\n"
            f"Equipe {APP_NAME}"
        )
        html_body = f"""
        <html>
            <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                    <h1 style="color: #2563eb; text-align: center;">Bem-vindo ao {APP_NAME}!</h1>
                    <p>Olá, <strong>{display_name}</strong>!</p>
                    <p>Sua conta foi criada com sucesso no <strong>{APP_NAME}</strong>.</p>
                    <p>Agora você já pode acessar a plataforma e aproveitar todo o conteúdo exclusivo.</p>
                    <a href="{FRONTEND_URL}" style="display: inline-block; padding: 12px 30px; background-color: #2563eb; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0;">Acessar Plataforma</a>
                    <p style="margin-top: 30px; border-top: 1px solid #ddd; padding-top: 20px; font-size: 12px; color: #666;">
                        Se você não reconhece este cadastro, responda este e-mail imediatamente.
                    </p>
                    <p style="font-size: 12px; color: #999;">
                        Equipe {APP_NAME}<br>
                        {FRONTEND_URL}
                    </p>
                </div>
            </body>
        </html>
        """
        return self.send_email(
            to_email=to_email,
            subject=subject,
            body=body,
            html_body=html_body,
        )

    def send_password_reset_email(self, to_email: str, reset_token: str) -> bool:
        """Envia e-mail com link de recuperação de senha."""
        reset_link = f"{FRONTEND_RESET_PASSWORD_URL}?token={reset_token}"
        subject = f"{APP_NAME}: redefinição de senha"
        body = (
            "Recebemos uma solicitação para redefinir sua senha.\n\n"
            f"Use este link para continuar: {reset_link}\n\n"
            "Este link expira em 30 minutos.\n"
            "Se você não solicitou a alteração, ignore este e-mail.\n\n"
            f"Equipe {APP_NAME}"
        )
        html_body = f"""
        <html>
            <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                    <h1 style="color: #2563eb; text-align: center;">Redefinir Senha</h1>
                    <p>Recebemos uma solicitação para redefinir sua senha no <strong>{APP_NAME}</strong>.</p>
                    <p>Clique no botão abaixo para continuar:</p>
                    <a href="{reset_link}" style="display: inline-block; padding: 12px 30px; background-color: #2563eb; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; font-weight: bold;">Redefinir Senha</a>
                    <p style="color: #e74c3c; font-weight: bold;">⏱️ Este link expira em 30 minutos.</p>
                    <p style="margin-top: 30px; border-top: 1px solid #ddd; padding-top: 20px;">
                        <strong>Não reconhece este pedido?</strong><br>
                        Se você não solicitou a alteração de senha, ignore este e-mail. Sua senha não será alterada.
                    </p>
                    <p style="font-size: 12px; color: #999;">
                        Equipe {APP_NAME}<br>
                        {FRONTEND_URL}
                    </p>
                </div>
            </body>
        </html>
        """
        return self.send_email(
            to_email=to_email,
            subject=subject,
            body=body,
            html_body=html_body,
        )

    def send_payment_receipt_email(
        self,
        to_email: str,
        plan: str,
        amount: float,
        payment_id: str,
        status: str,
    ) -> bool:
        """Envia recibo de pagamento."""
        subject = f"{APP_NAME}: recibo de pagamento"
        body = (
            "Pagamento confirmado no Nexus.\n\n"
            f"Plano: {plan}\n"
            f"Valor: R$ {amount:.2f}\n"
            f"Status: {status}\n"
            f"ID do pagamento: {payment_id}\n\n"
            "Guarde este e-mail como comprovante.\n\n"
            f"Equipe {APP_NAME}"
        )
        status_color = "#27ae60" if status.lower() == "approved" else "#e74c3c"
        status_label = "Aprovado" if status.lower() == "approved" else status
        html_body = f"""
        <html>
            <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                    <h1 style="color: #2563eb; text-align: center;">Recibo de Pagamento</h1>
                    <div style="background-color: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0;">
                        <p style="margin: 10px 0;"><strong>Plano:</strong> {plan}</p>
                        <p style="margin: 10px 0;"><strong>Valor:</strong> R$ {amount:.2f}</p>
                        <p style="margin: 10px 0;">
                            <strong>Status:</strong>
                            <span style="display: inline-block; padding: 5px 10px; background-color: {status_color}; color: white; border-radius: 3px;">
                                {status_label}
                            </span>
                        </p>
                        <p style="margin: 10px 0; font-size: 12px; color: #666;"><strong>ID do Pagamento:</strong> {payment_id}</p>
                    </div>
                    <p style="margin-top: 20px; padding: 15px; background-color: #e8f4f8; border-left: 4px solid #2563eb;">
                        ✅ Guarde este e-mail como comprovante de pagamento.
                    </p>
                    <p style="margin-top: 30px; border-top: 1px solid #ddd; padding-top: 20px; font-size: 12px; color: #999;">
                        Equipe {APP_NAME}<br>
                        {FRONTEND_URL}
                    </p>
                </div>
            </body>
        </html>
        """
        return self.send_email(
            to_email=to_email,
            subject=subject,
            body=body,
            html_body=html_body,
        )

    def send_admin_announcement_email(self, to_email: str, title: str, message: str) -> bool:
        """Envia comunicado oficial do administrador."""
        subject = f"{APP_NAME}: {title}"
        body = (
            f"{message}\n\n"
            "Esta é uma comunicação oficial da equipe Nexus."
        )
        html_body = f"""
        <html>
            <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                    <div style="background-color: #f39c12; color: white; padding: 15px; border-radius: 5px; text-align: center; margin-bottom: 20px;">
                        <h2 style="margin: 0;">📢 Comunicado Oficial</h2>
                    </div>
                    <h1 style="color: #2563eb; text-align: center;">{title}</h1>
                    <div style="background-color: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #f39c12;">
                        <p>{message}</p>
                    </div>
                    <p style="margin-top: 30px; border-top: 1px solid #ddd; padding-top: 20px; font-size: 12px; color: #999;">
                        Esta é uma comunicação oficial da equipe {APP_NAME}.<br>
                        {FRONTEND_URL}
                    </p>
                </div>
            </body>
        </html>
        """
        return self.send_email(
            to_email=to_email,
            subject=subject,
            body=body,
            html_body=html_body,
        )


email_service = EmailService()


def get_email_service() -> EmailService:
    return email_service
