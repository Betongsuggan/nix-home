#!/usr/bin/env bash

# Script to fix user modules that have home-manager.users.${config.user} wrapper

USER_MODULES_DIR="/home/betongsuggan/nix-home/modules/users"

# Find all files that contain the problematic pattern
FILES=$(grep -r "home-manager\.users\.\${config\.user}" "$USER_MODULES_DIR" -l)

for file in $FILES; do
    echo "Fixing $file..."
    
    # Use sed to fix the wrapper pattern
    # Remove the home-manager.users.${config.user} = { line and fix indentation
    sed -i 's/home-manager\.users\.\${config\.user} = {//g' "$file"
    
    # Fix closing bracket - find the pattern with extra closing bracket and space
    sed -i '/^[[:space:]]*};[[:space:]]*$/N;s/\n[[:space:]]*};[[:space:]]*$/\n  };/' "$file"
    
    echo "Fixed $file"
done

echo "All user modules fixed!"
