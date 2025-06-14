{ lib, theme }: {

  css = ''
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
      background: ${theme.colors.red-dark};
      margin-top: 20px;
      padding: 8px;
      font-size: 1.2em;
    }

    #window {
      color: ${theme.colors.text-light};
    }

    #box {
      border-radius: 2px;
      background: ${theme.colors.background-dark};
    }

    #search {
      background: ${theme.colors.background-light};
      border: 1px solid ${theme.colors.border-dark};
      border-radius: 5px;
      padding: 8px;
    }

    #prompt {
      margin-left: 4px;
      margin-right: 12px;
      color: ${theme.colors.text-light};
      opacity: 0.2;
    }

    #clear {
      color: ${theme.colors.text-light};
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

    #password {
    }

    #spinner {
      padding: 8px;
    }

    #typeahead {
      color: ${theme.colors.text-light};
      opacity: 0.8;
    }

    #input placeholder {
      opacity: 0.5;
    }

    #list {
    }

    child {
      padding: 8px;
      border-radius: 2px;
    }

    child:selected,
    child:hover {
      background: alpha(${theme.colors.red-dark}, 1.0);
    }

    #item {
    }

    #icon {
      margin-right: 8px;
      size: 10px;
    }

    #text {
    }

    #label {
      font-weight: 500;
    }

    #sub {
      opacity: 0.5;
      font-size: 0.8em;
    }

    #activationlabel {
    }

    #bar {
    }

    .barentry {
    }

    .activation #activationlabel {
    }

    .activation #text,
    .activation #icon,
    .activation #search {
      opacity: 0.5;
    }

    .aiItem {
      padding: 10px;
      border-radius: 2px;
      color: ${theme.colors.text-light};
      background: ${theme.colors.background-dark};
    }

    .aiItem.user {
      padding-left: 0;
      padding-right: 0;
    }

    .aiItem.assistant {
      background: lighter(${theme.colors.background-dark});
    }
  '';

  json = builtins.toJSON {
    ui = {
      anchors = {
        bottom = true;
        left = true;
        right = true;
        top = true;
      };
      window = {
        h_align = "fill";
        v_align = "fill";
        box = {
          h_align = "center";
          v_align = "center";
          width = 950;
          bar = {
            orientation = "horizontal";
            position = "end";
            entry = {
              h_align = "fill";
              h_expand = true;
              icon = {
                h_align = "center";
                h_expand = true;
                pixel_size = 24;
                theme = "";
              };
            };
          };
          search = {
            prompt = {
              name = "prompt";
              theme = "";
              pixel_size = 18;
              h_align = "center";
              v_align = "center";
            };
            clear = {
              name = "clear";
              icon = "edit-clear";
              theme = "";
              pixel_size = 18;
              h_align = "center";
              v_align = "center";
            };
            input = {
              h_align = "fill";
              h_expand = true;
              icons = true;
            };
            spinner = {
              hide = true;
            };
          };
          ai_scroll = {
            name = "aiScroll";
            h_align = "fill";
            v_align = "fill";
            max_height = 300;
            min_width = 400;
            height = 300;
            width = 400;
            margins = {
              top = 8;
            };
            list = {
              name = "aiList";
              orientation = "vertical";
              width = 400;
              spacing = 10;
              item = {
                name = "aiItem";
                h_align = "fill";
                v_align = "fill";
                x_align = 0;
                y_align = 0;
                wrap = true;
              };
            };
          };
          scroll = {
            list = {
              height = 15;
              width = 400;
              item = {
                activation_label = {
                  h_align = "fill";
                  v_align = "fill";
                  width = 20;
                  x_align = 0.5;
                  y_align = 0.5;
                };
                icon = {
                  pixel_size = 15;
                  theme = "";
                };
              };
            };
          };
        };
      };
    };
  };
}
