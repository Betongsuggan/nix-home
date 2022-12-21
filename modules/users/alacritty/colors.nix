let
  bgColor  = "#282828";
  red      = "#cc241d";
  green    = "#98971a";
  yellow   = "#d79921";
  blue     = "#458588";
  purple   = "#b16286";
  aqua     = "#689d68";
  gray     = "#a89984";
  darkgray = "#1d2021";
  white    = "#ebdbb2";
in
{
  primary = {
    background = "${bgColor}";
    foreground = "${white}";
  };

  selection = {
    text       = "${darkgray}";
    background = "${white}";
  };
  normal = {
    black   = "${bgColor}";
    red     = "${red}";
    green   = "${green}";
    yellow  = "${yellow}";
    blue    = "${blue}";
    magenta = "${purple}";
    cyan    = "${aqua}";
    white   = "${white}";
  };
}
