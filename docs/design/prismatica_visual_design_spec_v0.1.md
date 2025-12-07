# Prismatica: Visual Design Specification v0.1

**Theme:** Bioluminescent Geometric (Tron meets Zen Garden).
**Vibe:** High-contrast, clean, responsive, and evolving.
**Functional Goal:** Use visuals to signal game state and satisfy specific player archetype motivations (Gardener beauty, Surger juice, Planner clarity).

---

## 1. The Atmosphere (The "Gardener" Layer)
The game environment must feel like a living, evolving space that the player nurtures.

* **The Canvas:**
    * **Base Color:** Deep Charcoal (`#101015`). Not pure black, to reduce eye strain.
    * **Vignette:** A subtle dark vignette at the corners to focus attention on the center.
* **The Glow (WorldEnvironment):**
    * **Glow/Bloom:** Enabled immediately. Every element emits light. The screen becomes brighter as the player builds, giving a sense of lighting up the darkness.
* **Visual Permanence (Evolution):**
    * **Level 1-9 (Construction):** Shapes are wireframe outlines. They feel incomplete.
    * **Level 10 (Complete):** The shape fills with solid **Cyan** light and gains a slow, "breathing" pulse animation. This signals completion and beauty to the Gardener.

---

## 2. The Core & Shapes (The "Surger" Layer)
Interactive elements must feel elastic and reactive to provide visceral feedback.

* **The Core (Heart):**
    * **Shape:** A thick white ring.
    * **Idle Animation:** A gentle "heartbeat" scale animation (Scale 1.0 → 1.05 → 1.0) matching the resource generation rhythm.
    * **Click Reaction:** Rapid compression (Scale 0.9) followed by an elastic overshoot (Scale 1.1).
* **The Particles (Sparks):**
    * **Style:** Glowing **Lines/Trails**, not generic squares.
    * **Motion:** On click, sparks burst radially outward, then curve smoothly toward the UI counter, creating a satisfying "flow" motion.
* **Screen Shake:**
    * **Subtle:** 0.5px offset on every click.
    * **Heavy:** 5px offset on "Overload" ability or "Level Up" events.

---

## 3. The Grid Connections (The "Tinkerer" Layer)
Visuals must clearly communicate game logic and synergies without requiring text.

* **Circuit Lines:**
    * When a Square is placed next to the Core or another Square, a thin, glowing line animates to connect them.
    * **Adjacency Visualization:** This line visually confirms the "Adjacency Bonus" mechanic.
* **Merge Effect:**
    * If a 2x2 block of Squares is formed, the internal connecting lines dissolve, and the outer border becomes thicker, forming a single "Super-Square."
* **Grid Background:**
    * Faint, low-opacity dots (grid points) instead of full lines. This keeps the view clean for the Planner while still providing structure.

---

## 4. The Scale (The "Voyager" Layer)
The visual presentation must convey a sense of expanding scale and discovery.

* **The Infinite Zoom:**
    * Instead of expanding the grid boundary, the **Camera Zooms Out**.
    * **Phase 1:** The Core fills ~30% of the screen.
    * **Phase 2:** The Core fills ~5% of the screen, revealing the surrounding "Sector."
* **Parallax Depth:** Background stars and dust move slower than the foreground grid during camera movement, creating a sense of immense depth.

---

## 5. Color Palette Strategy (Functional Coding)
Colors are used strictly to denote function, tier, and mood.

| State | Color | Hex Code (approx) | Meaning |
| :--- | :--- | :--- | :--- |
| **Sparks (Currency)** | **Amber** | `#FFC107` | Energy, fleeting, active. |
| **Grid (Structure)** | **Cyan** | `#00E5FF` | Permanent, stable, infrastructure. |
| **Adjacency Bonus** | **Lime** | `#76FF03` | Synergy, efficiency, growth. |
| **Locked/Void** | **Dark Grey** | `#2C2C35` | The unknown, potential. |
| **Prestige (Light)** | **White/Prism** | `#FFFFFF` | Purity, high-tier, reset. |