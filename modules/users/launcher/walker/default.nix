{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.launcher;

in {
  options.launcher.walker = {
    config = mkOption {
      type = types.attrs;
      default = {};
      description = "Walker configuration (merged with defaults)";
    };

    theme = mkOption {
      type = types.attrs;
      default = {};
      description = "Walker theme configuration";
    };
  };

  config = mkIf (cfg.enable && cfg.backend == "walker") {
    # Walker uses external tools (iwmenu, bzmenu) so we ensure they're available
    home.packages = with pkgs; [ unstable.bzmenu unstable.iwmenu ];

    programs.walker = {
      enable = true;
      runAsService = true;

      config = mkMerge [
        {
          app_launch_prefix = "";
          terminal_title_flag = "";
          locale = "";
          close_when_open = false;
          theme = lib.mkForce "gruvbox";
          monitor = "";
          hotreload_theme = true;
          as_window = false;
          timeout = 0;
          disable_click_to_close = true;
          force_keyboard_focus = true;
          keybinds.quick_activate = [ ];

          keys = {
            accept_typeahead = [ "tab" ];
            trigger_labels = "";
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
            max_entries = 15;
            show_initial_entries = true;
            single_click = true;
            visibility_threshold = 1;
            placeholder = "No Results";
          };

          search = {
            argument_delimiter = "#";
            placeholder = "Search...";
            delay = 0;
            resume_last_query = false;
          };

          activation_mode = { labels = ""; };

          builtins = {
            applications = {
              weight = 5;
              name = "applications";
              placeholder = "Applications";
              prioritize_new = false;
              hide_actions_with_empty_query = false;
              context_aware = true;
              refresh = true;
              show_sub_when_single = true;
              show_icon_when_single = true;
              show_generic = true;
              history = true;
              actions = {
                enabled = true;
                hide_category = false;
                hide_without_query = false;
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
                prompts = [{
                  model = "claude-3-7-sonnet-20250219";
                  temperature = 1;
                  max_tokens = 1000;
                  label = "General Assistant";
                  prompt =
                    "You are a helpful general assistant. Keep your answers short and precise.";
                }];
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
        }
        cfg.walker.config
      ];

      theme = mkMerge [
        {
          name = "gruvbox";
          style = ''
            @define-color window_bg_color #282828;
            @define-color accent_bg_color #504945;
            @define-color theme_fg_color #ebdbb2;

            * {
              all: unset;
            }

            .normal-icons {
              -gtk-icon-size: 14px;
            }

            .large-icons {
              -gtk-icon-size: 24px;
            }

            scrollbar {
              opacity: 0;
            }

            .box-wrapper {
              box-shadow:
                0 19px 38px rgba(0, 0, 0, 0.3),
                0 15px 12px rgba(0, 0, 0, 0.22);
              background: @window_bg_color;
              padding: 16px;
              border-radius: 8px;
              border: 1px solid darker(@accent_bg_color);
            }

            .preview-box,
            .elephant-hint,
            .placeholder {
              color: @theme_fg_color;
            }

            .box {
              background: @window_bg_color;
            }

            .search-container {
              border-radius: 6px;
              background: @window_bg_color;
            }

            .input placeholder {
              opacity: 0.5;
            }

            .input {
              caret-color: @theme_fg_color;
              background: lighter(@window_bg_color);
              padding: 8px;
              color: @theme_fg_color;
            }

            .input:focus,
            .input:active {
              background: lighter(@window_bg_color);
            }

            .content-container {
              background: @window_bg_color;
            }

            .placeholder {
              color: @theme_fg_color;
            }

            .scroll {
              background: @window_bg_color;
            }

            .list {
              color: @theme_fg_color;
              background: @window_bg_color;
            }

            child {
              background: @window_bg_color;
            }

            .item-box {
              border-radius: 4px;
              padding: 4px 8px;
              background: @window_bg_color;
              color: @theme_fg_color;
            }

            .item-quick-activation {
              display: none;
            }

            child:hover .item-box,
            child:selected .item-box {
              background: alpha(@accent_bg_color, 0.25);
            }

            .item-image {
              color: @theme_fg_color;
              margin-right: 8px;
            }

            .item-text {
              color: @theme_fg_color;
            }

            .item-sub {
              color: alpha(@theme_fg_color, 0.7);
            }
          '';
        }
        cfg.walker.theme
      ];
    };

    # Override walker systemd service to add restart delay
    # This prevents race condition when Hyprland restarts
    systemd.user.services.walker = {
      Service = {
        RestartSec = 3;  # Wait 3 seconds before restarting
      };
    };
  };
}
