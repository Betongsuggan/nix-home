#!/usr/bin/env bash

# Test script for gaming user configuration
# This helps verify that the gaming user setup works correctly

echo "🎮 Testing Gaming User Configuration"
echo "=================================="

# Check if gamer user exists
if id "gamer" &>/dev/null; then
    echo "✅ Gaming user 'gamer' exists"
else
    echo "❌ Gaming user 'gamer' does not exist"
    exit 1
fi

# Check if Steam is available for gamer user
if sudo -u gamer which steam &>/dev/null; then
    echo "✅ Steam is available for gamer user"
else
    echo "❌ Steam is not available for gamer user"
fi

# Check if systemd service is created
if sudo -u gamer systemctl --user cat steam-bigpicture &>/dev/null; then
    echo "✅ Steam Big Picture systemd service is configured"
    
    # Show service status
    echo "📋 Service status:"
    sudo -u gamer systemctl --user status steam-bigpicture --no-pager || true
else
    echo "❌ Steam Big Picture systemd service is not configured"
fi

# Check autologin configuration
if grep -q "AutomaticLogin=gamer" /etc/gdm/custom.conf 2>/dev/null; then
    echo "✅ Autologin is configured for gamer user"
elif grep -q "gamer" /etc/systemd/system/getty@tty1.service.d/autologin.conf 2>/dev/null; then
    echo "✅ Console autologin is configured for gamer user"
else
    echo "⚠️  Autologin configuration not found (may be handled by display manager)"
fi

echo ""
echo "🚀 To test manually:"
echo "1. Switch to gamer user: sudo su - gamer"
echo "2. Start Steam Big Picture: steam -bigpicture"
echo "3. Enable service: systemctl --user enable steam-bigpicture"
echo "4. Start service: systemctl --user start steam-bigpicture"