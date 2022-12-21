{ pkgs }:
''
#!/usr/bin/env sh

# Terminate already running bar instances
${pkgs.killall}/bin/killall -q polybar

# Wait until the processes have been shut down
while pgrep -x polybar; do sleep 1; done

# Launch bar
polybar bottom 2>&1 &
''
