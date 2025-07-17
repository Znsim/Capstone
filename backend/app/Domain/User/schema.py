from pydantic import BaseModel
from typing import Optional
from datetime import date

class UserDTO(BaseModel):
    email: str
    username: str
    password: str
    

class LoginDTO(BaseModel):
    email:str
    password:str