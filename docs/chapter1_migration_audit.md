# Chapter 1 Migration Audit

This audit separates the Prototype 0.2 demo from the authored S01–S08 structure. It is a preparation document, not a new puzzle specification.

## Design authority

- The first-chapter S01–S08 workflow is the progression authority.
- The Truth Gallery design PDF supplies the authored Gallery locations, mirror, visitor, restorer, Window, central platform, and visual-layer intentions.
- `BLUE_LAKE_CONTEXT.md.docx` is supplementary context. It does not override explicit scene design.
- The Gallery PDF still uses the legacy protagonist name “格斯” and legacy direct visual-mode vocabulary. The implementation constraint is Graham Steel (格雷汉·斯蒂尔) with Space + Chalk Cursor; those older labels are not copied into the new architecture.

## Existing Prototype 0.2 audit

### Keep

- `GrahamSteel` movement with WASD / arrow keys.
- Explicit wall collision construction and the visible central gate-like structure. The central barrier remains available as authored spatial-puzzle material; it is not classified as a bug or silently removed.
- `chalk_cursor.gd` as the reusable cursor presentation for Blue Lake interaction.
- `blue_lake_transform.gd` as a reusable transformation presentation.
- `transition_overlay.gd` as a reusable Gallery-to-Theater transition component.
- Placeholder drawing and the single prototype scene as a temporary shell.

### Refactor later

- `main.gd` currently owns map drawing, interaction targets, dialogue, Blue Lake state, mirror state, Window state, and the theater transition. The new `ChapterState` shell now owns chapter/Slice progression data; future Slice work should move event-specific logic out of `main.gd` one Slice at a time.
- The current mirror and Window click targets are useful interaction primitives, but their locations and unlock conditions belong to S03 and S05/S08 respectively.
- The current Blue Lake intro trigger and transformation are useful presentation prototypes, but their timing belongs to the authored S01–S06 progression rather than the old Prototype 0.2 route.

### Temporarily disabled in the default foundation shell

- The old automatic Blue Lake introduction near the left-side trigger area.
- The old Prototype 0.2 “mirror click → Window click → theater” progression.
- The old tutorial/objective wording that presents the demo path as the first-chapter structure.
- The old direct “Window opens after the next click” state chain.

The reusable scripts remain in the project so they can be reattached to the correct Slice later. No new Mirror, Window, Central Platform, NPC, collection, or branching puzzle was implemented here.

### Delete

- No authored Gallery content was deleted in this preparation pass.
- No debug hotkey system was reintroduced. Q and numeric visual-mode shortcuts are absent from the current input map.

## Known conflicts to resolve during Slice implementation

1. The Gallery PDF describes several visual modes and direct mode combinations. These are design intentions, not player hotkeys. Their player-facing implementation must remain under Blue Lake / Chalk interaction.
2. The PDF’s old Prototype-style Window sequence is not the final S01–S08 sequence. It must be reattached to S05, S06, S07, and S08 only after those Slice beats are implemented.
3. The current central barrier is visible and collision-backed, but its final role is not yet implemented. Preserve it as spatial structure until the S02/S03 layout pass.
4. The Gallery PDF lists a visual sensor collection and moral branches. These are not enabled by the foundation shell and must not be added to the current prototype without a Slice-specific implementation decision.

