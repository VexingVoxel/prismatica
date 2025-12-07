# Incremental Player Types – Matrix v0.3

This document summarizes the six incremental player types across:
- **v0.3 Axes / Tensions**
- **Reward Profiles**
- **Primary Design Hooks**

It is meant as a quick-reference matrix layered on top of the detailed type docs.

---

## 1. Types × Axes (The v0.3 Coordinates)

| Player Type | **A1: Engagement** | **A2: Horizon** | **A3: Cog. Load** | **A4: Variance** | **A5: Abstraction** | **A6: Structure** |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Planner-Engineer** | Idle / Mixed | Meta | **Crunch** (High) | **Reliability** | **Interface** (Abstract) | **Open** (Builder) |
| **Surger** | Active | Session | **Flow** (Med) | **Volatility** | **Interface** (Visceral) | **Directed** (Reactor) |
| **Challenger** | Active | Session/Run | **Crunch** (High) | **Volatility** (Skill) | **Interface** (Abstract) | **Directed** (Goal) |
| **Gardener** | Idle | Meta | **Flow** (Low) | **Reliability** | **World** (Concrete) | **Open** (Cultivator) |
| **Voyager** | Mixed | Meta | **Flow** (Med) | **Reliability** | **World** (Concrete) | **Directed** (Explorer) |
| **Tinkerer-Builder** | Active (Tinker) | Run/Meso | **Crunch** (Med) | **Volatility** (Exp.) | **World** (Concrete) | **Open** (Sandbox) |

---

## 2. Types × Reward / Fun Snapshot

| Player Type | Tempo | Intensity | Predictability | Primary Fun Mix |
| :--- | :--- | :--- | :--- | :--- |
| **Planner-Engineer** | Meso–Macro | Medium | High | **Mastery (Systemic)**: Predictability, Optimization, Efficiency. |
| **Surger** | Micro–Meso | High | Low–Med | **Spectacle**: Spikes, Crits, "Juice", Kinetic Feedback. |
| **Challenger** | Meso | High | Medium | **Challenge**: Overcoming constraints, Execution, Proof of Skill. |
| **Gardener** | Macro | Low | Very High | **Comfort**: Beauty, Reliability, Nurturing, Routine. |
| **Voyager** | Meso–Macro | Medium | High | **Discovery**: Novelty, Unlocks, "What's Next?", Expansion. |
| **Tinkerer-Builder** | Meso | Medium | Medium | **Expression**: Creativity, Experimentation, "What if I do this?". |

---

## 3. Types × Primary Design Hooks

| Player Type | Primary Design Hooks | Design Anti-Patterns |
| :--- | :--- | :--- |
| **Planner-Engineer** | Transparent formulas; Long-term Tech Trees; Meaningful Automation Logic; ROI Comparison Tools. | Opaque math; Hidden caps; RNG that ruins efficiency; Fake choices. |
| **Surger** | Short cooldown actives; Combo counters; Frenzy/Overdrive states; Visceral "Pop" on clicks. | Linear AFK-only growth; Zero active input; Boring/Flat visuals (no feedback). |
| **Challenger** | Explicit Hard Modes; Achievement Runs; Modifiers/Curses; Leaderboards; Speedruns. | "Pay-to-Win" bypasses; RNG-based failure; Trivial difficulty; Grind-gating skill checks. |
| **Gardener** | 100% Reliable Offline Progress; Visual Evolution (Base grows); Cozy Art; Low-pressure daily check-ins. | Decay mechanics; Mandatory active clicking; Stressful timers; Ugly/Abstract UI only. |
| **Voyager** | Biome Shifts; New Mechanics per Layer; Narrative Unlocks; Hidden Secrets; "Next Frontier" teasing. | Repetitive "Prestige just for numbers"; Static background art; Mechanics that never change. |
| **Tinkerer-Builder** | Free/Cheap Respecs; Modular Systems (Cards/Runes/Blocks); Sandbox Area; Layout Editors. | Permanent choices (FOMO); Single "Best Build"; High friction to change layout. |

---

## 4. Loop Analysis (Affordance View)

* **The Inner Loop (Micro-Decisions):** Strongly serves **Surger** and **Challenger**.
* **The Mid Loop (Session/Run):** Strongly serves **Tinkerer**, **Voyager**, **Planner**.
* **The Outer Loop (Meta-Growth):** Strongly serves **Gardener**, **Planner**, **Voyager**.

*Design Note:* A game missing a strong Outer Loop will churn Gardeners. A game missing a strong Inner Loop will churn Surgers.