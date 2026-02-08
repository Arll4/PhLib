"""
Discord bot: displays data (e.g. messages forwarded from the API).
The API receives data from the client; this module is used to show it in Discord.
"""
import asyncio
import discord
from discord.ext import commands

from config import DISCORD_CHANNEL_ID

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


def schedule_send(content: str):
    """
    Schedule sending a message to the Discord channel (from another thread/loop).
    Returns a Future; the caller can await asyncio.wrap_future(future).
    """
    if not channel or not bot_loop:
        return None
    return asyncio.run_coroutine_threadsafe(channel.send(content=content), bot_loop)
