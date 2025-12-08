# Prismatica: Visual Design Specification v0.2 (Shader Integration)

**Theme:** Bioluminescent Geometric (Tron meets Zen Garden).
**Vibe:** Living energy, deep space, reactive, and evolving.
**Functional Goal:** Use shaders and post-processing to transform static geometry into a breathing, bio-digital ecosystem, providing visceral feedback for every player action to satisfy archetype motivations (Gardener beauty, Surger juice, Planner clarity).

---

## 1. The Global Atmosphere (The "World" Shader)
The game environment must feel like a living, evolving space suspended in a deep void, not a flat 2D plane.

* **The Canvas (Background):**
    * **Base Color:** Deep Charcoal (`#101015`). Not pure black, to reduce eye strain and allow bloom to pop.
    * **Shader - "Plasma Fog":** Instead of a flat color, the background uses a screen-space shader with very slow-moving, large-scale noise.
        * *Effect:* Subtle, deep blue/purple nebular wisps slowly drifting across the void behind the grid. Adds immense depth.
* **The Glow (WorldEnvironment):**
    * **HDR Bloom:** Aggressive bloom is essential. Every cyan, white, and amber element must bleed light into neighboring pixels, creating a soft, neon atmosphere. The world must feel "hot" with energy.
* **Impact Feedback (Screen Shader):**
    * **Shader - Chromatic Aberration:** On significant events (e.g., triggering an active skill like "Overload," or hitting a major milestone tier), a brief, subtle chromatic aberration effect (RGB channel split) warps the screen edges, making the accumulated power feel unstable.

---

## 2. The Core (The "Heartbeat" Shader)
The central interactive element must feel like raw, contained energy that drives the entire system.

* **Geometry:** A single, thick white ring centered precisely on a grid point. Its diameter equals the spacing between grid points.
* **Shader - "Internal Energy Flow":** The white ring is not a solid texture.
    * *Effect:* A scrolling noise texture moves rapidly along the UVs of the ring, making it look like raw, turbulent plasma is flowing endlessly around the loop.
* **Shader - "Heat Haze" Pulse:**
    * *Effect:* Synced with the resource generation tick, a subtle displacement shader ripples outward from the core. It briefly distorts the background plasma fog and nearby grid dots, simulating a heat shockwave.
* **Click Reaction (Surger Feedback):** Rapid compression followed by an elastic overshoot, accompanied by a burst of fast-moving Amber spark particles.

---

## 3. The Grid & Connections (The "Nervous System" Shader)
The grid is not a static board; it is a dormant conductive network waiting to be awakened by the player's structures.

* **Grid Points (Dots):**
    * **Geometry:** A sparse grid of small cyan dots.
    * **Shader - "Dormant Breathing":** The dots do not have static brightness. A shader applies a slight, randomized sine-wave variance to their emission strength. They gently pulse individually, making the empty space feel dormant but alive.
* **Connections (Lines):**
    * **Shader - "Data Flow":** When shapes connect (creating adjacency), thin cyan lines form between them.
        * *Reveal:* They "grow" from source to destination using a reveal shader.
        * *Flow:* Once connected, they feature a scrolling UV texture, making them look like electricity or data packets are actively moving along the path.

---

## 4. The Shapes (Evolution & Permanence)
Visuals must clearly communicate the transition from temporary "planning" to permanent "infrastructure," satisfying the Gardener's need for nurturing.

* **Wireframe State (Construction - Levels 1-9):**
    * Thin cyan outlines. The internal space is empty. They feel lightweight and incomplete.
* **Solid State (Completion - Level 10+):**
    * **Shader - "Liquid Light Fill" (Transition):** When leveling up from wireframe to solid, the shape doesn't snap out of existence. A shader effect makes it look like liquid cyan light is pouring into the wireframe mold until it fills completely.
    * **Shader - "Idle Hum" (Solid):** Completed solid shapes have a subtle surface shader that makes their glow radiate outwards rhythmically, showing they are active, permanent producers.

---

## 5. Color Palette Strategy (Functional Coding)
Colors remain strictly functional to denote function and tier, but their behavior is defined by shaders.

| State | Color | Hex Code | Meaning | Shader Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **Sparks (Currency)** | **Amber** | `#FFC107` | Energy, fleeting, active. | Fast, turbulent particle shaders. High velocity. |
| **Grid/Shapes** | **Cyan** | `#00E5FF` | Infrastructure, stable. | Slow pulsing, steady "liquid" flow shaders. |
| **The Core** | **White** | `#FFFFFF` | The Source, raw power. | Brightest emission, rapid internal turbulent flow, displacement effects. |
| **Adjacency** | **Lime** | `#76FF03` | Synergy, efficiency. | Brighter, faster flow on connecting lines than standard grid lines. |
| **Prestige** | **White/Prism**| `#FFFFFF` | Purity, higher plane. | Crystalline, refractive shader effects. |