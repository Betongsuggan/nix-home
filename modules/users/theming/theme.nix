{ colors ? import ./colors.nix, font ? import ./font.nix }:
{
  inherit font colors;
  cornerRadius = "5px";
}
