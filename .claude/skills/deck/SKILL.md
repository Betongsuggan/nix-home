---
name: deck
description: Read and update the project tracker (Nextcloud Deck on controller) with the `deck` CLI. Use when the user mentions a project, ticket, card, board, backlog, "what am I working on", or asks to log progress, add an idea, move something to done, or capture a new project.
---

# Project tracker: Nextcloud Deck

The tracker is Nextcloud Deck at cloud.rydback.net. The `deck` command (modules/deck) is installed for the admin user on bits and desktop and authenticates on its own. Run `deck --help` for the verbs; `modules/deck/SPEC.md` has the details.

## Boards and what goes where

- **Projects**: the portfolio. One card per project, stacks `Idea` / `Active` / `Paused` / `Done`. A card here says what the project is and where its work is tracked; it does not hold task lists.
- **De-Google**, **AI lab**, **nix-home**: work boards. Stacks are `Backlog` (or `To do`) / `Doing` / `Blocked` (De-Google) / `Done`. One card per work item, with a markdown checklist in the description when the item has steps.
- Labels (per board): `repo` = changes in nix-home, `op` = operator work (phone, provider dashboards, hardware), `blocked` / `gate` = waiting on or gating other work, `on-site` = needs a visit.

New boards only for a new long-running project with real task volume; otherwise add a card to an existing board.

## How to work

1. Start by reading: `deck board <board>` (ids are in the first column), `deck card <id>` for the description and comments.
2. Status changes are a `move` plus a one-line `comment` saying what happened and when, e.g. `deck move 42 Doing && deck comment 42 "Started: module skeleton on branch x"`. Never move without the comment.
3. Progress inside a card: `deck edit <id> -d -` with the updated description (tick checklist boxes, keep the rest). Read it first; the PUT replaces the whole description.
4. New project idea from the user: `deck add Projects Idea "<title>" -d -` with two or three sentences: what, why, where work would land.
5. Something finished in the repo: comment the commit hash on the card, then `deck move <id> Done`.
6. `docs/de-googling.md` is still the written source of truth for De-Google decisions. A card moving to Active or Done there is also a line in that file's status board or progress log.

## Pitfalls

- Card ids are global, stack and label names are per board. Pass the card's own board's stack names to `move`.
- `-d TEXT` is the whole description; use `-d -` with a heredoc for anything multi-line.
- A 401 means the app password was revoked: tell the user, point at modules/deck/SPEC.md "Setting up the token".
