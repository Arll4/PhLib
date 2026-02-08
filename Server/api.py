import asyncio
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

import discord_bot

app = FastAPI(title="PhLib Server")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class MessageIn(BaseModel):
    message: str

@app.get("/")
async def root():
    return {"message": "Hello, World!"}


@app.post("/message")
async def post_message(data: MessageIn):
    """Receive data from the client. Optionally forwarded to Discord for display."""
    if not data.message or not data.message.strip():
        raise HTTPException(status_code=400, detail="message must be non-empty")

    future = discord_bot.schedule_send(data.message.strip())
    if future:
        try:
            await asyncio.wrap_future(future)
        except Exception as e:
            raise HTTPException(status_code=503, detail=f"Discord send failed: {e}")

    return {"ok": True, "received": data.message}

@app.post("/save-profession")
async def save_profession(data):
    print(data)
    return {"ok": True, "saved": data}