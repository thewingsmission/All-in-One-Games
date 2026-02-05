# All-in-One Games - Play & Win
## Folder Structure & Asset Management Plan

**Created:** January 15, 2026  
**Status:** Structure Created, Ready for Development

---

## 📱 App Flow

```
Splash Screen
    ↓
Menu Scene (6 game icon buttons)
    ↓
Game Menu Scene
    ├── Leaderboard (Top 3)
    │   ├── All-Time
    │   └── Weekly Competition (placeholder)
    ├── Game Rules
    └── Difficulty Selection OR Start Game Button
        ↓
    Actual Game
```

---

## 🎮 Six Games Included (Version 1)

1. **Number Link** - Has difficulty levels
2. **Wordle** - Has difficulty levels (word length)
3. **Nerdle** - TBD on levels
4. **Pokerdle** - TBD on levels
5. **Sudoku** - Has difficulty levels
6. **Downstairs** - Likely no levels, direct start

---

## 📂 Directory Structure Created

### **Assets Organization**

```
assets/
├── common/                          # Shared resources
│   ├── images/                      # Splash, backgrounds
│   ├── icons/                       # App icon, navigation icons
│   └── fonts/                       # Custom fonts
│
└── games/                           # Game-specific assets
    ├── number link/
    │   ├── images/
    │   │   ├── animals/            # Animal themed images
    │   │   ├── congratulations/    # Success screens
    │   │   └── ui/                 # Buttons, UI elements
    │   ├── data/
    │   │   └── levels/             # CSV level files
    │   └── config/
    │
    ├── wordle/
    │   ├── images/
    │   └── data/
    │       └── word_tables/        # Word CSV files (3-10 letters)
    │
    ├── nerdle/
    │   ├── images/
    │   └── data/
    │
    ├── pokerdle/
    │   ├── images/
    │   │   └── cards/              # Card graphics
    │   └── data/
    │
    ├── sudoku/
    │   ├── images/
    │   └── data/
    │       └── puzzles/            # Sudoku CSV files
    │
    └── downstairs/
        ├── images/
        │   ├── characters/         # Player sprites
        │   └── ui/
        └── data/
```

### **Code Organization**

```
lib/
├── main.dart                        # App entry point
│
├── core/                            # Core functionality
│   ├── constants/                   # Colors, text styles, app constants
│   ├── navigation/                  # Routing logic
│   ├── services/                    # Storage, analytics
│   └── utils/                       # Asset loader, screen utilities
│
├── shared/                          # Shared UI components
│   ├── widgets/                     # Buttons, game cards, loaders
│   └── themes/                      # App theme
│
├── screens/                         # App-level screens
│   ├── splash/                      # Splash screen
│   ├── home/                        # Main menu (6 game buttons)
│   ├── game_menu/                   # Individual game menu with leaderboard
│   └── settings/                    # App settings
│
└── games/                           # Individual game modules
    ├── number_link/                 # Dart package name (assets folder: "number link")
    │   ├── screens/                 # Game screens
    │   ├── widgets/                 # Game-specific widgets
    │   ├── models/                  # Data models
    │   └── services/                # Game logic, level loading
    │
    ├── wordle/
    ├── nerdle/
    ├── pokerdle/
    ├── sudoku/
    └── downstairs/
```

---

## 🔧 Asset Migration Strategy

### **Source Web Apps Location:**
- `/Users/leekaiyan/Desktop/Flutter Projects/number_link_web/`
- `/Users/leekaiyan/Desktop/Flutter Projects/wordle_web/`
- `/Users/leekaiyan/Desktop/Flutter Projects/nerdle/`
- `/Users/leekaiyan/Desktop/Flutter Projects/pokerdle/`
- `/Users/leekaiyan/Desktop/Flutter Projects/sudoku/`
- `/Users/leekaiyan/Desktop/Flutter Projects/downstairs/`

### **Assets to Extract from Each Game:**

#### **Number Link:**
- Images: `assets/images/` → `assets/games/number link/images/`
- Levels: `assets/levels/*.csv` → `assets/games/number link/data/levels/`
- Web icon: `web/icons/Icon-192.png` → Use for menu button

#### **Wordle:**
- Word tables: `assets/*.csv` → `assets/games/wordle/data/word_tables/`
- Web icon: `web/icons/` → Use for menu button

#### **Sudoku:**
- Puzzle files: `*.csv` → `assets/games/sudoku/data/puzzles/`
- Web icon: `web/favicon.png` or `web/icons/` → Use for menu button

#### **Downstairs:**
- Character sprites: `assets/*.png` → `assets/games/downstairs/images/characters/`
- Web icon: `web/icons/` → Use for menu button

#### **Nerdle & Pokerdle:**
- Investigate assets and migrate accordingly
- Extract web icons for menu buttons

---

## 🎨 Menu Scene Design

### **Game Selection Buttons:**
- 6 image buttons arranged in grid (2 columns × 3 rows)
- Use web app icons (192x192 or 512x512 from web/icons/)
- Portrait orientation
- Buttons should be tappable with game name labels

### **Game Menu Scene (Individual Game):**
- Header: Game title/icon
- Leaderboard Section:
  - Toggle between "All-Time" and "Weekly"
  - Top 3 players (placeholder for now)
- Game Rules Section:
  - Brief text description
- Difficulty Selection:
  - Buttons for games with levels (Number Link, Wordle, Sudoku)
  - Single "Start Game" button for others
- Back button to return to main menu

---

## 📋 Next Steps (Awaiting Your Approval)

Once you approve, I will:

1. ✅ Initialize Flutter project
2. ✅ Create asset migration scripts
3. ✅ Copy assets from 6 web apps to mobile app structure
4. ✅ Set up `pubspec.yaml` with asset declarations
5. ✅ Build app navigation structure
6. ✅ Create splash screen
7. ✅ Create main menu with 6 game icon buttons
8. ✅ Create game menu template (with leaderboard placeholder)
9. ✅ Migrate game code from web apps (keeping exact same look)
10. ✅ Test each game individually

---

## 📝 Notes

- **Portrait Mode Only:** Force portrait orientation in app settings
- **Code Reuse:** Copy most code from existing 6 web projects
- **Visual Consistency:** Maintain exact same look as web versions
- **Modular Design:** Each game is self-contained for easy maintenance
- **Future Scalability:** Easy to add Game #7, #8, etc.

---

**Ready to proceed once you give the green light! 🚀**
