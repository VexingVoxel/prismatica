# Gap Analysis: Prismatica Architecture v0.5.2

**Target:** `docs/design/prismatica_architecture_design_spec_v0.5.2.md`
**Reference Docs:** v0.2 (Gameplay), v0.3 (Visuals), v0.5.1 (Tech Infrastructure)

---

## 1. Executive Summary
Version 0.5.2 successfully consolidates the "Three Pillars" (Tech, Gameplay, Visuals) into a cohesive master blueprint. However, the consolidation process has compressed some specific implementation details found in earlier versions. While the *architecture* is sound, the *implementation specs* for specific features are currently implied rather than explicit.

---

## 2. Identified Gaps

### A. Gameplay Mechanics (v0.2 Alignment)
*   **The "Soft Wall" Logic:** v0.2 explicitly mentioned a "Soft Wall" (slowdown) at Minute 15 that triggers the need for Prestige. v0.5.2 mentions the mechanics (Sparks, Adjacency) but omits the *progression pacing curves* or the specific math triggers for these events.
*   **Input Specifics:** v0.5.2 mentions `GameSceneController` handles input via "Command Pattern," but lacks the specific interaction definition found in v0.2 (Drag-and-drop vs. Click-to-place).
    *   *Risk:* Ambiguity in control scheme implementation.

### B. Visual/Juice Details (v0.3 Alignment)
*   **Specific Shader Params:** v0.3 defined specific shader uniforms (e.g., `fill_progress`). v0.5.2 retains `fill_progress` but omits the "Data Flow" UV scrolling parameters.
    *   *Risk:* Minor. Shader dev can infer this, but it's a slight loss of specificity.
*   **Camera Shake Nuance:** v0.3 defined specific *triggers* (skills vs. clicks). v0.5.2 groups them.
    *   *Impact:* Negligible.

### C. Technical Edge Cases (v0.5.1 Alignment)
*   **BigNumber Serialization:** v0.5.2 correctly identifies the need for String conversion.
    *   *Gap:* It does not specify the *format* of that string (e.g., scientific notation string vs. raw mantissa/exponent object wrapper). v0.5.1 hinted at an implementation detail that needs to be concrete in code.

### D. Missing Components (Logical Gaps)
*   **UI/HUD Architecture:** v0.5.2 focuses heavily on the *Grid* and *Core*, but the **UI Layer** (HUD) is under-defined.
    *   *Missing:* How does the `GameplayEventBus` connect to the UI? Who manages the "Toast" notifications mentioned in the Core Infrastructure?
    *   *Recommendation:* Need a specific `HUDController` in the Presentation Layer.

---

## 3. Recommendations for Implementation

1.  **Define HUD Controller:** Explicitly add a `HUDController` to the Presentation Layer in the next iteration or dev task to handle `resource_changed` signals and update Labels/Bars.
2.  **Standardize Input:** Decide on **Click-to-Select + Click-to-Place** (Mobile friendly) vs. **Drag-and-Drop** (Desktop native) before coding `GameSceneController`.
3.  **Math Spec:** Create a separate `balance_sheet.md` or similar to house the specific numbers (e.g., "15 minutes = Soft Wall") so they don't get lost in architectural docs.

---

## 4. Conclusion
v0.5.2 is **Ready for Implementation** regarding the *Engine Structure* (Autoloads, Buses, Data Flow). The identified gaps are primarily *Content/Tuning* details (Pacing, specific Math) or *UI wiring* details, which can be defined during the implementation of those specific systems.
