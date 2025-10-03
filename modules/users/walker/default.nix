{ config, lib, pkgs, ... }:
with lib;

{
  options.walker = {
    enable = mkEnableOption "Enable Walker application launcher with home manager module";
  };

  config = mkIf config.walker.enable {
    home.packages = with pkgs; [ unstable.bzmenu unstable.iwmenu ];

    programs.walker = {
      enable = true;
      runAsService = true;

      config = {
        app_launch_prefix = "";
        terminal_title_flag = "";
        locale = "";
        close_when_open = false;
        theme = lib.mkForce "local";
        monitor = "";
        hotreload_theme = true;
        as_window = false;
        timeout = 0;
        disable_click_to_close = true;
        force_keyboard_focus = true;

        keys = {
          accept_typeahead = [ "tab" ];
          trigger_labels = "lalt";
          next = [ "down" ];
          prev = [ "up" ];
          close = [ "esc" ];
          remove_from_history = [ "shift backspace" ];
          resume_query = [ "ctrl r" ];
          toggle_exact_search = [ "ctrl m" ];
          activation_modifiers = {
            keep_open = "shift";
            alternate = "alt";
          };
          ai = {
            clear_session = [ "ctrl x" ];
            copy_last_response = [ "ctrl c" ];
            resume_session = [ "ctrl r" ];
            run_last_response = [ "ctrl e" ];
          };
        };

        events = {
          on_activate = "";
          on_selection = "";
          on_exit = "";
          on_launch = "";
          on_query_change = "";
        };

        list = {
          dynamic_sub = true;
          keyboard_scroll_style = "vim";
          max_entries = 50;
          show_initial_entries = true;
          single_click = true;
          visibility_threshold = 20;
          placeholder = "No Results";
        };

        search = {
          argument_delimiter = "#";
          placeholder = "Search...";
          delay = 0;
          resume_last_query = false;
        };

        activation_mode = {
          labels = "";
        };

        builtins = {
          applications = {
            weight = 5;
            name = "applications";
            placeholder = "Applications";
            prioritize_new = false;
            hide_actions_with_empty_query = true;
            context_aware = true;
            refresh = true;
            show_sub_when_single = true;
            show_icon_when_single = true;
            show_generic = false;
            history = true;
            actions = {
              enabled = true;
              hide_category = false;
              hide_without_query = true;
            };
          };

          bookmarks = {
            weight = 5;
            placeholder = "Bookmarks";
            name = "bookmarks";
            icon = "bookmark";
            switcher_only = true;
            entries = [ ];
          };

          xdph_picker = {
            hidden = true;
            weight = 5;
            placeholder = "Screen/Window Picker";
            show_sub_when_single = true;
            name = "xdphpicker";
            switcher_only = true;
          };

          ai = {
            weight = 5;
            placeholder = "AI";
            name = "ai";
            icon = "help-browser";
            switcher_only = true;
            show_sub_when_single = true;
            anthropic = {
              prompts = [
                {
                  model = "claude-3-7-sonnet-20250219";
                  temperature = 1;
                  max_tokens = 1000;
                  label = "General Assistant";
                  prompt = "You are a helpful general assistant. Keep your answers short and precise.";
                }
              ];
            };
          };

          calc = {
            require_number = true;
            weight = 5;
            name = "calc";
            icon = "accessories-calculator";
            placeholder = "Calculator";
            min_chars = 4;
          };

          windows = {
            weight = 5;
            icon = "view-restore";
            name = "windows";
            placeholder = "Windows";
            show_icon_when_single = true;
          };

          clipboard = {
            always_put_new_on_top = true;
            exec = "wl-copy";
            weight = 5;
            name = "clipboard";
            avoid_line_breaks = true;
            placeholder = "Clipboard";
            image_height = 300;
            max_entries = 20;
          };

          commands = {
            weight = 5;
            icon = "utilities-terminal";
            switcher_only = true;
            name = "commands";
            placeholder = "Commands";
          };

          custom_commands = {
            weight = 5;
            icon = "utilities-terminal";
            name = "custom_commands";
            placeholder = "Custom Commands";
          };

          emojis = {
            exec = "wl-copy";
            weight = 5;
            name = "emojis";
            placeholder = "Emojis";
            switcher_only = true;
            history = true;
            typeahead = true;
            show_unqualified = false;
          };

          symbols = {
            after_copy = "";
            weight = 5;
            name = "symbols";
            placeholder = "Symbols";
            switcher_only = true;
            history = true;
            typeahead = true;
          };

          finder = {
            use_fd = false;
            fd_flags = "--ignore-vcs --type file";
            weight = 5;
            icon = "file";
            name = "finder";
            placeholder = "Finder";
            switcher_only = true;
            ignore_gitignore = true;
            refresh = true;
            concurrency = 8;
            show_icon_when_single = true;
            preview_images = true;
          };

          runner = {
            eager_loading = true;
            weight = 5;
            icon = "utilities-terminal";
            name = "runner";
            placeholder = "Runner";
            typeahead = true;
            history = true;
            generic_entry = false;
            refresh = true;
            use_fd = false;
          };

          ssh = {
            weight = 5;
            icon = "preferences-system-network";
            name = "ssh";
            placeholder = "SSH";
            switcher_only = true;
            history = true;
            refresh = true;
          };

          switcher = {
            weight = 5;
            name = "switcher";
            placeholder = "Switcher";
            prefix = "/";
          };

          websearch = {
            keep_selection = true;
            weight = 5;
            icon = "applications-internet";
            name = "websearch";
            placeholder = "Websearch";
            entries = [
              {
                name = "Nix Packages";
                url = "https://search.nixos.org/packages?query=%TERM%";
                switcher_only = true;
              }
              {
                name = "Home manager options";
                url = "https://home-manager-options.extranix.com/?query=%TERM%";
                switcher_only = true;
              }
              {
                name = "Google";
                url = "https://www.google.com/search?q=%TERM%";
                switcher_only = true;
              }
            ];
          };

          dmenu = {
            hidden = true;
            weight = 5;
            name = "dmenu";
            placeholder = "Dmenu";
            switcher_only = true;
            show_icon_when_single = true;
          };

          translation = {
            delay = 1000;
            weight = 5;
            name = "translation";
            icon = "accessories-dictionary";
            placeholder = "Translation";
            switcher_only = true;
            provider = "googlefree";
          };
        };
      };

      theme.style = ''
        #window,
        #box,
        #aiScroll,
        #aiList,
        #search,
        #password,
        #input,
        #prompt,
        #clear,
        #typeahead,
        #list,
        child,
        scrollbar,
        slider,
        #item,
        #text,
        #label,
        #bar,
        #sub,
        #activationlabel {
          all: unset;
        }

        #cfgerr {
          background: @theme_error_bg_color;
          margin-top: 20px;
          padding: 8px;
          font-size: 1.2em;
        }

        #window {
          color: @theme_fg_color;
        }

        #box {
          border-radius: 2px;
          background: @theme_bg_color;
        }

        #search {
          background: @theme_bg_color;
          border: 1px solid @theme_fg_color;
          border-radius: 5px;
          padding: 8px;
        }

        #prompt {
          margin-left: 4px;
          margin-right: 12px;
          color: @theme_fg_color;
          opacity: 0.2;
        }

        #clear {
          color: @theme_fg_color;
          opacity: 0.8;
        }

        #password,
        #input,
        #typeahead {
          border-radius: 2px;
        }

        #input {
          background: none;
        }

        #spinner {
          padding: 8px;
        }

        #typeahead {
          color: @theme_fg_color;
          opacity: 0.8;
        }

        #input placeholder {
          opacity: 0.5;
        }

        child {
          padding: 8px;
          border-radius: 2px;
        }

        child:selected,
        child:hover {
          background: alpha(@theme_error_bg_color, 1.0);
        }

        #icon {
          margin-right: 8px;
        }

        #text {
          font-size: 1.2em;
        }

        #label {
          font-weight: 500;
        }

        #sub {
          opacity: 0.5;
          font-size: 0.6em;
        }

        .aiItem {
          padding: 10px;
          border-radius: 2px;
          color: @theme_fg_color;
          background: @theme_bg_color;
        }

        .aiItem.user {
          padding-left: 0;
          padding-right: 0;
        }

        .aiItem.assistant {
          background: lighter(@theme_bg_color);
        }

        .activation #text,
        .activation #icon,
        .activation #search {
          opacity: 0.5;
        }
      '';
    };
  };
}