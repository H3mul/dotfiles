# sandbox: host localhost ports (WSL2)
A sandboxed command's `localhost` is private to that command, so it can't reach host services (dev servers, published container ports).
- Don't retry unsandboxed. Ask me to add `127.0.0.1:<port>` (IP, not `localhost`; one entry per port, no ranges) to `sandbox.network.allowedDomains` in the project's `.claude/settings.local.json`.
- Then connect via the proxy by clearing the bypass: `NO_PROXY= no_proxy= curl http://127.0.0.1:<port>`.
- Tools that ignore proxy env vars (DB drivers, ssh, UDP, node fetch) won't work this way; use an `excludedCommands` entry or an approved unsandboxed retry.
- To test your own server, start it and the client in the same Bash call.
