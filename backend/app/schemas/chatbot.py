from pydantic import BaseModel


class ChatbotMessageRequest(BaseModel):
    message: str


class ChatbotMessageResponse(BaseModel):
    reply: str