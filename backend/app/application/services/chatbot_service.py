import os
from openai import OpenAI


class ChatbotService:
    def __init__(self):
        self.client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

    def ask(self, message: str, user_context: dict | None = None) -> str:
        system_prompt = """
You are an AI customer support assistant for an EV Charging Station app.
Help users with:
- finding compatible charging stations
- reservation problems
- payment questions
- charging session questions
- general app usage

Do not invent database data. If required data is missing, ask the user to provide it or say it is not available.
Answer clearly and briefly.
"""

        context_text = f"User context: {user_context}" if user_context else "No user context provided."

        response = self.client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "system", "content": context_text},
                {"role": "user", "content": message},
            ],
            temperature=0.3,
        )

        return response.choices[0].message.content