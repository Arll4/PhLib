"""
Client utilities: Lua saved vars to JSON conversion.
"""
import json
import os
import re
from pathlib import Path
from dotenv import load_dotenv
from slpp import slpp as lua_parser

_CLIENT_DIR = Path(__file__).resolve().parent

load_dotenv(_CLIENT_DIR / ".env")
def get_savedvars_path() -> str:
    path = os.environ.get("WOW_SAVEDVARS_PATH", "").strip().strip("\ufeff")
    if not path:
        raise ValueError("WOW_SAVEDVARS_PATH is not set. Set it in .env.")
    return path

def _load_lua_table_string(path: str) -> str:
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()
    match = re.match(r"^\s*\w+\s*=\s*", content)
    if match:
        content = content[match.end() :]
    return content.strip()

def _to_json_serializable(obj):
    if isinstance(obj, dict):
        return {str(k): _to_json_serializable(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_to_json_serializable(v) for v in obj]
    return obj


def lua_table_to_json(path: str | None = None, *, indent: int | None = None) -> str:
    path = path or get_savedvars_path()
    lua_text = _load_lua_table_string(path)
    data = lua_parser.decode(lua_text)
    if data is None:
        raise ValueError("Lua parse returned None (invalid or empty table?).")
    clean = _to_json_serializable(data)
    return json.dumps(clean, indent=indent, ensure_ascii=False)
