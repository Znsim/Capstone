from fastapi import APIRouter, Depends
from fastapi.responses import HTMLResponse
from core.database import provide_session
from fastapi import HTTPException, status
from .schema import (UserDTO,LoginDTO)
from core.dependencies import hash_password
from .crud import UserCRUD
from core.dependencies import TOKEN_TYPE
from core.dependencies import (send_verification_email, verify_email,get_email_by_token)

router = APIRouter(
    prefix="/users",
    tags=["User"],
)

@router.post("/join")
async def Join(payload:UserDTO,db=Depends(provide_session)):
    crud = UserCRUD(session=db)
    payload.password = hash_password(payload.password)
    user = await crud.create_user(payload=payload)
    send_verification_email(user.email)
    return user

@router.get("/login")
async def Login(email:str,password:str,db=Depends(provide_session)):
    crud = UserCRUD(session=db)
    print(email)
    print(password)
    token = await crud.Login(gemail=email, password=password) 
    print(token)
    if token:
        return {TOKEN_TYPE+" "+token}

@router.get("/emailCheck")
async def EmailCheck(email:str,db=Depends(provide_session)):
    crud = UserCRUD(session=db)
    if await crud.get_user_by_email(gemail=email):  
        return True
    else:
        return False

@router.get("/verify-email", response_class=HTMLResponse)
async def AuthCheck(token: str, db=Depends(provide_session)):
    crud = UserCRUD(session=db)
    if verify_email(token=token):
        email = get_email_by_token(token=token)
        if await crud.user_auth_change(gemail=email):  
            return """
            <html>
                <head><title>Success</title></head>
                <body>
                    <h1>Verification Successful</h1>
                    <p>Your email has been successfully verified!</p>
                </body>
            </html>
            """
        else:
            return """
            <html>
                <head><title>Failure</title></head>
                <body>
                    <h1>Verification Failed</h1>
                    <p>There was an error during verification.</p>
                </body>
            </html>
            """
    else:
        return """
        <html>
            <head><title>Error</title></head>
            <body>
                <h1>Invalid Token</h1>
                <p>The verification token is invalid or expired.</p>
            </body>
        </html>
        """

@router.get("/nickCheck")
async def NickCheck(nick:str,db=Depends(provide_session)):
    crud = UserCRUD(session=db)
    if await crud.get_user_by_nick(nickname=nick):  
        return True
    else:
        return False