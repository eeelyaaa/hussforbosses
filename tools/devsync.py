"""Huss for Bosses sync server: Studio pulls src/ and studio/ over localhost.

Adapted from deja-kill's tools/devsync.py (TEAM CALL B1; changes logged in team/decisions.md, M0).

Run (from the game repo root, keep it running):
    python tools/devsync.py

Then in Studio (Studio MCP run_code, or the command bar), in the Huss for Bosses place only:
    require(game.ServerStorage.DevSync:Clone())()                         -- sync src/ into the place
    require(game.ServerStorage.DevSync:Clone()).run("CheckPlace.lua")     -- run a studio/ script
    require(game.ServerStorage.DevSync:Clone()).run("checks/X.lua")       -- subfolders work too

The loader refuses to run unless workspace:GetAttribute("HussForBosses") == true (the place guard), and
refuses a server that is not this project (so deja-kill's devsync on its own port is never pulled here).

Endpoints:
    /health           {"project": "huss-for-bosses"}
    /files            {"project": ..., "files": {"<Root>/<path>.lua": source}}   every *.lua under src/
    /studio/<path>    one studio/ script as text (subfolders allowed, nothing outside studio/)
    /loader           src/ServerStorage/DevSync.lua, to recreate the loader in a place that lost it

File names follow Rojo: *.server.lua -> Script, *.client.lua -> LocalScript, *.lua -> ModuleScript,
init.lua / init.server.lua / init.client.lua turn their folder into that script, directories -> Folders.
"""
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PROJECT = "huss-for-bosses"
PORT = 34874  # deja-kill uses 34873; a different port keeps the two games' servers apart
ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
STUDIO = ROOT / "studio"
LOADER = SRC / "ServerStorage" / "DevSync.lua"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.reply(json.dumps({"project": PROJECT}), "application/json")
        elif self.path == "/files":
            files = {}
            for p in sorted(SRC.rglob("*.lua")):
                files[p.relative_to(SRC).as_posix()] = p.read_text(encoding="utf-8")
            self.reply(json.dumps({"project": PROJECT, "files": files}), "application/json")
        elif self.path == "/loader":
            self.reply(LOADER.read_text(encoding="utf-8"), "text/plain")
        elif self.path.startswith("/studio/"):
            p = (STUDIO / self.path[len("/studio/"):]).resolve()
            if STUDIO.resolve() not in p.parents or p.suffix != ".lua" or not p.is_file():
                self.send_error(404)
                return
            self.reply(p.read_text(encoding="utf-8"), "text/plain")
        else:
            self.send_error(404)

    def reply(self, text, content_type):
        body = text.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        print("devsync:", fmt % args, flush=True)


if __name__ == "__main__":
    print(f"devsync ({PROJECT}) serving {SRC} and {STUDIO} on http://127.0.0.1:{PORT}", flush=True)
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
