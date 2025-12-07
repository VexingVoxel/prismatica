# Shared Early-Phase Design Across Incremental Player Types v0.3

## 1. The Strategic Goal: The "Neutral Plaza"

Given the six distinct player types in the v0.3 Ontology, the critical design challenge of the first 30 minutes is **retention across divergent motivations**.

A **Planner** wants to see a spreadsheet; a **Voyager** wants to see a universe; a **Surger** wants to see a frenzy. If you lean too hard into one specific loop immediately, you churn the other five types.

The solution is the **Neutral Plaza**: A shared onboarding state that balances the v0.3 Axes in a way that is "Safe" for everyone, while planting specific **Design Hooks** that promise future depth for each specific type.

---

## 2. The Coordinates of the "Neutral Plaza"

To maximize broad appeal, the early game (0–30 mins) should sit in the "Goldilocks Zone" of the 6 Axes.

| Axis | Early Phase Setting | Why? |
| :--- | :--- | :--- |
| **A1 Engagement** | **Mixed** | Must offer *some* active clicking (for Surgers) but quickly unlock passive income (for Gardeners). |
| **A2 Horizon** | **Session (Short)** | Everyone starts with short attention spans. Goals must be immediate: "Reach Level 5." |
| **A3 Cog. Load** | **Flow (Low)** | Avoid "Crunch" immediately. Systems must be intuitive. Planners will wait for complexity; Gardeners will quit if hit with it too soon. |
| **A4 Variance** | **Reliability** | **Zero Risk.** Do not introduce RNG failure or "Volatility" yet. Both Planners and Gardeners hate early setbacks. |
| **A5 Abstraction** | **Balanced** | Critical. Must show *Numbers* (Interface) for the Logic Group and *Visuals* (World) for the Experience Group. |
| **A6 Structure** | **Directed** | Even "Open" types (Tinkerer/Planner) need a tutorial rail first. Sandbox freedom comes later. |

---

## 3. The "Future Self" Hooks (Foreshadowing)

While the gameplay is simple, you must drop "Breadcrumbs" that tell each type: *"Your specific kind of fun is coming soon."*

### For the Logic Group (Interface-Focused)

* **Planner-Engineer (The Architect)**
    * *The Hook:* **Visible Grayed-Out Depth.**
    * *Execution:* Show a "Locked" Automation tab or a Skill Tree with silhouette nodes. Let them hover and see "Requires Level 10." This tells them: *"Math is coming."*
    * *Anti-Pattern:* Hiding all complexity. If it looks *too* simple, the Planner assumes it's a "baby game" and quits.

* **Surger (The Action Hero)**
    * *The Hook:* **One Visceral Button.**
    * *Execution:* Give them a short-cooldown ability (e.g., "Overcharge") within the first 5 minutes. Make the numbers pop visually.
    * *Anti-Pattern:* A strict "1 click = 1 resource" loop for 20 minutes. They need a spike.

* **Challenger (The Athlete)**
    * *The Hook:* **A "Hard" Optional Goal.**
    * *Execution:* An early achievement: "Reach Level 10 in under 5 minutes." Or a "Boss" bar that looks intimidating.
    * *Anti-Pattern:* Making the tutorial un-loseable *and* slow. They need to smell resistance.

### For the Experience Group (World-Focused)

* **Gardener (The Cultivator)**
    * *The Hook:* **Visual Permanence.**
    * *Execution:* The first upgrade shouldn't just increase a number; it should add a visual asset (a house, a tree, a worker).
    * *Anti-Pattern:* "Spreadsheet Only" UI. If the world doesn't look like a place worth tending, they leave.

* **Voyager (The Explorer)**
    * *The Hook:* **The "Next" Silhouette.**
    * *Execution:* A locked tab labeled "Moon Base" or "The Cavern." A progress bar to "Next Biome."
    * *Anti-Pattern:* One static background. They need to know the environment will change.

* **Tinkerer-Builder (The Inventor)**
    * *The Hook:* **A Slot to Fill.**
    * *Execution:* An empty equipment slot or a grid with one building and empty space. "Drag and drop" functionality in the tutorial.
    * *Anti-Pattern:* Linear lists of upgrades only. They need to see *spatial* or *modular* potential.

---

## 4. The Transition Point (Breaking the Plaza)

The "Neutral Plaza" phase ends when the **First Prestige** or **First Major Unlock** occurs (usually 15–45 mins). This is where the game *must* branch to support divergent playstyles.

* **Unlock Automation:** Releases the **Gardener** to idle and the **Planner** to optimize.
* **Unlock Active Skills:** Releases the **Surger** and **Challenger** to push limits.
* **Unlock New Layers/Maps:** Releases the **Voyager** to explore and the **Tinkerer** to experiment.

**Design Rule:** If the first prestige is just "Numbers go up +10%," you lose the Voyager and Tinkerer. It must be a **Paradigm Shift**.

---

## 5. Early-Phase Anti-Patterns (v0.3)

Things that fragment the audience too early:

1.  **The "Data Dump" (High Cognitive Load):**
    * *Effect:* Scares off Gardeners and Surgers who want Flow.
    * *Fix:* Unfold complexity layer by layer.

2.  **The "Click Wall" (Forced Activity):**
    * *Effect:* Exhausts Gardeners and Planners who want automation.
    * *Fix:* Provide an "Auto-Clicker" or passive income source within the first 3 minutes.

3.  **The "Punishment" (High Variance):**
    * *Effect:* Any mechanic that resets progress *without* player consent (e.g., decay, theft) in the first session causes immediate uninstall from Reliable types (Gardener/Planner/Voyager).

4.  **The "Blank Page" (Open Structure):**
    * *Effect:* Dropping a Tinkerer/Planner into a complex sandbox with no tutorial. They freeze.
    * *Fix:* Directed tasks first ("Buy 5 Farms"), then open up ("Arrange them how you want").

---

## 6. Summary Checklist

For the first 30 minutes, does your game:
* [ ] **Flow:** Keep cognitive load low (intuitive UI)?
* [ ] **Feedback:** Provide visceral pops (Surger) *and* clear math (Planner)?
* [ ] **Visuals:** Show a growing world (Gardener/Voyager)?
* [ ] **Safety:** Ensure zero risk of loss (Reliability)?
* [ ] **Tease:** Show locked tabs/nodes for future depth (Planner/Tinkerer)?