#!/usr/bin/env python3
"""
Script para criar uma conta admin com acesso premium grátis no Nexus

Uso:
    python create_admin_premium_account.py
    
O script vai solicitar:
    - Email para login
    - Senha
    - Username (opcional)
    - Duração do acesso premium (dias) - padrão: 365 dias (1 ano)
"""

import os
import sys
import uuid
from datetime import datetime, timezone, timedelta
from pathlib import Path
from getpass import getpass

# Adicionar backend ao path
sys.path.insert(0, str(Path(__file__).parent / "backend"))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.models import User, Subscription
from app.security import hash_password


def get_database_url() -> str:
    """Obtém URL do banco de dados a partir de variável de ambiente ou input do usuário."""
    db_url = os.getenv("DATABASE_URL")
    
    if db_url:
        print(f"✅ DATABASE_URL encontrada: {db_url[:50]}...")
        return db_url
    
    print("\n⚠️  DATABASE_URL não encontrada em variáveis de ambiente")
    print("\nDigite a URL de conexão ao PostgreSQL:")
    print("Exemplo: postgresql://user:password@localhost:5432/nexus")
    db_url = input("URL: ").strip()
    
    if not db_url:
        print("❌ URL do banco de dados é obrigatória!")
        sys.exit(1)
    
    return db_url


def validate_email(email: str) -> bool:
    """Valida formato de email."""
    import re
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None


def validate_password(password: str) -> bool:
    """Valida força da senha (12+ chars, maiúscula, minúscula, dígito, especial)."""
    import re
    
    if len(password) < 12:
        print("❌ Senha deve ter pelo menos 12 caracteres")
        return False
    
    if not re.search(r'[A-Z]', password):
        print("❌ Senha deve conter pelo menos 1 maiúscula")
        return False
    
    if not re.search(r'[a-z]', password):
        print("❌ Senha deve conter pelo menos 1 minúscula")
        return False
    
    if not re.search(r'[0-9]', password):
        print("❌ Senha deve conter pelo menos 1 dígito")
        return False
    
    if not re.search(r'[@$!%*?&]', password):
        print("❌ Senha deve conter pelo menos 1 caractere especial (@$!%*?&)")
        return False
    
    return True


def create_admin_account():
    """Cria a conta admin premium."""
    
    print("\n" + "="*60)
    print("🔐 CRIAR CONTA ADMIN PREMIUM GRÁTIS - NEXUS")
    print("="*60)
    
    # Obter URL do banco
    db_url = get_database_url()
    
    # Conectar ao banco
    try:
        engine = create_engine(db_url)
        SessionLocal = sessionmaker(bind=engine)
        db = SessionLocal()
        print("✅ Conectado ao banco de dados")
    except Exception as e:
        print(f"❌ Erro ao conectar ao banco: {e}")
        sys.exit(1)
    
    # Solicitar dados da conta
    print("\n📝 DADOS DA CONTA:")
    print("-" * 60)
    
    # Email
    while True:
        email = input("Email: ").strip()
        if not email:
            print("❌ Email é obrigatório")
            continue
        if not validate_email(email):
            print("❌ Email inválido")
            continue
        
        # Verificar se já existe
        existing = db.query(User).filter(User.email == email).first()
        if existing:
            print("❌ Email já cadastrado no sistema")
            continue
        
        break
    
    # Username
    username = input("Username (opcional, Enter para pular): ").strip()
    if username:
        existing = db.query(User).filter(User.username == username).first()
        if existing:
            print("❌ Username já existe")
            username = input("Digite outro username: ").strip()
    
    # Senha
    while True:
        password = getpass("Senha: ")
        if not validate_password(password):
            continue
        
        password_confirm = getpass("Confirme a senha: ")
        if password != password_confirm:
            print("❌ Senhas não conferem")
            continue
        
        break
    
    # Duração do premium
    duration = input("Duração do acesso premium em dias (padrão 365): ").strip()
    try:
        duration = int(duration) if duration else 365
    except ValueError:
        duration = 365
    
    print("\n⏳ RESUMO DA CONTA:")
    print("-" * 60)
    print(f"Email: {email}")
    print(f"Username: {username or '(não definido)'}")
    print(f"Role: admin")
    print(f"is_premium: True")
    print(f"Acesso Premium por: {duration} dias")
    print(f"Plano: Premium (sem pagamento)")
    
    confirm = input("\nDeseja criar esta conta? (s/n): ").strip().lower()
    if confirm != 's':
        print("❌ Operação cancelada")
        db.close()
        sys.exit(0)
    
    # Criar usuário
    try:
        new_user = User(
            id=uuid.uuid4(),
            email=email,
            username=username if username else None,
            hashed_password=hash_password(password),
            is_premium=True,  # Premium desde o início
            role="admin",  # Definir como admin
        )
        
        db.add(new_user)
        db.flush()
        
        # Criar subscription premium
        premium_ends = datetime.now(timezone.utc) + timedelta(days=duration)
        
        subscription = Subscription(
            id=uuid.uuid4(),
            user_id=new_user.id,
            plan="Premium",
            plan_type="Premium",
            status="active",
            trial_started_at=None,
            trial_ends_at=None,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc),
        )
        
        db.add(subscription)
        db.commit()
        
        print("\n" + "="*60)
        print("✅ CONTA CRIADA COM SUCESSO!")
        print("="*60)
        print(f"\n📋 DADOS DE LOGIN:")
        print(f"Email: {email}")
        print(f"Senha: ••••••••• (você informou)")
        print(f"\n👤 INFORMAÇÕES DA CONTA:")
        print(f"User ID: {new_user.id}")
        print(f"Role: {new_user.role}")
        print(f"Premium: Sim ✅")
        print(f"Acesso até: {premium_ends.strftime('%d/%m/%Y %H:%M:%S')}")
        print(f"\n💡 PRÓXIMOS PASSOS:")
        print(f"1. Abra o app mobile Nexus")
        print(f"2. Login com email: {email}")
        print(f"3. Você terá acesso admin e premium imediatamente")
        print("\n" + "="*60)
        
    except Exception as e:
        db.rollback()
        print(f"\n❌ Erro ao criar conta: {e}")
        sys.exit(1)
    finally:
        db.close()


if __name__ == "__main__":
    try:
        create_admin_account()
    except KeyboardInterrupt:
        print("\n\n❌ Operação cancelada pelo usuário")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Erro inesperado: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
