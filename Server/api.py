import json
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

import db

app = FastAPI(title="PhLib Server")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class SaveDataIn(BaseModel):
    data: str


@app.post("/save-data")
async def save_data(body: SaveDataIn) -> dict:
    """Receive PhLib saved vars JSON and save to SQLite."""
    if not body.data or not body.data.strip():
        raise HTTPException(status_code=400, detail="data must be non-empty")
    raw = body.data.strip()
    if not raw.startswith("{"):
        raise HTTPException(status_code=400, detail="Payload must be JSON object")
    try:
        savedvars = json.loads(raw)
    except json.JSONDecodeError as err:
        raise HTTPException(status_code=400, detail=f"Invalid JSON: {err}")
    if not isinstance(savedvars, dict):
        raise HTTPException(status_code=400, detail="Payload must be a JSON object")
    db.save_savedvars(savedvars)
    return {"ok": True, "length": len(raw)}
