---
name: Serene Crossword Sanctuary
colors:
  surface: '#05161a'
  surface-dim: '#05161a'
  surface-bright: '#2b3c40'
  surface-container-lowest: '#011014'
  surface-container-low: '#0d1e22'
  surface-container: '#112226'
  surface-container-high: '#1c2c31'
  surface-container-highest: '#27373c'
  on-surface: '#d3e6eb'
  on-surface-variant: '#bdc9c6'
  inverse-surface: '#d3e6eb'
  inverse-on-surface: '#223337'
  outline: '#889391'
  outline-variant: '#3e4947'
  surface-tint: '#80d5cb'
  primary: '#80d5cb'
  on-primary: '#003733'
  primary-container: '#0f766e'
  on-primary-container: '#a3faef'
  inverse-primary: '#006a63'
  secondary: '#fabc41'
  on-secondary: '#422d00'
  secondary-container: '#bd8700'
  on-secondary-container: '#392600'
  tertiary: '#ccc6b6'
  on-tertiary: '#333025'
  tertiary-container: '#6d695c'
  on-tertiary-container: '#f0e9d9'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#9cf2e8'
  primary-fixed-dim: '#80d5cb'
  on-primary-fixed: '#00201d'
  on-primary-fixed-variant: '#00504a'
  secondary-fixed: '#ffdea8'
  secondary-fixed-dim: '#fabc41'
  on-secondary-fixed: '#271900'
  on-secondary-fixed-variant: '#5e4200'
  tertiary-fixed: '#e9e2d2'
  tertiary-fixed-dim: '#ccc6b6'
  on-tertiary-fixed: '#1e1c12'
  on-tertiary-fixed-variant: '#4a473b'
  background: '#05161a'
  on-background: '#d3e6eb'
  surface-variant: '#27373c'
typography:
  display-lg:
    fontFamily: Quicksand
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
  display-lg-mobile:
    fontFamily: Quicksand
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 38px
  headline-tile:
    fontFamily: Quicksand
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 28px
  headline-md:
    fontFamily: Quicksand
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
  headline-sm:
    fontFamily: Quicksand
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Quicksand
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  body-md:
    fontFamily: Quicksand
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 18px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 14px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 0.75rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

## Brand & Style

The design system is engineered to foster an immersive, meditative escape within casual word puzzles. Centered on calm focus, mental unwinding, and understated luxury, the visual narrative avoids hyperactive casino-like stimuli. Instead, it pairs tranquil organic landscape scenery—such as misty pine highlands, dawn lakes, and muted mountain silhouettes—with tangible, polished letter craft.

The aesthetic fuses **Modern Organic Glassmorphism** with soft tactile components:
- **Atmospheric Depth:** Frosted glass panels layered with subtle ambient light allow scenic backdrops to illuminate through UI chrome without compromising legibility.
- **Physical Warmth:** Interactive letter wheels, solver blocks, and tile boards feel carved from polished bone or smoothed porcelain stone, featuring soft physical highlights and delicate amber glows upon completion.
- **Micro-Delight:** Celebratory states use warm golden firefly glows, gentle shimmer sweeps, and soft botanical particles over high-frequency flashes or loud visual noise.

## Colors

The palette establishes an alpine twilight foundation with warm cream fixtures and luminous golden highlights:

- **Primary (`#0F766E`, `#115E59`, Deep Teal):** Directs focal gameplay elements, active indicator badges, selected tile trails, and button surfaces. It evokes mountain pine canopies and serene alpine waters.
- **Secondary (`#F5B83D`, `#FBBF24`, Warm Sunlit Gold):** Reserved for victory rewards, coins, hint utility triggers, stars, streaks, and level completion blooms.
- **Tertiary (`#FFF8E7`, `#FEF3C7`, Soft Cream):** Applied to unsolved and solved letter blocks, interactive letter discs, and hero typography. It creates immediate contrast against dark natural scenery while maintaining a soft, natural aesthetic.
- **Neutral (`#0D1E22`, `#132E35`, Deep Forest Slate):** Base scenery overlays, frosted modal foundations, and deep shadows.
- **Functional Semantics:**
  - Success / Correct Word: `#2DD4BF` (Radiant Mint).
  - Subtle Warning / Extra Word Found: `#FB923C` (Tangerine Glow).
  - Translucent White: `rgba(255, 255, 255, 0.18)` for frosted panel fills, `rgba(255, 255, 255, 0.32)` for thin glass specular borders.

## Typography

Typography prioritizes legibility, gentle organic curves, and immediate recognition from arm's length on handheld screens:

- **Letter Tiles (`headline-tile`):** Rendered in `Quicksand` with bold weights and custom vertical centering. Optical balance ensures glyphs like `W`, `M`, `Q`, and `I` fit comfortably within uniform square or circular tile boundaries.
- **Interface & Metrics (`label-lg`, `label-md`):** Set in `Plus Jakarta Sans` for crisp numerical display across coin balances, level pills, and shop items.
- **Headings & Milestone Modals (`display-lg-mobile`, `headline-md`):** Uses rounded terminal apertures to maintain warmth and calm, avoiding harsh or sharp mechanical strokes.

## Layout & Spacing

