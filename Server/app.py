import contextlib
import threading
import time
import uvicorn

import config
from api import app as fastapi_app
import discord_bot


class UvicornServer(uvicorn.Server):
  def install_signal_handlers(self):
    pass

  @contextlib.contextmanager
  def run_in_thread(self):
    thread = threading.Thread(target=self.run, daemon=True)
    thread.start()
    try:
      while not self.started:
        time.sleep(1e-3)
        yield
    except Exception as e:
      print(f"Error in UvicornServer.run_in_thread: {e}")
    finally:
      self.should_exit = True
      thread.join(timeout=2)


if __name__ == "__main__":
    if not config.DISCORD_TOKEN:
        print("Warning: DISCORD_TOKEN not set. Discord bot will not start.")
        uvicorn.run(fastapi_app, host=config.API_HOST, port=config.API_PORT)
    else:
        server_config = uvicorn.Config(
            fastapi_app, host=config.API_HOST, port=config.API_PORT
        )
        server = UvicornServer(server_config)
        with server.run_in_thread():
            discord_bot.bot.run(config.DISCORD_TOKEN)
