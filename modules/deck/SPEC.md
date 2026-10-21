# Deck

The `deck` command: Nextcloud Deck (the project tracker on controller, see `modules/nextcloud/SPEC.md`) from a terminal, and from Claude Code, without a browser or a pasted password. A thin curl + jq wrapper around Deck's REST API; the app password comes from the vault.

## Usage

```nix
# hosts/<host>/user-<name>.nix
my.deck = {
  enable = true;
  user = "birger";   # the Nextcloud login; defaults to the Home Manager username
};
```

That is the whole wiring. The NixOS half sees the user and decrypts `accounts/nextcloud/<user>/deck-token` from `secrets/common.yaml` to `/run/secrets/deck-token-<hm-user>` (owner that user, 0400). The host must have `my.sops` on.

```
deck boards [--json]                       boards: id and title
deck board <board> [--json]                stacks and their cards
deck card <id> [--json]                    one card with description and comments
deck add <board> <stack> <title> [-d TEXT|-] [-l LABEL]...    prints the new card id
deck edit <id> [-t TITLE] [-d TEXT|-]
deck move <id> <stack>                     to another stack of the same board
deck label <id> <label> | deck unlabel <id> <label>
deck comment <id> TEXT|-
deck done <id> | deck undone <id>
deck archive <id>
deck new-board <title> [COLOR]             COLOR is hex without '#', default 0082c9
deck new-stack <board> <title>
deck new-label <board> <title> COLOR
```

Boards, stacks and labels are a title (case-insensitive) or an id; cards are ids, which every listing prints. `-d -` reads the text from stdin, so multi-line markdown descriptions come from a heredoc. Read verbs take `--json` for the raw API answer.

```
deck board Projects
deck add Projects Idea "Immich on controller" -l repo -d - <<'TEXT'
Photos off Google. Blocked by the off-site backup.
TEXT
deck move 42 Active && deck comment 42 "Started 2026-10-22: module skeleton pushed"
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Install `deck` for this user |
| user | str | `config.home.username` | Nextcloud login the app password belongs to; selects the vault key |
| url | str | `https://cloud.<lib.domain>` | Nextcloud base URL |
| tokenFile | str | `/run/secrets/deck-token-<hm-user>` | File with the app password, read at runtime. A string, not a path, so it never enters the store |
| package | package (read-only) | the script | For other modules |

## Setting up the token

1. In Nextcloud as `user`: avatar → Settings → Security → *Devices & sessions* → name it (`claude-deck`) → *Create new app password*. Nextcloud shows a username and a password: the username is the login you already know, the password is the token to store.
2. In the `nix-vault` clone: `sops secrets/common.yaml` and add

   ```yaml
   accounts:
     nextcloud:
       birger:
         deck-token: <app password>
   ```
   Commit, push to controller, then `nix flake update nix-vault` here and rebuild the host.
3. `deck boards` lists the account's boards. HTTP 401 means the token is wrong or revoked.

To rotate: revoke the device in Nextcloud, repeat the steps with a new app password. One token per Nextcloud account, shared by every host that enables the module, which is why it lives in `common.yaml` (same as the SteamGridDB key).

## Notes

- **Why an app password and not the login password.** Revocable on its own from the Security page, and it bypasses nothing: it has the account's rights, no more.
- **Token handling.** curl reads `user = "login:token"` from a config on a pipe (`-K <(...)`), so the token is in neither argv nor the environment.
- **Card lookup.** Deck's card endpoints need the board and stack ids in the path, so `deck card 42` scans the account's boards for card 42. Fine for a handful of boards; archived cards are not found (unarchive in the UI first).
- **Comments** go through the OCS endpoint (`/ocs/v2.php/apps/deck/api/v1.0/cards/<id>/comments`), the rest through `/index.php/apps/deck/api/v1.0`.
- **`done` vs. the Done stack.** `deck done` stamps the card's done time (strikethrough in the UI, hidden from Upcoming); it does not move it. The convention on these boards is `deck move <id> Done` for a finished project card and `deck done` for a checklist-style card.
- **Claude Code.** `.claude/skills/deck/SKILL.md` carries the board conventions; `.claude/settings.json` allows `Bash(deck:*)` so updates don't prompt.
