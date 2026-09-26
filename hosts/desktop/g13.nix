# input-remapper mappings for the Logitech G13 (keypad + thumbstick, which
# input-remapper groups as one device "Logitech G13 Thumbstick")
let
  inherit (builtins) concatStringsSep;
  concatMapStrings = f: l: concatStringsSep "" (map f l);

  # Thumbstick axis past `threshold` percent (negative = below center)
  stick = code: threshold: output: {
    input = [
      {
        type = 3; # EV_ABS
        inherit code;
        analog_threshold = threshold;
      }
    ];
    inherit output;
  };
  # One wall-jump cycle: jump first, forward 10 ms later (the order WoW's
  # wall jump needs: "jump must always be first"), both held 50 ms, then a
  # 30 ms gap so the next cycle is a fresh jump and a fresh forward press.
  # `extra` keys (a strafe) go down and up with forward
  climb =
    extra:
    let
      keys = [ "KEY_W" ] ++ extra;
      down = concatMapStrings (k: ".key_down(${k})") keys;
      up = concatMapStrings (k: ".key_up(${k})") keys;
      cycle = "key_down(KEY_SPACE).wait(10)${down}.wait(50).key_up(KEY_SPACE)${up}.wait(30)";
    in
    "${cycle}.hold(${cycle})";

  key = code: output: {
    input = [
      {
        type = 1; # EV_KEY
        inherit code;
      }
    ];
    inherit output;
  };
in
[
  # Thumbstick -> WASD
  (stick 1 (-40) "KEY_W") # Up
  (stick 1 40 "KEY_S") # Down
  (stick 0 (-40) "KEY_A") # Left
  (stick 0 40 "KEY_D") # Right

  # G-keys
  (key 656 "KEY_1") # G1
  (key 657 "KEY_2") # G2
  (key 658 "KEY_3") # G3
  (key 659 "KEY_4") # G4
  (key 660 "KEY_5") # G5
  (key 661 "KEY_6") # G6
  (key 662 "KEY_7") # G7
  (key 663 "KEY_TAB") # G8
  (key 664 "KEY_9") # G9
  (key 665 "KEY_0") # G10
  (key 666 "KEY_F1") # G11
  (key 667 "KEY_F2") # G12
  (key 668 "KEY_F3") # G13
  (key 669 "KEY_F4") # G14
  (key 670 "KEY_LEFTSHIFT") # G15
  (key 671 "KEY_F6") # G16
  (key 672 "KEY_F7") # G17
  (key 673 "KEY_F8") # G18
  (key 674 "KEY_F9") # G19
  (key 675 "KEY_F10") # G20
  (key 676 "KEY_F11") # G21
  (key 677 "KEY_F12") # G22

  # M1 -> WoW wall climbing, M2 -> the same while strafing right (+ D).
  # One cycle per press, repeated while the button is held (a tap is one
  # cycle); the cycle is finished even when released mid-way
  (key 691 (climb [ ]))
  (key 692 (climb [ "KEY_D" ]))

  # Thumbstick buttons -> modifiers
  (key 294 "KEY_LEFTCTRL") # Left button
  (key 295 "KEY_ESC") # Right button
]
