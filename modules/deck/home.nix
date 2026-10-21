{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;

let
  cfg = config.my.deck;

  # A thin wrapper around Nextcloud Deck's REST API. Boards, stacks and labels
  # are addressed by name or id, cards by id (listings print them). Read verbs
  # take --json for the raw API answer.
  deck = pkgs.writeShellApplication {
    name = "deck";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      jq
    ];
    text = ''
      url=${escapeShellArg cfg.url}
      user=${escapeShellArg cfg.user}
      tokenFile=${escapeShellArg cfg.tokenFile}
      api="$url/index.php/apps/deck/api/v1.0"
      ocs="$url/ocs/v2.php/apps/deck/api/v1.0"

      usage() {
        cat <<'EOF'
      deck: Nextcloud Deck from the command line

        deck boards [--json]                       boards: id and title
        deck board <board> [--json]                stacks and their cards
        deck card <id> [--json]                    one card with description and comments
        deck add <board> <stack> <title> [-d TEXT|-] [-l LABEL]...
        deck edit <id> [-t TITLE] [-d TEXT|-]
        deck move <id> <stack>                     to another stack of the same board
        deck label <id> <label> | deck unlabel <id> <label>
        deck comment <id> TEXT|-
        deck done <id> | deck undone <id>
        deck archive <id>
        deck new-board <title> [COLOR]             COLOR is hex without '#', default 0082c9
        deck new-stack <board> <title>
        deck new-label <board> <title> COLOR
        deck delete-board <board>                  the board with every stack and card
        deck delete-label <board> <label>

      <board>, <stack> and <label> are a title (case-insensitive) or an id.
      "-d -" reads the text from stdin.
      EOF
      }

      # Errors raised inside $(...) must still end the script: signal the main
      # shell instead of exiting the subshell
      trap 'exit 1' USR1
      die() { echo "deck: $*" >&2; kill -s USR1 $$; exit 1; }

      [ -r "$tokenFile" ] || die "no token at $tokenFile; see modules/deck/SPEC.md, 'Setting up the token'"

      # req METHOD URL [JSON]: prints the body, exits on a non-2xx status.
      # The token stays out of argv: curl reads it from a config on a pipe.
      req() {
        local method=$1 path=$2 body=''${3-}
        local -a data=()
        if [ -n "$body" ]; then data=(--data-binary "$body"); fi
        local out status
        out=$(curl -sS -K <(printf 'user = "%s:%s"\n' "$user" "$(tr -d '\n' <"$tokenFile")") \
          -H 'OCS-APIRequest: true' -H 'Accept: application/json' -H 'Content-Type: application/json' \
          -X "$method" "''${data[@]}" -w '\n%{http_code}' "$path")
        status=''${out##*$'\n'}
        out=''${out%$'\n'*}
        if [ "$status" -lt 200 ] || [ "$status" -ge 300 ]; then
          echo "$out" >&2
          die "$method ''${path#"$url"} -> HTTP $status"
        fi
        printf '%s' "$out"
      }

      # by_name JSON QUERY: the id of the element whose title matches, or the id itself
      by_name() {
        local json=$1 q=$2
        if [[ $q =~ ^[0-9]+$ ]]; then echo "$q"; return; fi
        jq -er --arg q "$q" \
          'map(select((.title | ascii_downcase) == ($q | ascii_downcase))) | first | .id' <<<"$json" 2>/dev/null \
          || return 1
      }

      # Deck soft-deletes boards (deletedAt != 0, hidden in the UI until its cron
      # purges them); hide them here too
      boards() { req GET "$api/boards" | jq -c 'map(select(.deletedAt == 0))'; }

      board_id() { by_name "$(boards)" "$1" || die "no board '$1'"; }
      stack_id() { by_name "$(req GET "$api/boards/$1/stacks")" "$2" || die "no stack '$2' on board $1"; }
      label_id() { by_name "$(req GET "$api/boards/$1" | jq '.labels')" "$2" || die "no label '$2' on board $1"; }

      # find_card ID: sets CARD_BOARD and CARD_STACK, which the card endpoints
      # need in their path
      find_card() {
        local id=$1 b hit
        [[ $id =~ ^[0-9]+$ ]] || die "card ids are numbers, got '$id'"
        for b in $(boards | jq -r '.[].id'); do
          hit=$(req GET "$api/boards/$b/stacks" | jq -r --argjson id "$id" \
            '[.[] | select(any((.cards // [])[]; .id == $id)) | .id] | first // empty')
          if [ -n "$hit" ]; then
            CARD_BOARD=$b
            CARD_STACK=$hit
            return 0
          fi
        done
        die "no card with id $id"
      }

      card_url() { echo "$api/boards/$CARD_BOARD/stacks/$CARD_STACK/cards/$1"; }

      # put_card ID JQ-FILTER: GET the card, apply the filter, PUT it back
      put_card() {
        local id=$1 filter=$2 card
        card=$(req GET "$(card_url "$id")")
        card=$(jq -c "$filter"' | .owner |= (if type == "object" then .uid else . end)
          | {title, description, type, order, duedate, owner, done}' <<<"$card")
        req PUT "$(card_url "$id")" "$card" >/dev/null
      }

      read_text() { if [ "$1" = "-" ]; then cat; else printf '%s' "$1"; fi; }

      show_board() {
        jq -r '.[] | "## \(.title)  (stack \(.id))",
          ((.cards // [])[] | "  \(.id)\t\(.title)"
            + (if (.labels | length) > 0 then "  [" + ([.labels[].title] | join(", ")) + "]" else "" end)
            + (if .duedate then "  due \(.duedate[:10])" else "" end)
            + (if .done then "  done" else "" end)), ""'
      }

      show_card() {
        local card=$1 comments=$2 board=$3 stack=$4
        jq -r --arg board "$board" --arg stack "$stack" \
          '"#\(.id)  \(.title)", "board: \($board)   stack: \($stack)",
           "labels: " + ([.labels[]?.title] | join(", ")),
           (if .duedate then "due: \(.duedate)" else empty end),
           (if .done then "done: \(.done)" else empty end),
           "", (.description // ""), ""' <<<"$card"
        jq -r '.ocs.data[]? | "--- \(.actorDisplayName), \(.creationDateTime[:16])", .message, ""' <<<"$comments"
      }

      cmd=''${1-}
      [ -n "$cmd" ] || { usage; exit 1; }
      shift

      case "$cmd" in
        boards)
          out=$(boards)
          if [ "''${1-}" = "--json" ]; then echo "$out"; else jq -r '.[] | "\(.id)\t\(.title)"' <<<"$out"; fi
          ;;
        board)
          [ $# -ge 1 ] || die "usage: deck board <board> [--json]"
          b=$(board_id "$1")
          out=$(req GET "$api/boards/$b/stacks")
          if [ "''${2-}" = "--json" ]; then echo "$out"; else show_board <<<"$out"; fi
          ;;
        card)
          [ $# -ge 1 ] || die "usage: deck card <id> [--json]"
          find_card "$1"
          card=$(req GET "$(card_url "$1")")
          comments=$(req GET "$ocs/cards/$1/comments")
          if [ "''${2-}" = "--json" ]; then
            jq -n --argjson card "$card" --argjson comments "$comments" '$card + {comments: $comments.ocs.data}'
          else
            board=$(req GET "$api/boards/$CARD_BOARD" | jq -r '.title')
            stack=$(req GET "$api/boards/$CARD_BOARD/stacks" | jq -r --argjson s "$CARD_STACK" '.[] | select(.id == $s) | .title')
            show_card "$card" "$comments" "$board" "$stack"
          fi
          ;;
        add)
          [ $# -ge 3 ] || die "usage: deck add <board> <stack> <title> [-d TEXT|-] [-l LABEL]..."
          b=$(board_id "$1"); s=$(stack_id "$b" "$2"); title=$3; shift 3
          desc="" labels=()
          while getopts 'd:l:' opt; do
            case $opt in
              d) desc=$(read_text "$OPTARG") ;;
              l) labels+=("$OPTARG") ;;
              *) usage; exit 1 ;;
            esac
          done
          order=$(req GET "$api/boards/$b/stacks" | jq --argjson s "$s" '[.[] | select(.id == $s) | (.cards // []) | length] | first // 0')
          body=$(jq -cn --arg t "$title" --arg d "$desc" --argjson o "$((order + 1))" \
            '{title: $t, type: "plain", order: $o, description: $d}')
          card=$(req POST "$api/boards/$b/stacks/$s/cards" "$body")
          id=$(jq -r '.id' <<<"$card")
          for l in "''${labels[@]}"; do
            req PUT "$api/boards/$b/stacks/$s/cards/$id/assignLabel" "{\"labelId\": $(label_id "$b" "$l")}" >/dev/null
          done
          echo "$id"
          ;;
        edit)
          [ $# -ge 1 ] || die "usage: deck edit <id> [-t TITLE] [-d TEXT|-]"
          id=$1; shift
          filter='.'
          while getopts 't:d:' opt; do
            case $opt in
              t) filter="$filter | .title = $(jq -cn --arg v "$OPTARG" '$v')" ;;
              d) filter="$filter | .description = $(jq -cn --arg v "$(read_text "$OPTARG")" '$v')" ;;
              *) usage; exit 1 ;;
            esac
          done
          find_card "$id"
          put_card "$id" "$filter"
          ;;
        move)
          [ $# -eq 2 ] || die "usage: deck move <id> <stack>"
          find_card "$1"
          s=$(stack_id "$CARD_BOARD" "$2")
          order=$(req GET "$api/boards/$CARD_BOARD/stacks" | jq --argjson s "$s" '[.[] | select(.id == $s) | (.cards // []) | length] | first // 0')
          req PUT "$(card_url "$1")/reorder" "{\"order\": $((order + 1)), \"stackId\": $s}" >/dev/null
          ;;
        label | unlabel)
          [ $# -eq 2 ] || die "usage: deck $cmd <id> <label>"
          find_card "$1"
          l=$(label_id "$CARD_BOARD" "$2")
          verb=assignLabel; [ "$cmd" = unlabel ] && verb=removeLabel
          req PUT "$(card_url "$1")/$verb" "{\"labelId\": $l}" >/dev/null
          ;;
        comment)
          [ $# -eq 2 ] || die "usage: deck comment <id> TEXT|-"
          find_card "$1"
          body=$(jq -cn --arg m "$(read_text "$2")" '{message: $m}')
          req POST "$ocs/cards/$1/comments" "$body" >/dev/null
          ;;
        done)
          [ $# -eq 1 ] || die "usage: deck done <id>"
          find_card "$1"
          put_card "$1" ".done = \"$(date -u +%Y-%m-%dT%H:%M:%S+00:00)\""
          ;;
        undone)
          [ $# -eq 1 ] || die "usage: deck undone <id>"
          find_card "$1"
          put_card "$1" '.done = null'
          ;;
        archive)
          [ $# -eq 1 ] || die "usage: deck archive <id>"
          find_card "$1"
          req PUT "$(card_url "$1")/archive" >/dev/null
          ;;
        new-board)
          [ $# -ge 1 ] || die "usage: deck new-board <title> [COLOR]"
          req POST "$api/boards" "$(jq -cn --arg t "$1" --arg c "''${2-0082c9}" '{title: $t, color: $c}')" | jq -r '.id'
          ;;
        new-stack)
          [ $# -eq 2 ] || die "usage: deck new-stack <board> <title>"
          b=$(board_id "$1")
          n=$(req GET "$api/boards/$b/stacks" | jq 'length')
          req POST "$api/boards/$b/stacks" "$(jq -cn --arg t "$2" --argjson o "$((n + 1))" '{title: $t, order: $o}')" | jq -r '.id'
          ;;
        new-label)
          [ $# -eq 3 ] || die "usage: deck new-label <board> <title> COLOR"
          b=$(board_id "$1")
          req POST "$api/boards/$b/labels" "$(jq -cn --arg t "$2" --arg c "$3" '{title: $t, color: $c}')" | jq -r '.id'
          ;;
        delete-board)
          [ $# -eq 1 ] || die "usage: deck delete-board <board>"
          b=$(board_id "$1")
          req DELETE "$api/boards/$b" >/dev/null
          ;;
        delete-label)
          [ $# -eq 2 ] || die "usage: deck delete-label <board> <label>"
          b=$(board_id "$1")
          req DELETE "$api/boards/$b/labels/$(label_id "$b" "$2")" >/dev/null
          ;;
        -h | --help | help) usage ;;
        *) usage; exit 1 ;;
      esac
    '';
  };
in
{
  options.my.deck = {
    enable = mkEnableOption "the `deck` command for Nextcloud Deck";

    user = mkOption {
      type = types.str;
      default = config.home.username;
      defaultText = literalExpression "config.home.username";
      description = ''
        Nextcloud login the app password belongs to. Also selects the vault
        key: `accounts/nextcloud/<user>/deck-token` in `secrets/common.yaml`.
      '';
    };

    url = mkOption {
      type = types.str;
      default = "https://cloud.${inputs.self.lib.domain}";
      defaultText = literalExpression ''"https://cloud.''${lib.domain}"'';
      description = "Nextcloud base URL.";
    };

    tokenFile = mkOption {
      # str, not path: a path would copy the token into the world-readable store
      type = types.str;
      default = "/run/secrets/deck-token-${config.home.username}";
      defaultText = literalExpression ''"/run/secrets/deck-token-''${config.home.username}"'';
      description = ''
        File holding a Nextcloud app password for `user`, read at runtime.
        The NixOS half of this module decrypts it there from the vault.
      '';
    };

    package = mkOption {
      type = types.package;
      readOnly = true;
      default = deck;
      description = "The `deck` command.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ deck ];
  };
}
