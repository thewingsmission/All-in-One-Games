#!/bin/bash

# Asset Migration Script for All-in-One Games
# This script copies assets from individual web game projects to the mobile app

set -e  # Exit on error

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Base paths
PARENT_DIR="/Users/leekaiyan/Desktop/Flutter Projects"
TARGET_DIR="$PARENT_DIR/All‑in‑One Games - Play & Win"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Asset Migration for All-in-One Games${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Function to copy files with progress
copy_assets() {
    local source=$1
    local dest=$2
    local game_name=$3
    
    if [ -d "$source" ]; then
        echo -e "${GREEN}✓ Copying $game_name assets...${NC}"
        mkdir -p "$dest"
        cp -R "$source"/* "$dest/" 2>/dev/null || true
        echo -e "${GREEN}  → $(ls -1 "$dest" | wc -l | xargs) items copied${NC}"
    else
        echo -e "${YELLOW}⚠ Source not found: $source${NC}"
    fi
}

# 1. Number Link
echo -e "\n${BLUE}[1/6] Number Link${NC}"
copy_assets "$PARENT_DIR/number_link_web/assets/images" "$TARGET_DIR/assets/games/number link/images" "Number Link images"
copy_assets "$PARENT_DIR/number_link_web/assets/levels" "$TARGET_DIR/assets/games/number link/data/levels" "Number Link levels"

# Copy web icon for menu button
if [ -f "$PARENT_DIR/number_link_web/web/icons/Icon-192.png" ]; then
    cp "$PARENT_DIR/number_link_web/web/icons/Icon-192.png" "$TARGET_DIR/assets/common/icons/number_link_icon.png"
    echo -e "${GREEN}✓ Number Link menu icon copied${NC}"
fi

# 2. Wordle
echo -e "\n${BLUE}[2/6] Wordle${NC}"
copy_assets "$PARENT_DIR/wordle_web/assets" "$TARGET_DIR/assets/games/wordle/data/word_tables" "Wordle word tables"

if [ -f "$PARENT_DIR/wordle_web/web/icons/Icon-192.png" ]; then
    cp "$PARENT_DIR/wordle_web/web/icons/Icon-192.png" "$TARGET_DIR/assets/common/icons/wordle_icon.png"
    echo -e "${GREEN}✓ Wordle menu icon copied${NC}"
fi

# 3. Sudoku
echo -e "\n${BLUE}[3/6] Sudoku${NC}"
# Copy CSV puzzle files from root
if [ -f "$PARENT_DIR/sudoku/sudoku_5000_fixed.csv" ]; then
    cp "$PARENT_DIR/sudoku/sudoku_5000_fixed.csv" "$TARGET_DIR/assets/games/sudoku/data/puzzles/"
    echo -e "${GREEN}✓ Sudoku puzzles copied${NC}"
elif [ -f "$PARENT_DIR/sudoku/sudoku_5000.csv" ]; then
    cp "$PARENT_DIR/sudoku/sudoku_5000.csv" "$TARGET_DIR/assets/games/sudoku/data/puzzles/"
    echo -e "${GREEN}✓ Sudoku puzzles copied${NC}"
fi

if [ -f "$PARENT_DIR/sudoku/web/icons/Icon-192.png" ]; then
    cp "$PARENT_DIR/sudoku/web/icons/Icon-192.png" "$TARGET_DIR/assets/common/icons/sudoku_icon.png"
    echo -e "${GREEN}✓ Sudoku menu icon copied${NC}"
elif [ -f "$PARENT_DIR/sudoku/web/favicon.png" ]; then
    cp "$PARENT_DIR/sudoku/web/favicon.png" "$TARGET_DIR/assets/common/icons/sudoku_icon.png"
    echo -e "${GREEN}✓ Sudoku menu icon copied (from favicon)${NC}"
fi

# 4. Downstairs
echo -e "\n${BLUE}[4/6] Downstairs${NC}"
copy_assets "$PARENT_DIR/downstairs/assets" "$TARGET_DIR/assets/games/downstairs/images/characters" "Downstairs sprites"

if [ -f "$PARENT_DIR/downstairs/web/icons/Icon-192.png" ]; then
    cp "$PARENT_DIR/downstairs/web/icons/Icon-192.png" "$TARGET_DIR/assets/common/icons/downstairs_icon.png"
    echo -e "${GREEN}✓ Downstairs menu icon copied${NC}"
fi

# 5. Nerdle
echo -e "\n${BLUE}[5/6] Nerdle${NC}"
if [ -d "$PARENT_DIR/nerdle" ]; then
    # Check for assets or web icons
    if [ -d "$PARENT_DIR/nerdle/assets" ]; then
        copy_assets "$PARENT_DIR/nerdle/assets" "$TARGET_DIR/assets/games/nerdle/images" "Nerdle assets"
    fi
    
    if [ -f "$PARENT_DIR/nerdle/web/icons/Icon-192.png" ]; then
        cp "$PARENT_DIR/nerdle/web/icons/Icon-192.png" "$TARGET_DIR/assets/common/icons/nerdle_icon.png"
        echo -e "${GREEN}✓ Nerdle menu icon copied${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Nerdle project not found or needs manual review${NC}"
fi

# 6. Pokerdle
echo -e "\n${BLUE}[6/6] Pokerdle${NC}"
if [ -d "$PARENT_DIR/pokerdle" ]; then
    # Check for assets
    if [ -d "$PARENT_DIR/pokerdle/assets" ]; then
        copy_assets "$PARENT_DIR/pokerdle/assets" "$TARGET_DIR/assets/games/pokerdle/images" "Pokerdle assets"
    fi
    
    if [ -f "$PARENT_DIR/pokerdle/web/icons/Icon-192.png" ]; then
        cp "$PARENT_DIR/pokerdle/web/icons/Icon-192.png" "$TARGET_DIR/assets/common/icons/pokerdle_icon.png"
        echo -e "${GREEN}✓ Pokerdle menu icon copied${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Pokerdle project not found or needs manual review${NC}"
fi

echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Asset migration complete!${NC}"
echo -e "${BLUE}========================================${NC}\n"
echo -e "Next step: Run 'flutter pub get' to update dependencies\n"
