from fastapi import APIRouter, Depends, HTTPException

from app.schemas.chatbot import ChatbotMessageRequest, ChatbotMessageResponse
from app.application.services.chatbot_service import ChatbotService
from app.core.dependencies import get_current_user, AuthenticatedUser

router = APIRouter()


def get_chatbot_service():
    return ChatbotService()


@router.post("/message", response_model=ChatbotMessageResponse)
def send_message_to_chatbot(
    request: ChatbotMessageRequest,
    current_user: AuthenticatedUser = Depends(get_current_user),
    service: ChatbotService = Depends(get_chatbot_service),
):
    try:
        user_context = {
            "user_id": current_user.id,
            "role": current_user.role,
        }

        reply = service.ask(request.message, user_context)

        return ChatbotMessageResponse(reply=reply)

    except Exception:
        raise HTTPException(status_code=500, detail="Chatbot service unavailable")