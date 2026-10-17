# sandbox: host localhost ports (WSL2)
A sandboxed command's `localhost` is private to that command, so it can't reach host services (dev servers, published container ports).
- Don't retry unsandboxed. I can't edit settings files from the sandbox, so give me this command (port filled in) to run myself with the `!` prefix from the project root. It merges into `.claude/settings.local.json` without overwriting and is safe to re-run. Use the IP, not `localhost`; one entry per port, no ranges:
  `mkdir -p .claude && f=.claude/settings.local.json && { [ -s "$f" ] || echo '{}' > "$f"; } && jq --arg e "127.0.0.1:PORT" '.sandbox.network.allowedDomains |= ((. // []) | if index($e) then . else . + [$e] end)' "$f" > "$f.tmp" && mv "$f.tmp" "$f" || rm -f "$f.tmp"`
- Then connect via the proxy by clearing the bypass: `NO_PROXY= no_proxy= curl http://127.0.0.1:<port>`.
- Tools that ignore proxy env vars (DB drivers, ssh, UDP, node fetch) won't work this way; use an `excludedCommands` entry or an approved unsandboxed retry.
- To test your own server, start it and the client in the same Bash call.
