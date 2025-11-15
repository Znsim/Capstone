from fastapi import APIRouter, Depends
from fastapi.responses import HTMLResponse
from core.database import provide_session
from fastapi import HTTPException, status
from .schema import UserDTO,LoginDTO
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
    user_data = await crud.create_user(payload=payload)
    send_verification_email(payload.email)
    return user_data

@router.post("/login")
async def Login(payload: LoginDTO, db=Depends(provide_session)):
    crud = UserCRUD(session=db)
    print(payload.email)
    print(payload.password)
    token = await crud.login(email=payload.email, password=payload.password) 
    print(token)
    if token:
        # 사용자 정보 별도 조회
        user_info = await crud.get_user_by_email(email=payload.email)
        # 사용자 정보
        return {TOKEN_TYPE + " " + token: user_info}

@router.get("/emailCheck")
async def EmailCheck(email:str,db=Depends(provide_session)):
    crud = UserCRUD(session=db)
    if await crud.get_user_by_email(email=email):  
        return True
    else:
        return False

@router.get("/verify-email", response_class=HTMLResponse)
async def AuthCheck(token: str, db=Depends(provide_session)):
    crud = UserCRUD(session=db)
    if verify_email(token=token):
        email = get_email_by_token(token=token)
        if await crud.authenticate_user(email=email):  
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

@router.get("/nameCheck")
async def NameCheck(name:str,db=Depends(provide_session)):
    crud = UserCRUD(session=db)
    if await crud.get_user_by_username(username=name):  
        return True
    else:
        return False