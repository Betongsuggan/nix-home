{ theme }: {
  css = ''
    /* Base styling to match Wofi */
    * {
      font-family: ${theme.font.name};
      font-size: 18px;
      color: ${theme.colors.text-light};
    }

    #window {
      background-color: ${theme.colors.background-dark};
      border: 1px solid ${theme.colors.border-light};
      border-radius: ${theme.cornerRadius};
    }

    #search {
      background-color: ${theme.colors.background-light};
      color: ${theme.colors.text-light};
      border: none;
      margin: 10px;
      padding: 0.50em;
    }

    #list {
      background-color: transparent;
      margin: 0 10px 10px 10px;
    }

    #item {
      padding: 0.50em;
    }

    #item:selected {
      background-color: ${theme.colors.red-dark};
    }

    #item:hover {
      background-color: ${theme.colors.red-dark};
    }

    #item-text {
      margin-left: 0.25em;
      color: ${theme.colors.text-light};
    }

    #item-text:selected {
      color: ${theme.colors.text-light};
    }

    #item-subtext {
      color: ${theme.colors.text-mid};
      font-size: 14px;
      margin-left: 0.25em;
    }

    image, #item-icon {
      margin-left: 0.25em;
      margin-right: 0.25em;
    }

    /* Custom styling */
  '';
}

#${config.walker.style}
