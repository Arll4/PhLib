"""
SQLite storage for PhLib saved vars (realms, characters, professions, recipes).
"""
import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).resolve().parent / "wow.db"


def _get_conn():
    return sqlite3.connect(DB_PATH)


def init_db():
    """Create tables if they don't exist."""
    conn = _get_conn()
    try:
        conn.executescript("""
            CREATE TABLE IF NOT EXISTS realms (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT UNIQUE NOT NULL
            );
            CREATE TABLE IF NOT EXISTS characters (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                realm_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                UNIQUE(realm_id, name),
                FOREIGN KEY (realm_id) REFERENCES realms(id)
            );
            CREATE TABLE IF NOT EXISTS professions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                character_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                rank INTEGER,
                max_rank INTEGER,
                captured INTEGER,
                FOREIGN KEY (character_id) REFERENCES characters(id)
            );
            CREATE TABLE IF NOT EXISTS recipes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                profession_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                item_id INTEGER,
                rarity TEXT,
                difficulty TEXT,
                quality INTEGER,
                FOREIGN KEY (profession_id) REFERENCES professions(id)
            );
            CREATE INDEX IF NOT EXISTS idx_recipes_name ON recipes(name);
            CREATE INDEX IF NOT EXISTS idx_characters_realm ON characters(realm_id);
            CREATE INDEX IF NOT EXISTS idx_professions_character ON professions(character_id);
        """)
        conn.commit()
    finally:
        conn.close()


def save_savedvars(data: dict) -> None:
    """
    Parse PhLib saved vars JSON and replace DB content.
    Skips '_config' and other non-realm keys. Structure: realm -> character -> profession -> { rank, recipes, ... }.
    """
    if not data or not isinstance(data, dict):
        return
    init_db()
    conn = _get_conn()
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM recipes")
        cur.execute("DELETE FROM professions")
        cur.execute("DELETE FROM characters")
        cur.execute("DELETE FROM realms")
        for realm_name, realm_data in data.items():
            if realm_name == "_config" or not isinstance(realm_data, dict):
                continue
            cur.execute("INSERT INTO realms (name) VALUES (?)", (realm_name,))
            realm_id = cur.lastrowid
            for char_name, char_data in realm_data.items():
                if not isinstance(char_data, dict):
                    continue
                cur.execute("INSERT INTO characters (realm_id, name) VALUES (?, ?)", (realm_id, char_name))
                char_id = cur.lastrowid
                for prof_name, prof_data in char_data.items():
                    if not isinstance(prof_data, dict):
                        continue
                    rank = prof_data.get("rank")
                    max_rank = prof_data.get("maxRank")
                    captured = prof_data.get("captured")
                    recipes = prof_data.get("recipes")
                    if isinstance(recipes, dict):
                        recipe_list = list(recipes.values())
                    elif isinstance(recipes, list):
                        recipe_list = recipes
                    else:
                        recipe_list = []
                    cur.execute(
                        "INSERT INTO professions (character_id, name, rank, max_rank, captured) VALUES (?, ?, ?, ?, ?)",
                        (char_id, prof_name, rank, max_rank, captured),
                    )
                    prof_id = cur.lastrowid
                    for r in recipe_list:
                        if not isinstance(r, dict):
                            continue
                        name = r.get("name")
                        if not name:
                            continue
                        cur.execute(
                            "INSERT INTO recipes (profession_id, name, item_id, rarity, difficulty, quality) VALUES (?, ?, ?, ?, ?, ?)",
                            (
                                prof_id,
                                name,
                                r.get("itemID"),
                                r.get("rarity"),
                                r.get("difficulty"),
                                r.get("quality"),
                            ),
                        )
        conn.commit()
    finally:
        conn.close()


def get_all_characters() -> list[tuple[str, str]]:
    """Return list of (realm_name, character_name)."""
    conn = _get_conn()
    try:
        cur = conn.execute(
            "SELECT r.name, c.name FROM characters c JOIN realms r ON c.realm_id = r.id ORDER BY r.name, c.name"
        )
        return cur.fetchall()
    finally:
        conn.close()


def get_character_professions(realm: str, character: str) -> list[dict]:
    """Return list of { name, rank, max_rank } for the given realm+character."""
    conn = _get_conn()
    try:
        cur = conn.execute(
            """SELECT p.name, p.rank, p.max_rank
               FROM professions p
               JOIN characters c ON p.character_id = c.id
               JOIN realms r ON c.realm_id = r.id
               WHERE r.name = ? AND c.name = ? ORDER BY p.name""",
            (realm, character),
        )
        return [{"name": row[0], "rank": row[1], "max_rank": row[2]} for row in cur.fetchall()]
    finally:
        conn.close()


def get_professions_by_character_name(character_name: str) -> list[tuple[str, str, list[dict]]]:
    """
    Find all (realm, character) with this name and return (realm, character, list of profession dicts).
    """
    conn = _get_conn()
    try:
        cur = conn.execute(
            """SELECT r.name, c.name, c.id FROM characters c JOIN realms r ON c.realm_id = r.id WHERE c.name = ?""",
            (character_name,),
        )
        rows = cur.fetchall()
        out = []
        for realm, char_name, char_id in rows:
            cur2 = conn.execute(
                "SELECT name, rank, max_rank FROM professions WHERE character_id = ? ORDER BY name",
                (char_id,),
            )
            profs = [{"name": r[0], "rank": r[1], "max_rank": r[2]} for r in cur2.fetchall()]
            out.append((realm, char_name, profs))
        return out
    finally:
        conn.close()


def search_recipe_names(prefix: str, limit: int = 25) -> list[str]:
    """Return recipe names that start with prefix (case-insensitive), for autocomplete."""
    if not prefix or len(prefix) < 3:
        return []
    conn = _get_conn()
    try:
        cur = conn.execute(
            "SELECT DISTINCT name FROM recipes WHERE LOWER(name) LIKE LOWER(?) || '%' ORDER BY name LIMIT ?",
            (prefix.strip(), limit),
        )
        return [row[0] for row in cur.fetchall()]
    finally:
        conn.close()


def get_characters_with_recipe(recipe_name: str) -> list[tuple[str, str]]:
    """Return list of (realm_name, character_name) that have this recipe."""
    conn = _get_conn()
    try:
        cur = conn.execute(
            """SELECT DISTINCT r.name, c.name
               FROM recipes rec
               JOIN professions p ON rec.profession_id = p.id
               JOIN characters c ON p.character_id = c.id
               JOIN realms r ON c.realm_id = r.id
               WHERE rec.name = ? ORDER BY r.name, c.name""",
            (recipe_name,),
        )
        return cur.fetchall()
    finally:
        conn.close()
