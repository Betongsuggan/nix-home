{ colors ? import ./colors.nix, font ? import ./font.nix }:
{
  font = font;
  colors = colors;
  cornerRadius = "5px";
}
