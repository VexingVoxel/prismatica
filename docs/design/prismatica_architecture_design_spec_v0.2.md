# Prismatica: POC Architecture & Design Specification v0.2

**Theme:** 2D Minimalist Geometric (Shapes & Particles).
**Engine:** Godot.
**Design Goal:** Validate the "Neutral Plaza" (First 30 Minutes) by balancing retention across the 6 Incremental Player Types.

---

## 1. Design Phases: The "Neutral Plaza" Simulation

The early game is structured to minimize "Churn Risks" (Anti-Patterns) while planting "Future Self" hooks for every player type.

### Phase 1: The Spark (0–5 Minutes)
* **The State:** A single hollow white circle in a dark void.
* **Interaction:** Active clicking (Pulse) generates "Sparks."
* **The Hook (Surger):** **"Overload" Ability.** At Minute 3, unlock a short-cooldown skill that triggers massive screen shake and particle bursts.
    * *Design Fix:* **Scaling Overload.** To prevent the "Soft Wall" boredom later, this ability must interact with the grid (e.g., "During Overload, Adjacency Bonuses are doubled").
* **The Hook (Gardener):** **The "Hands-Free" Rule.**
    * *Design Fix:* The first passive upgrade ("Background Resonance") must be affordable within **30–40 clicks**. If the Gardener is forced to click for 2 minutes straight, they will churn.
* **The Hook (Voyager):** **The Zoom Out.** As resources accumulate, the camera pulls back to reveal the circle is just one node on an infinite grid.

### Phase 2: The Grid (5–15 Minutes)
* **The State:** Unlock the "Grid View." Player places **Squares** adjacent to the Core Circle.
* **Interaction:** Drag-and-drop construction. Squares generate passive Sparks; the Core multiplies them.
* **The Hook (Tinkerer):** **Adjacency Bonuses.** "Squares generate +10% if touching the Core."
    * *Design Fix:* **Free Movement.** Moving an existing Square to a new slot must cost **zero resources**. Friction here kills experimentation.
* **The Hook (Planner):** **Transparent Math.**
    * *Design Fix:* **Detailed Tooltips.** On hover, the UI must show the formula: `Production: 10 (Base) x 1.1 (Adjacency)`. Opaque numbers ("Production: 11") trigger the Planner's anti-pattern.
* **The Hook (Gardener):** **Visual Evolution.** Squares permanently change color (Gray → Cyan) and glow upon reaching Level 10, rewarding nurturing.

### Phase 3: The Divergence (15–30 Minutes)
* **The State:** Progress slows (The Soft Wall).
* **The Paradigm Shift:** The **"Prism"** (Prestige). Reset the grid to gain "Light" and unlock **Triangles**.
* **The Hook (Planner):** **Locked "Logic" Tab.** Visible but inaccessible before prestige. Tooltip: "Unlocks Automation Circuits." Promises future depth and math.
* **The Hook (Challenger):** **Speedrun Achievement.** "Reach Prism Layer 2 in under 10 minutes."

---

## 2. Technical Architecture (Godot)

### A. Data vs. Visualization (Separation of Concerns)
To satisfy the **Planner's** need for robust math and the **Tinkerer's** need for modularity, we must strictly separate logic from rendering.

1.  **The "Core" Autoload (Singleton):**
    * **Responsibility:** The Source of Truth.
    * **Data:** Holds `BigNumber` values (Sparks, Light).
    * **Logic:** Runs the "Math Tick" loop (calculating passive income independent of frame rate).
    * **Why:** Ensures reliability (Gardener) and prevents floating-point errors (Planner).

2.  **The Grid Data Resource:**
    * **Structure:** A `Dictionary` lookup using `Vector2i` keys.
    * **Format:** `{ Vector2i(0,0): { "type": "Square", "level": 10 } }`.
    * **Why:** Allows instant logic checks (`grid_data.has(neighbor)`) for the Tinkerer's adjacency bonuses without touching the slow Scene Tree.

3.  **The Visual Layer (Nodes):**
    * **Structure:** A `Node2D` container.
    * **Logic:** Listens to signals from Core/Grid and updates visuals *only*.
    * **The Juice Separation:** The signal `resource_generated` triggers the UI text update (Planner) and spawns a particle burst (Surger) simultaneously but independently.

### B. Essential Systems for POC
* **BigNumber System:** Godot's built-in `int` caps at approx 9 x 10^18. We must implement or import a BigInt class immediately to support exponential growth.
* **Adjacency Algorithm:** A utility function that checks `grid_data.has(neighbor_coords)` to determine multipliers dynamically.

---

## 3. POC Success Criteria

Before moving to full production, the POC must validate:

* [ ] **The Visceral Check (Surger):** Does clicking the circle feel juicy? (Tween animations + Particle Bursts).
* [ ] **The Spatial Check (Tinkerer):** Does dragging a Square adjacent to the Core *immediately* update the UI numbers? (Instant feedback loop).
* [ ] **The Scale Check (Planner):** Can the math system handle numbers larger than a Quintillion (10^18) without crashing or turning negative?
* [ ] **The Aesthetics Check (Gardener):** Does the transition from "Empty Void" to "Glowing Grid" feel rewarding?

---

## 4. Scope Constraints (What to Ignore)
* **Save/Load Encryption:** Use plaintext JSON.
* **Audio:** Placeholder "Click" and "Level Up" sounds only.
* **Complex Tutorial:** Use static text labels.
* **Mobile UI:** Focus on Desktop Mouse/Keyboard input first.