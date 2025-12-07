# Incremental Player Model – Ontology v0.3

## 1. Purpose

This document defines the **ontological building blocks** for the "Clicker-Native" Player Model (v0.3).

The goal is to keep terms like *player type*, *behavior*, *trait*, and *mode* clearly separated, so we can design and reason about systems without conceptual mush.

This ontology is genre-specific: it assumes we’re talking about games with **incremental growth, automation, and possible idle play**.

---

## 2. Core Ontological Objects

### 2.1 The 6 Axes (The Coordinate System)

**What they are**
Continuous **dimensions of experience** that characterize how players engage with incremental games. These are the *space* in which player types live.

**A1 – Engagement Mode:** Active ↔ Idle
* **Active:** Prefers hands-on interaction, clicking, skill usage, and responding to prompts.
* **Idle:** Prefers automated background growth; sets systems up and walks away.
* *Design Note:* This is the "Physics" of the loop.

**A2 – Time Horizon:** Session ↔ Meta
* **Session (Short):** Thinks in seconds/minutes. "What happens if I click this now?"
* **Meta (Long):** Thinks in days/weeks/prestige cycles. "How does this decision affect my efficiency next week?"
* *Design Note:* This defines the "Tempo" of the reward schedule.

**A3 – Cognitive Load:** Flow ↔ Crunch
* **Flow (Low Load):** Prefers low-friction, intuitive decision-making. Values relaxation or visceral reaction over calculation.
* **Crunch (High Load):** Prefers high-friction, analytical decision-making. Values complex formulas, spreadsheets, and optimization puzzles.
* *Design Note:* This defines the mental energy required to play.

**A4 – Variance Appetite:** Reliability ↔ Volatility
* **Reliability (Low Variance):** Wants predictable, guaranteed returns. Dislikes RNG or systems that might invalidate plans.
* **Volatility (High Variance):** Wants high stakes and variance. Loves "Critical Success" moments, massive spikes, and gambles, even at the risk of stalling.
* *Design Note:* This replaces the v0.2 "Risk" axis. It defines emotional stability preferences.

**A5 – Abstraction Level:** Interface ↔ World
* **Interface (Abstract):** Engages primarily with the **Math and UI**. The game is a dashboard/spreadsheet to be optimized.
* **World (Concrete):** Engages primarily with the **Simulation and Fantasy**. The game is a place (garden, factory, universe) to be built or explored.
* *Design Note:* This defines the "Lens" through which the player perceives the game.

**A6 – Structure:** Directed ↔ Open
* **Directed:** Wants to follow a path. Motivated by clear goals, unlocks, and "next" buttons.
* **Open:** Wants to build a path. Motivated by tools, sandbox elements, and self-expression.
* *Design Note:* This defines the agency and guidance the player demands.

---

### 2.2 Player Types

**What they are**
Named **clusters of motivation** defined by characteristic positions on the Axes. They are intended to be relatively stable for a given person over time.

* **The Logic Group (Interface-Focused):**
    * **Planner-Engineer:** The Architect. (Reliable, Open, Crunch)
    * **Surger:** The Action Hero. (Volatile, Directed, Flow)
    * **Challenger:** The Athlete. (Volatile, Directed, Crunch)

* **The Experience Group (World-Focused):**
    * **Gardener:** The Cultivator. (Reliable, Open, Flow)
    * **Voyager:** The Explorer. (Reliable, Directed, Flow)
    * **Tinkerer-Builder:** The Inventor. (Volatile, Open, Crunch)

**Role**
* Provide a compact vocabulary for "who this feature is for."
* Serve as the central reference for design discussions (e.g., *"This system primarily serves Planners and Gardeners."*).

---

### 2.3 Player Behaviors

**What they are**
Observable **in-game actions and patterns**, such as:
* Frequency of prestige.
* Ratio of active clicking to offline time.
* Usage of external calculators vs. "eyeballing it."
* Re-spec frequency.

**Role**
* Behaviors are **evidence** of underlying player types, but not identical to them.
* We infer types *via* behaviors.

---

### 2.4 Traits / Modifiers

**What they are**
Secondary **motivation tags** that can overlay any player type without being types themselves. They add flavor and nuance.

* **Competitor:** Driven by external comparison (Leaderboards, Rankings).
* **Collaborator:** Driven by social contribution (Guilds, Raids, Chat).
* **Collector:** Driven by completionism (100% bars, Sets).
* **Narrativist:** Driven by story beats (Lore logs, Cutscenes).

**Ontology Note:** Traits are orthogonal to the axes. A *Planner-Competitor* plays for efficiency to beat others; a *Surger-Competitor* plays for spikes to beat others.

---

### 2.5 Modes / States

**What they are**
Short-lived **play states** a player can be in, tied to context or momentary intention.

* **Push Mode:** High-effort active play to break a wall.
* **Setup Mode:** Re-configuring after a prestige.
* **Farming/AFK Mode:** Low-effort accumulation.
* **Experimentation Mode:** Testing new builds.

**Relation to Types**
Types *bias* which modes someone prefers. A **Gardener** prefers Farming Mode; a **Surger** prefers Push Mode.

---

### 2.6 Segments (Analytics Layer)

**What they are**
Data-driven **player segments** derived from telemetry.

* **Descriptive:** "Segment A: Logins < 2 mins, Prestige daily."
* **Conceptual:** "Segment A maps to the **Gardener** type."

---

## 3. Usage in Design Docs

When applying this ontology in practice:

1.  **Define the Axes:** Use the v0.3 Axes to map your game's systems. Does your game support *Open Structure* (Building) or is it purely *Directed* (Unlocks)?
2.  **Audit by Type:** For any feature, explicitly note:
    * Which **Types** it serves.
    * Which **Anti-Patterns** it might trigger.
3.  **Balance the Loops:** Ensure your game has:
    * A **Logic Loop** for Interface players.
    * An **Experience Loop** for World players.

This ontology is the scaffolding on which we hang the **Incremental Player Types v0.3** and the library of **Design Hooks**.