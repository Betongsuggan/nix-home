# input-remapper mappings for the Logitech G13 (keypad + thumbstick, which
# input-remapper groups as one device "Logitech G13 Thumbstick")
let
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

  # M1 -> WoW wall climbing: W, then Space 10 ms later, both held for as
  # long as M1 is. A held Space makes WoW jump again on the first frame it
  # counts the character as standing, which on a wall can be a single frame;
  # spamming Space instead could leave that frame in a gap between presses.
  # Space stays down at least 40 ms, so a quick tap is still a hop
  (key 691 "modify(KEY_W, wait(10).modify(KEY_SPACE, wait(40).hold()))")

  # Thumbstick buttons -> modifiers
  (key 294 "KEY_LEFTCTRL") # Left button
  (key 295 "KEY_ESC") # Right button
]
