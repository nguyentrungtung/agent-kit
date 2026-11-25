#!/usr/bin/env python3
"""A tiny fake GitLab REST API (issues + labels) for tests/regressions.sh — logs every request as one JSON line.
usage: fake-gitlab.py <log-file> <port-file>   (token expected: secret-token; issue 7 is pre-seeded for `kit-task pull`)"""
import json, sys, urllib.parse
from http.server import BaseHTTPRequestHandler, HTTPServer

LOG, PORTFILE, TOKEN = sys.argv[1], sys.argv[2], "secret-token"
issues = {7: {"iid": 7, "title": "Fix login", "description": "Users cannot log in", "labels": ["bug", "priority:P1"], "state": "opened"}}
nxt = [41]


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _do(self, method):
        n = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(n).decode() if n else ""
        form = {k: v[0] for k, v in urllib.parse.parse_qs(raw, keep_blank_values=True).items()}
        with open(LOG, "a") as f:
            f.write(json.dumps({"m": method, "p": self.path, "token": self.headers.get("PRIVATE-TOKEN"), "form": form}) + "\n")

        def send(code, obj):
            b = json.dumps(obj).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(b)))
            self.end_headers()
            self.wfile.write(b)

        if self.headers.get("PRIVATE-TOKEN") != TOKEN:
            return send(401, {"message": "401 Unauthorized"})
        parts = self.path.split("?")[0].split("/")  # '', api, v4, projects, <project>, issues|labels, [iid]
        kind = parts[5] if len(parts) > 5 else ""
        if kind == "labels":
            return send(201, {"id": 1})
        if kind == "issues" and method == "POST":
            i = nxt[0]
            nxt[0] += 1
            issues[i] = {"iid": i, "title": form["title"], "description": form.get("description", ""),
                         "labels": form.get("labels", "").split(","), "state": "opened"}
            return send(201, dict(issues[i], web_url="http://127.0.0.1:%d/acme/app/-/issues/%d" % (self.server.server_port, i)))
        if kind == "issues" and len(parts) > 6:
            it = issues.get(int(parts[6]))
            if it is None:
                return send(404, {"message": "404 Not found"})
            if method == "PUT":
                ev = form.get("state_event")
                if ev:
                    it["state"] = "closed" if ev == "close" else "opened"
                for k in ("title", "description"):
                    if k in form:
                        it[k] = form[k]
            return send(200, it)
        send(404, {"message": "404 Not found"})

    def do_GET(self):
        self._do("GET")

    def do_POST(self):
        self._do("POST")

    def do_PUT(self):
        self._do("PUT")


srv = HTTPServer(("127.0.0.1", 0), H)
open(PORTFILE, "w").write(str(srv.server_port))
srv.serve_forever()
