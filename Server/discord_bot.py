"""
Discord bot: displays data (e.g. messages forwarded from the API).
Slash commands: /char_prof, /char_item (from PhLib SQLite data).
"""
import asyncio
import discord
from discord import app_commands
from discord.ext import commands

from config import DISCORD_CHANNEL_ID
import db

# Set when bot is ready (used by api to send messages)
bot_loop = None
channel = None

intents = discord.Intents.default()
bot = commands.Bot(command_prefix="!", intents=intents)


@bot.event
async def on_ready():
    global bot_loop, channel
    bot_loop = asyncio.get_event_loop()
    if DISCORD_CHANNEL_ID:
        channel = bot.get_channel(DISCORD_CHANNEL_ID)
        if channel:
            print(f"Discord bot ready. Display channel: #{channel.name}")
        else:
            print(f"Discord channel ID {DISCORD_CHANNEL_ID} not found.")
    else:
        print("DISCORD_CHANNEL_ID not set. Data will not be sent to Discord.")
    print(f"Logged in as {bot.user}")
    try:
        # Sync global commands (only char_prof and char_item; overwrites old ones)
        synced = await bot.tree.sync()
        print(f"Synced {len(synced)} command(s): {[c.name for c in synced]}")
        # Also sync per guild so any old guild-specific commands are replaced
        for guild in bot.guilds:
            try:
                await bot.tree.sync(guild=guild)
            except Exception:
                pass
    except Exception as e:
        print(f"Failed to sync commands: {e}")


def schedule_send(content: str):
    """
    Schedule sending a message to the Discord channel (from another thread/loop).
    Returns a Future; the caller can await asyncio.wrap_future(future).
    """
    if not channel or not bot_loop:
        return None
    return asyncio.run_coroutine_threadsafe(channel.send(content=content), bot_loop)


# ---- Slash commands (PhLib data from SQLite) ----


async def character_autocomplete(interaction: discord.Interaction, current: str) -> list[app_commands.Choice[str]]:
    """Autocomplete for /char_prof: show character names from DB."""
    db.init_db()
    names = db.search_character_names(current or "", limit=25)
    if not names:
        return []
    return [app_commands.Choice(name=n, value=n) for n in names]


@bot.tree.command(name="char_prof", description="Show what professions a character has")
@app_commands.describe(character="Character name (pick from list or leave empty to list all)")
@app_commands.autocomplete(character=character_autocomplete)
async def char_prof(interaction: discord.Interaction, character: str | None = None):
    await interaction.response.defer(ephemeral=True)
    db.init_db()
    if character:
        character = character.strip()
        results = db.get_professions_by_character_name(character)
        if not results:
            await interaction.edit_original_response(content=f"No character named **{character}** found in the database.")
            return
        lines = []
        for realm, char_name, profs in results:
            if not profs:
                lines.append(f"**{char_name}** ({realm}): *no professions*")
            else:
                proflist = ", ".join(f"{p['name']} ({p['rank'] or 0}/{p['max_rank'] or 0})" for p in profs)
                lines.append(f"**{char_name}** ({realm}): {proflist}")
        msg = "\n".join(lines)
        if len(msg) > 1900:
            msg = msg[:1900] + "\n..."
        await interaction.edit_original_response(content=msg or "No data.")
    else:
        chars = db.get_all_characters()
        if not chars:
            await interaction.edit_original_response(content="No characters in the database. Send saved vars from the client first.")
            return
        lines = []
        for realm, char_name in chars:
            profs = db.get_character_professions(realm, char_name)
            proflist = ", ".join(p["name"] for p in profs) if profs else "—"
            lines.append(f"**{char_name}** ({realm}): {proflist}")
        msg = "\n".join(lines)
        if len(msg) > 1900:
            msg = msg[:1900] + "\n..."
        await interaction.edit_original_response(content=msg or "No data.")


async def item_autocomplete(interaction: discord.Interaction, current: str) -> list[app_commands.Choice[str]]:
    if len(current) < 3:
        return [app_commands.Choice(name="Type at least 3 characters to search", value="")]
    names = db.search_recipe_names(current, limit=25)
    return [app_commands.Choice(name=n, value=n) for n in names]


@bot.tree.command(name="char_item", description="Search for a recipe; shows which characters have it")
@app_commands.describe(item="Recipe/item name (autocomplete after 3 characters)")
@app_commands.autocomplete(item=item_autocomplete)
async def char_item(interaction: discord.Interaction, item: str):
    await interaction.response.defer(ephemeral=True)
    item = (item or "").strip()
    if len(item) < 3:
        await interaction.edit_original_response(content="Please enter at least 3 characters to search for an item.")
        return
    db.init_db()
    chars = db.get_characters_with_recipe(item)
    if not chars:
        await interaction.edit_original_response(content=f"No characters found with recipe **{item}**.")
        return
    lines = [f"**{item}** — known by:"]
    for realm, char_name in chars:
        lines.append(f"• {char_name} ({realm})")
    msg = "\n".join(lines)
    if len(msg) > 1900:
        msg = msg[:1900] + "\n..."
    await interaction.edit_original_response(content=msg)
