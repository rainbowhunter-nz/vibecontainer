# Claude Code project instructions

- Treat `app/` as the application source root.
- Do not place application source files at the repository root unless the user asks.
- The parent directory contains devcontainer and Claude Code infrastructure.
- Before making broad changes, inspect the existing app structure and infer the stack from actual files.
- Do not invent a language runtime or framework if the app is empty.
- Do not read `.env`, `.env.*`, or `secrets/` files.
- Prefer small, reviewable changes and run available tests or linters when a stack exists.