Designed specifically for the Android 360x800 viewport, the layout uses a vertically stacked grid with strict safe-area constraints:

- **Canvas & Screen Margins:** Horizontal screen margins are locked at `16px` (`margin: 1rem`) to maximize puzzle cell grid width while preventing UI controls from touching edge bezels.
- **Vertical Hierarchy Partitioning:**
  - **Top Bar Safe Region (0px - 72px):** Houses status capsules (coins, level identifier, pause/settings).
  - **Word Matrix Board (72px - 440px):** Dynamic aspect-fit area accommodating cross-grids from 3x3 up to 7x7 cells, with `4px` to `6px` inter-cell spacing.
  - **Selected Word Streamer Bar (440px - 480px):** Floating pill displaying current active connected letters.
  - **Input Letter Wheel & Controls (480px - 760px):** Circular swipe wheel (diameter `230px - 250px`) flanked symmetrically by Hint, Shuffle, and Utility buttons.
  - **Bottom Navigation / System Inset (760px - 800px):** Clear padding preventing accidental system gesture activation.

## Elevation & Depth

Visual hierarchy uses frosted glassmorphic layering over ambient landscape backdrops rather than opaque surfaces:

- **Level 0 (Background Canvas):** High-definition nature backdrop with a calibrated gradient tint (`#0D1E22` at 60% opacity down to 20% opacity) ensuring game-piece contrast.
- **Level 1 (Pill Containers & Status Bars):** Frosted glass panels using `backdrop-filter: blur(16px)`, `background: rgba(13, 30, 34, 0.45)`, a top specular highlight border of `1px solid rgba(255, 255, 255, 0.25)`, and a deep, soft ambient shadow (`0 8px 32px -4px rgba(0, 0, 0, 0.35)`).
- **Level 2 (Letter Tiles - Board):** Solved tiles use soft cream (`#FFF8E7`) with a solid 3D bottom bevel (`box-shadow: 0 4px 0 #EAD7AC, 0 6px 12px rgba(0, 0, 0, 0.2)`). Unsolved tiles are translucent dark glass frames (`rgba(255, 255, 255, 0.15)`) with subtle inner borders.
- **Level 3 (Interactive Letter Wheel Nodes):** Tactile floating disks of cream or teal with dual-tone elevation—casting a localized soft glow when tapped or dragged across (`0 0 20px rgba(245, 184, 61, 0.6)`).
- **Level 4 (Modals & Victory Sheets):** Layered frosted glass with `backdrop-filter: blur(24px)` over an ambient darkened scrim (`rgba(10, 20, 24, 0.75)`).

## Shapes

The design system uses a pill-shaped geometry (`roundedness: 3`) to evoke organic river stones and smooth river pebbles:

- **Pills & Badges (`rounded-full` / `9999px`):** Used universally for status displays (coin tally, level tracker), action buttons, and active connection banners.
- **Letter Tiles (`16px` to `20px` radius):** Board puzzle cells maintain rounded squares with soft corners, keeping the grid readable while matching the overall curved motif.
- **Modal Containers (`24px` to `28px` radius):** Dialogs, level completion cards, and drawer sheets feature pill-derived rounded perimeters with no sharp vertices.

## Components

### Top Bar Navigation & Counters
- **Level Indicator Pill:** Centered translucent glass pill (`bg-neutral/40`, `border-white/20`) displaying `LEVEL 128` in crisp high-contrast white text.
- **Coin Balance Capsule:** Pill positioned at top-left. Left-aligned shimmery circular gold coin medallion (`#F5B83D`) with embossed star, paired with bold white counter text and an emerald-tinted `+` button.
- **Utility Buttons (Settings/Dictionary):** Circular 40x40px frosted glass icons (`bg-white/15`, `border-white/25`) with optical click depression states.

### Puzzle Matrix (Crossword Grid)
- **Empty / Target Cell:** Semi-translucent square container (`bg-white/10`, `border border-white/20`) with smooth rounded corners (`14px - 18px`).
- **Solved Cell:** Transitions into solid `#FFF8E7` tile surface with `#115E59` glyph, complete with a celebratory warm gold particle pulse upon word completion.

### Word Wheel & Letter Nodes
- **Wheel Base:** Translucent circular glass dish (`240px` diameter) with an ultra-thin ring guide.
- **Letter Nodes:** Circular `48px` buttons arranged along the wheel's perimeter. Idle: `#FFF8E7` with `#132E35` text. Active/Dragged: Shifts instantly to `#0F766E` with golden radial border glow and cream text.
- **Connecting Vector String:** Organic dynamic ribbon drawn between selected letters with a translucent teal gradient and bright gold core line (`width: 6px`).

### Action & Booster Buttons
- **Primary Buttons:** High-gloss deep teal (`#0F766E`) pill with a lighter top inner highlight, displaying cream text and an elevation drop of `0 4px 0 #0B524D`.
- **Booster Buttons (Hint / Shuffle / Target):** Circular frosted glass action discs positioned left and right of the wheel. Badge counters attached to the top-right corner indicate remaining booster counts using secondary gold (`#F5B83D`).
- **Modals & Cards:** Frosted glass overlay with centered reward chests or star clusters, warm gold headline text, and dual primary actions.