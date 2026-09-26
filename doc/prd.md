# Product Requirements Document (PRD)

## Project: OzActionbar (WoW 1.12.1 / Vanilla / Turtle WoW)

---

## 1. Overview & Objectives

### 1.1 Problem Statement
The default World of Warcraft 1.12.1 (Build 5875) user interface uses an asymmetrical, rigid 1024-pixel bottom bar. Action buttons are pushed to the left, flanking gryphon sculptures consume screen real estate, bottom-right extra bars are awkwardly anchored on top of bags, and pet/stance bars are pinned to the far left. Furthermore, the client offers poor combat feedback: action buttons do not visually warn players when their current target is outside spell or ability range, reactive procs (like Warrior's Overpower) lack prominent notification, and configuring bar elements requires tedious slash commands or editing Lua scripts.

### 1.2 Core Objectives
**OzActionbar** is a high-performance, modular, pure-Lua action bar enhancement designed specifically for WoW 1.12.1 (Vanilla / Turtle WoW / SuperWoW) adhering strictly to `agent.md` guidelines:
1. **Centered Bar Layout**: Horizontally center the primary action bar, bottom-left extra bar, bottom-right extra bar, stance/shapeshift bar, and pet action bar into a balanced, symmetrical combat matrix.
2. **Gryphon & Clutter Removal**: Eliminate the Blizzard gryphons (`MainMenuBarLeftEndCap`, `MainMenuBarRightEndCap`) and unnecessary heavy background art to provide an unobstructed, modern HUD.
3. **Advanced Range Detection & Out-of-Range Red Mask**: Dynamically check ability range using **UnitXP API** (`UnitXP("distanceBetween", "player", "target")`) when available, falling back seamlessly to spellbook range guessing and `IsActionInRange(slot)`. Action button icons are tinted red when the target is out of range.
4. **Button Border Replacement**: Replace default button borders with custom crisp texture (`btn_border.blp`).
5. **Reactive Ability Growing & Strong Highlight**: When reactive abilities become usable (e.g. Warrior Overpower/Revenge/Execute, Rogue Riposte, Hunter Counterattack/Mongoose Bite), scale/grow the button and display a pulsing proc highlight overlay (`btn_highlight_strong.blp`).
6. **Bags & MicroMenu Docking with Auto-Hide**: Relocate bags and micro-menu buttons to the screen bottom-right corner, hidden by default to keep the combat center clean, showing smoothly on mouse hover.
7. **Experience / Reputation Bar**: Slim, clean status bar positioned right below the main action bar (Layer 0.5) with rich mouseover statistics.
8. **In-Game Configuration GUI & Minimap Button**: Pure Lua settings window and draggable minimap button to toggle features without requiring slash commands or UI reloads.
9. **Strict Architectural Compliance**: 100% pure Lua UI (strictly NO XML frames), fully compatible with Lua 5.0.2 constraints (no `#`, no `//`, no `string.lower`/`string.upper`, no `GetStringHeight`), and safe lifecycle hook management.

---

## 2. Visual Wireframes & Layout Specifications (MANDATORY per agent.md Section 8)

### 2.1 Full Bottom HUD Wireframe (Combat Matrix Centered)

```text
+---------------------------------------------------------------------------------------------------+
|                                          SCREEN CENTER                                            |
|                                                |                                                  |
|                                                V                                                  |
|                                                                                                   |
|                            [     CastingBarFrame (Dynamic Height)     ]                           |
|                                                                                                   |
|                                 +---+ +---+ +---+ +---+ +---+                                     |
|                                 |P 1| |P 2| |P 3| |P 4| |P 5|  (Pet Bar - 10 btns centered)        |
|                                 +---+ +---+ +---+ +---+ +---+                                     |
|                                                                                                   |
|                                  [S1] [S2] [S3] [S4] (Stance/Shapeshift Bar - Centered)           |
|                                                                                                   |
|       +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+                     |
|       | 1 | | 2 | | 3 | | 4 | | 5 | | 6 | | 7 | | 8 | | 9 | | 10| | 11| | 12|  MultiBarBottomRight|
|       +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+  (Row 3)            |
|       +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+                     |
|       | 1 | | 2 | | 3 | | 4 | | 5 | | 6 | | 7 | | 8 | | 9 | | 10| | 11| | 12|  MultiBarBottomLeft |
|       +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+  (Row 2)            |
|       +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+                     |
|       | 1 | | 2 | | 3 | | 4 | | 5 | | 6 | | 7 | | 8 | | 9 | | 10| | 11| | 12|  MainMenuBar       |
|       +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+  (Row 1, Centered)  |
|       ======================== [ Experience / Reputation Bar ] ========================           |
|                                                                                                   |
+---------------------------------------------------------------------------------------------------+
|                                               [Bags / MicroMenu Docked at Bottom-Right Corner]    |
|                                               (Hidden by default, mouseover to reveal)            |
+---------------------------------------------------------------------------------------------------+
```

### 2.2 Dynamic Vertical Stacking Matrix

The vertical position of each layer dynamically stacks based on the visibility of underlying bars:

```text
====================================================================================
STACK ORDER (Bottom to Top)
====================================================================================
Layer 6: [CastingBarFrame]         --> Anchored to topmost visible element + 12px margin
------------------------------------------------------------------------------------
Layer 5: [PetActionBarFrame]       --> Dynamic width (10 buttons). Centered above Layer 4
------------------------------------------------------------------------------------
Layer 4: [ShapeshiftBarFrame]      --> Dynamic width (N forms). Centered above Layer 3
------------------------------------------------------------------------------------
Layer 3: [MultiBarBottomRight]     --> 12 buttons (498px wide). Centered above Layer 2
------------------------------------------------------------------------------------
Layer 2: [MultiBarBottomLeft]      --> 12 buttons (498px wide). Centered above Layer 1
------------------------------------------------------------------------------------
Layer 1: [Main Action Bar]         --> 12 buttons (498px wide). Centered at Screen Bottom
------------------------------------------------------------------------------------
Layer 0.5: [Exp / Rep Watch Bar]   --> Slim floating bar (498px wide) docked below Row 1
====================================================================================
```

### 2.3 Action Button Visual States (Range Coloring & Reactive Proc Glow)

```text
+-----------------------+     +-----------------------+     +-----------------------+
|  Normal / In-Range    |     |  Out of Range (Target)|     |  Reactive Proc Glow   |
|  (btn_border.blp)     |     |  (Red Vertex Mask)    |     |  (Growing + Highlight)|
|                       |     |                       |     |                       |
|   +---------------+   |     |   +---------------+   |     |  +=================+  |
|   |  Icon Texture |   |     |   |  Icon Texture |   |     |  | [HIGHLIGHT OVER]|  |
|   |  Vertex:      |   |     |   |  Vertex:      |   |     |  | |  Icon Texture | |  |
|   |  (1, 1, 1, 1) |   |     |   | (1, 0.15, 0.15)|   |     |  | |  (Scale 1.08) | |  |
|   |  Full Color   |   |     |   |  **RED TINT** |   |     |  | +---------------+ |  |
|   +---------------+   |     |   +---------------+   |     |  +=================+  |
|   Custom Square Border|     |   Custom Square Border|     |  btn_highlight_strong |
|   Hotkey: "1" (White) |     |   Hotkey: "1" (White) |     |  Pulsing Alpha 0.4-1.0|
+-----------------------+     +-----------------------+     +-----------------------+
```

### 2.4 In-Game Configuration GUI Wireframe

```text
+-------------------------------------------------------------------+
|  OzActionbar Settings                                         [X] |
+-------------------------------------------------------------------+
|                                                                   |
|  [X] Center Action Bars (Main, BottomLeft, BottomRight)           |
|  [X] Center Shapeshift / Stance Bar                               |
|  [X] Center Pet Action Bar                                        |
|  [X] Elevate Casting Bar Dynamically                              |
|                                                                   |
|  ---------------------------------------------------------------  |
|  [X] Remove Gryphons & Background Art                             |
|  [X] Dock Bags & MicroMenu to Bottom-Right (Auto-Hide on Hover)   |
|  [X] Apply Custom Button Border (btn_border.blp)                  |
|                                                                   |
|  ---------------------------------------------------------------  |
|  [X] Out-of-Range Red Coloring                                    |
|      [X] Use UnitXP Exact Distance (if available)                 |
|      [X] Fallback Spell Range Guessing                            |
|                                                                   |
|  ---------------------------------------------------------------  |
|  [X] Reactive Ability Growing & Proc Highlight                    |
|      (Overpower, Revenge, Execute, Riposte, Mongoose Bite, etc.)  |
|                                                                   |
|  ---------------------------------------------------------------  |
|  [X] Compact Bottom Experience & Reputation Bar                   |
|                                                                   |
|                                      [ Defaults ]     [ Close ]   |
+-------------------------------------------------------------------+
```

### 2.5 Minimap Button Wireframe

```text
       ( Minimap Radar )
     /                   \
    |                     |
    |      N       E      |
    |                     |=== (Oz)  <-- Minimap Button (31x31 circular)
     \                   /              - Left Click: Toggle Config GUI
       (       S       )                - Right Drag: Free radial positioning around minimap
```

---

## 3. Feature Specifications

### 3.1 Feature 1: Centered Bar Architecture

#### 3.1.1 Main Action Bar (`MainMenuBar`)
- **Dimensions**: 12 standard action buttons (`ActionButton1` to `ActionButton12`), each 36x36 px, with 6px spacing between buttons. Total width = `12 * 36 + 11 * 6 = 498px`.
- **Horizontal Centering**:
  - `ActionButton1` anchored with horizontal offset: `x = -math.floor(498 / 2) + 18 = -231px` relative to screen bottom center (`BOTTOM`, `UIParent`, 0, 24).
  - Buttons 2 through 12 sequentially anchor to the right of the previous button:
    `btn:SetPoint("LEFT", prevBtn, "RIGHT", 6, 0)`.
- **Paging Support**:
  - Full support for `BonusActionBarFrame` (Warrior stances, Rogue stealth, Druid forms).
  - Page navigation arrows (`ActionBarUpButton`, `ActionBarDownButton`) and page number indicator repositioned neatly adjacent to `ActionButton12` or hidden based on user preference.

#### 3.1.2 Bottom-Left Extra Bar (`MultiBarBottomLeft`)
- **Dimensions**: 12 buttons (`MultiBarBottomLeftButton1` to `MultiBarBottomLeftButton12`), 36x36 px, 6px spacing (498px width).
- **Positioning**: Centered horizontally at `x = 0`.
- **Vertical Anchor**: Anchored `4px` above `ActionButton1` (Row 1).

#### 3.1.3 Bottom-Right Extra Bar (`MultiBarBottomRight`)
- **Dimensions**: 12 buttons (`MultiBarBottomRightButton1` to `MultiBarBottomRightButton12`), 36x36 px, 6px spacing (498px width).
- **Positioning**: Centered horizontally at `x = 0`.
- **Vertical Anchor**: Anchored `4px` above `MultiBarBottomLeftButton1` (Row 2).

#### 3.1.4 Shapeshift & Stance Bar (`ShapeshiftBarFrame`)
- **Context**: In WoW 1.12, Warrior stances, Rogue stealth, Druid forms, Priest Shadowform, and Paladin auras all utilize `ShapeshiftBarFrame` with `ShapeshiftButton1` through `ShapeshiftButton10` (30x30 px, 7px spacing).
- **Dynamic Centering Calculation**:
  - `local num_forms = GetNumShapeshiftForms()`
  - When `num_forms > 0`:
    - `total_width = num_forms * 30 + (num_forms - 1) * 7`
    - `start_x = -math.floor(total_width / 2) + 15`
    - First button (`ShapeshiftButton1`) is positioned at `(start_x, y)` relative to the top edge of the highest active bottom action bar.
- **Stacking Priority**: Positioned directly above `MultiBarBottomRight` (if visible), else `MultiBarBottomLeft` (if visible), else `MainMenuBar`.

#### 3.1.5 Pet Action Bar (`PetActionBarFrame`)
- **Dimensions**: 10 pet buttons (`PetActionButton1` to `PetActionButton10`), 30x30 px, 8px spacing. Total width = `10 * 30 + 9 * 8 = 372px`.
- **Dynamic Centering**:
  - First button (`PetActionButton1`) offset = `-math.floor(372 / 2) + 15 = -171px`.
- **Stacking Priority**:
  - If `ShapeshiftBarFrame` is shown: Pet bar anchors above `ShapeshiftBarFrame`.
  - Otherwise: Pet bar anchors above the highest visible bottom action bar.

#### 3.1.6 Casting Bar Integration (`CastingBarFrame`)
- Automatically elevated to sit above the topmost element (Pet bar / Stance bar / Action bars) to prevent cast progress bar from clipping action buttons.

---

### 3.2 Feature 2: Gryphon Removal & Background Art Trimming

#### 3.2.1 Gryphon Removal
- Explicitly hide left and right gryphon endcaps:
  - `MainMenuBarLeftEndCap:Hide()`
  - `MainMenuBarRightEndCap:Hide()`
  - Nullify their `:Show()` methods to prevent Blizzard FrameXML from re-showing them on UI events:
    `MainMenuBarLeftEndCap.Show = function() end`
    `MainMenuBarRightEndCap.Show = function() end`

#### 3.2.2 Background Texture Trimming
- Hide or clear heavy stone background textures:
  - `MainMenuBarTexture0`, `MainMenuBarTexture1`, `MainMenuBarTexture2`, `MainMenuBarTexture3`
  - `MainMenuMaxLevelBar0`, `MainMenuMaxLevelBar1`, `MainMenuMaxLevelBar2`, `MainMenuMaxLevelBar3`
  - `SlidingActionBarTexture0`, `SlidingActionBarTexture1` (pet bar background art)
  - `ShapeshiftBarLeft`, `ShapeshiftBarMiddle`, `ShapeshiftBarRight` (stance bar background art)

---

### 3.3 Feature 3: Range Detection & Out-of-Range Red Mask

#### 3.3.1 Dual-Engine Range Detection Architecture

```text
                           +----------------------+
                           | ActionButton_OnUpdate|
                           +----------------------+
                                      |
                                      V
                           +----------------------+
                           |  Target Exists?      |--- NO ---> Normal State (1, 1, 1, 1)
                           +----------------------+
                                      | YES
                                      V
                     +----------------------------------+
                     | Is UnitXP Extension Available?   |
                     +----------------------------------+
                            /                    \
                     YES   /                      \  NO
                          V                        V
       +-------------------------------+   +-------------------------------+
       | UnitXP("distanceBetween",     |   | Fallback Engine:              |
       |        "player", "target")    |   | 1. IsActionInRange(slot)      |
       | Compare with Action's Max/Min |   | 2. Spellbook Range Guessing   |
       | Range (via Tooltip/Spell DB)  |   | 3. CheckInteractDistance(1..4)|
       +-------------------------------+   +-------------------------------+
                          \                        /
                           \                      /
                            V                    V
                             +------------------+
                             | Out of Range?    |
                             +------------------+
                               /              \
                        YES   /                \  NO
                             V                  V
                  +--------------------+   +--------------------+
                  | Icon Vertex Red:   |   | Check Usable:      |
                  | (1.0, 0.15, 0.15)  |   | Usable: (1, 1, 1)  |
                  +--------------------+   | OOM:  (0.4,0.4,0.4)|
                                           +--------------------+
```

#### 3.3.2 UnitXP Range Engine
- Probe for `UnitXP` function:
  `local ok, dist = pcall(UnitXP, "distanceBetween", "player", "target")`
- When `ok and type(dist) == "number"`:
  - Extract spell min/max range from action (via tooltip scanner cache or known spell range lookup).
  - Out of range if `dist > maxRange` or `(minRange and dist < minRange)`.

#### 3.3.3 Fallback Spell Range Guessing Engine
- If `UnitXP` is unavailable or returns non-numeric:
  1. Evaluate `IsActionInRange(slot)`. If `IsActionInRange(slot) == 0`, mark as out of range.
  2. For spells where `IsActionInRange(slot)` returns `nil` (or macro actions), parse action tooltip for range indicators (`string.find(text, "(%d+)%s*yd%s*range")`).
  3. Class-specific range probe spells (e.g. Shoot 30y, Charge 8-25y, Fireball 35y, Wrath 30y, Judgement 10y) paired with `CheckInteractDistance` provide supplementary range verification.

---

### 3.4 Feature 4: Button Border Replacement (`btn_border.blp`)

- Replace default round/beveled Blizzard borders with `Interface\AddOns\OzActionbar\texture\btn_border.blp`.
- Custom overlay frame/texture anchored to each button (`TOPLEFT` -3, 3 to `BOTTOMRIGHT` 3, -3) with clean square edges.
- Supports all primary buttons, bottom bars, pet buttons, and stance buttons.

---

### 3.5 Feature 5: Reactive Ability Growing & Proc Highlight (`btn_highlight_strong.blp`)

#### 3.5.1 Tracked Reactive Spells
- **Warrior**: `Overpower`, `Revenge`, `Execute`
- **Rogue**: `Riposte`
- **Hunter**: `Mongoose Bite`, `Counterattack`
- **Procs / Buffs**: Clearcasting, Shadow Trance (Nightfall), etc.

#### 3.5.2 Visual Behavior
- When ability is reactive and `IsUsableAction(slot) == 1` and not on cooldown:
  1. **Highlight Texture**: Overlay frame displays `Interface\AddOns\OzActionbar\texture\btn_highlight_strong.blp`.
  2. **Smooth Breathing / Glow**: Alpha oscillates between `0.4` and `1.0` using a lightweight sine-wave timer in `OnUpdate`.
  3. **Growing Effect**: The button scale or highlight overlay scales slightly (`1.08x`) to produce a distinct growing emphasis.
- When used or proc expires: highlight hides immediately, restoring standard scale and border.

---

### 3.6 Feature 6: Bags & MicroMenu Docking with Auto-Hide

- **Docking Location**: Bottom-right screen corner (`BOTTOMRIGHT`, `UIParent`, -10, 10).
- **Auto-Hide Behavior**:
  - Hidden by default during combat and exploration to maximize visual clarity.
  - Hover trigger: A transparent mouseover trigger zone at the bottom-right corner reveals the bag panel and micro buttons on mouse enter, fading out with a 0.5s delay on mouse leave.
  - Keyboard shortcuts (B, C, P, M, etc.) still open all respective frames normally.

---

### 3.7 Feature 7: Bottom Experience & Reputation Bar (Layer 0.5)

- **Position**: Anchored directly below `MainMenuBar` (`TOP`, `MainMenuBar`, "BOTTOM", 0, -3).
- **Dimensions**: 498px wide (matching 12 action buttons exactly) by 8px height.
- **Mouseover Text**: Clean tooltip / fontstring overlay showing current XP, level progress %, rested XP %, and watched reputation standing.

---

### 3.8 Feature 8: Configuration UI & Minimap Button

#### 3.8.1 Minimap Button
- 31x31 circular icon with standard Blizzard minimap ring.
- Drag handler: supports radial dragging around minimap circumference based on cursor angle.
- Left-click toggles `OzActionbarConfigFrame`.

#### 3.8.2 Configuration Window
- Pure Lua modal window (`OzActionbarConfigFrame`) with checkbox controls for all features.
- SavedVariables: `OzActionbarDB` stores user preferences across sessions per account/character.

---

## 4. Technical Architecture & Lua 5.0 Guidelines

### 4.1 Strict Adherence to `agent.md`

| Constraint | Implementation Rule |
| :--- | :--- |
| **No XML UI** | Strictly pure Lua creation (`CreateFrame`, pure programmatic anchors). |
| **Lua 5.0 Syntax** | Strictly NO `#table` (use `table.getn`), NO `//` (use `math.floor(a/b)`), NO `string.gmatch` (use `string.gfind`). |
| **String Safety** | Strictly NO `string.lower()` or `string.upper()` (prevents Chinese / UTF-8 / GBK corruption). |
| **FontString Safety** | Strictly NEVER call `GetStringHeight()` (doesn't exist in 1.12). |
| **Script Context** | Script handlers execute with `this`, `event`, `arg1`..`arg9` (no modern `self`). |
| **Closure Scoping** | Re-bind loop variables to explicit locals before closure creation. |
| **Hook Convention** | Non-destructive hooking with clean re-entrancy protection. |
| **Naming Conventions** | Modules in `PascalCase`, methods in `camelCase`, local functions start with verbs (`snake_case`), local variables start with nouns (`snake_case`), constants in `UPPER_SNAKE_CASE`. |

### 4.2 File & Directory Structure

```text
d:\proj\wow_addon\OzActionbar\
├── OzActionbar.toc                  # Addon metadata & load manifest
├── OzActionbar.lua                  # Core logic: Centering, Gryphons, Range, Border, Glow, Bags, Exp
├── Config.lua                       # Lightweight settings panel & draggable minimap button
├── texture/                         # Custom button textures & borders
│   ├── btn_border.blp               # Custom action button border texture
│   ├── btn_highlight_strong.blp     # Reactive proc highlight overlay texture
│   └── ...
└── doc/
    ├── agent.md                     # Development standards & rules
    └── prd.md                       # This document
```

---

## 5. Edge Cases & Resilience

1. **UnitXP Availability Dynamics**:
   - Detects presence of `UnitXP` at runtime. If player is running SuperWoW/UnitXP SP3, uses high-precision yard distance; if running clean 1.12 client, falls back gracefully to spellbook guessing without errors.
2. **Stance Shifting / Form Changes**:
   - Shifting stances (Warrior, Druid, Rogue) triggers `UPDATE_SHAPESHIFT_FORMS` and `ACTIONBAR_PAGE_CHANGED`. Dynamic width recalculation occurs instantaneously.
3. **Reactive Proc State Transitions**:
   - When Overpower/Revenge expires or dodge window ends, `IsUsableAction` turns false; highlight hides immediately and button returns to base scale without animation glitches.
4. **Resolution / UI Scale Changes**:
   - Listens for `UI_SCALE_CHANGED` and recalculates screen center offsets.

---

## 6. Verification & Test Plan

- [ ] **Gryphon Removal**: Verify both gryphons and background art are invisible on load and do not reappear after entering/leaving combat or opening world map.
- [ ] **Horizontal Centering**: Measure screen pixel center; verify Action Bar (Row 1), BottomLeft (Row 2), BottomRight (Row 3), Pet Bar, and Stance Bar are centered symmetrically.
- [ ] **Exp/Rep Bar Below Main Bar**: Verify Exp bar is positioned below `MainMenuBar` (Layer 0.5) matching 498px width.
- [ ] **Bags / MicroMenu Auto-Hide**: Verify bags and micro menu are tucked into bottom-right and appear only on mouseover.
- [ ] **Button Border Skinning**: Verify `btn_border.blp` is cleanly applied across all active buttons.
- [ ] **Range Detection (UnitXP & Fallback)**:
  - With UnitXP present: verify exact yard calculations against spell ranges.
  - Without UnitXP: verify fallback range detection via `IsActionInRange` and spellbook guessing.
  - Hostile target out of range: button icon tints deep red `(1.0, 0.15, 0.15)`.
- [ ] **Reactive Spell Growing & Proc Glow**:
  - Warrior Overpower after dodge: button overlay glows with `btn_highlight_strong.blp` and pulses/grows.
  - Button cast or expiration: glow terminates cleanly.
- [ ] **Minimap Button & Config GUI**:
  - Drag minimap button smoothly around radar edge.
  - Left-click opens Config GUI; toggling checkboxes enables/disables modules dynamically.
- [ ] **Lua 5.0 Audit**: Grep codebase to ensure 0 instances of `#`, `//`, `GetStringHeight`, `string.lower`, or `string.upper`.
