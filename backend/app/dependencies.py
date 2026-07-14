from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.security import decode_token
from app.services.auth_session_service import is_session_active

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def get_current_token_payload(token: str = Depends(oauth2_scheme)):
    try:
        return decode_token(token)
    except JWTError:
        return None


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    try:
        payload = decode_token(token)
        user_id = payload.get("sub")
        if not user_id:
            return None

        jti = payload.get("jti")
        if jti and not is_session_active(str(user_id), str(jti)):
            return None

        return db.query(User).filter(User.id == user_id).first()
    except JWTError:
        return None
