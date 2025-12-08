# Prismatica: Visual Design Specification v0.3 (The Stabilized Reality)

**Theme:** Constructing Order from Chaos.
**Core Metaphor:** "Light is Territory."

---

## 1. The Environment Philosophy
The game world consists of two distinct states of existence. The player's goal is to expand the "Real" world into the "Void."

### A. The Void (Unlit)
*   **Concept:** Unstable, non-physical space.
*   **Visual:** The existing "Deep Slate Abyss" with Brownian Plasma Fog.
*   **Mechanic:** No building is possible here. It is empty space.

### B. The Stabilized Floor (Lit)
*   **Concept:** A manifested physical reality anchored by the Core and expanding structures.
*   **Visual:** A solid, dark surface that appears *only* where the "Fog of War" is lifted (where light touches).
*   **Material:** **Dark Matte Carbon / Obsidian.**
    *   **Texture:** Subtle diagonal etching or brushed metal finish.
    *   **Reflectivity:** Low, matte finish (grounding the neon shapes).
*   **Mechanic:** Valid placement zone. "If you can see the floor, you can build on it."

---

## 2. The Core: "The Anchor"
The Core is not just floating; it is the heavy machinery driving this stabilization.

*   **Footprint:** A 3x3 Grid Area (192x192px).
*   **The "Cooling Floor" (Socket):**
    *   **Visual:** A dense, intricate variation of the standard floor.
    *   **Details:** Deeply etched circuit patterns, vents, or cooling fins radiating from the center.
    *   **Purpose:** Visually defines the "Keep" / "No Build Zone" and grounds the floating energy rings.
*   **The Reactor (Energy Source):**
    *   **Concept:** A contained singularity functioning as an engine.
    *   **Gyroscope Rings:**
        *   **Primary Ring:** Thick, pulsing "Energy Flow" ring (existing).
        *   **Secondary Rings:** Two thinner, rotating rings nested inside.
            *   *Inner:* Fast rotation, White/Cyan.
            *   *Outer:* Slow rotation, segmented (HUD-like).
    *   **The Singularity (Center):**
        *   **Visual:** A dense, solid Orb (~16px radius).
        *   **Shader:** "Turbulent Plasma" effect (Miniature Star) using HDR White/Amber.
        *   **Behavior:** Pulses rhythmically with the game tick ("Heartbeat").
    *   **Particles:**
        *   **Orbitals:** Tiny sparks orbiting the center.
        *   **Ejection:** Resource generation triggers spark emission from the Singularity.

---

## 3. The Grid: "The Lattice"
The Grid is no longer just lines floating in space; it is the structural binding of the floor.

*   **Integration:** Grid lines appear as **Glowing Grout** or **Laser-Etched Seams** embedded into the Stabilized Floor.
*   **Behavior:**
    *   **Unlit:** Invisible (merged with the Void).
    *   **Lit:** They define the edges of the floor tiles.
    *   **Animation:** They pulse gently with the "network" status.

---

## 4. Implementation Strategy
*   **The Floor Layer:** A new distinct visual layer below the Grid Lines but above the Background.
*   **The Mask:** The same "Shader Array" mechanism used for the Grid Lines will now mask the Floor Texture.
    *   `Light Mask = 0` -> Show Background (Void).
    *   `Light Mask = 1` -> Show Floor Texture (Reality).
*   **Shader Approach:** Use a tiling noise/texture for the floor, masked by the calculated light distance.
