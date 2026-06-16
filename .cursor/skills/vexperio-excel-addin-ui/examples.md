# UI examples — Vexperio Excel add-in

## Example 1: Pricing row opens task drawer

**Trigger:** User clicks a pricing row in `tab-options.jsx`.

```javascript
setState((s) => ({
  ...s,
  drawer: {
    kind: "newTask",
    payload: { kind: "price", preselect: row },
  },
}));
```

**Verify:** Pricing tab has no inline editors; `NewTaskForm` step 1 defaults to price kind.

---

## Example 2: Overview → Tours with selection

**Trigger:** User clicks a tour row in `tab-overview.jsx`.

```javascript
setState({
  tab: "tours",
  selectedTour: tour.id,
  secondary: null,
  drawer: null,
});
```

**Verify:** Tours tab shows detail for `selectedTour`; back from detail clears selection per tab logic.

---

## Example 3: Dirty drawer close guard

**Pattern in `EditTourForm`:**

```javascript
const [dirty, setDirty] = useState(false);
const { guard, overlay } = useCloseGuard(dirty);

return (
  <>
    <Drawer onClose={() => guard(onClose)} title="Edit tour">
      {/* fields call setDirty(true) on change */}
    </Drawer>
    {overlay}
  </>
);
```

**Verify:** Esc with unsaved changes shows confirm; Esc when clean closes immediately.

---

## Example 4: Port token change to prototype and production

1. Edit `excel-addin/src/tokens.css` — e.g. `--accent` under `accent-fluent-blue`.
2. Copy file to `vexperio excel add-ins/tokens.css`.
3. Open `Vexperio Add-in.html` in browser; toggle accent in Tweaks.
4. Sideload production; confirm `document.body` class `accent-fluent-blue`.

---

## Example 5: Schedule docking expand + new schedule seed

**Trigger:** “Add departure” from a docking header in `tab-dates.jsx`.

```javascript
setState((s) => ({
  ...s,
  drawer: {
    kind: "newSchedule",
    payload: {
      seed: { date: docking.date, ship: docking.ship, port: docking.port, dockingTimes: docking.dockingTimes },
    },
  },
}));
```

**Verify:** `NewScheduleForm` pre-fills date/ship/port; save still goes through `appendScheduleRow` in `api.js`.

---

## Example 6: Secondary page Esc

**Precondition:** `secondary.kind === 'option'`, `drawer === null`.

**Action:** Press Esc.

**Expected:** `app.jsx` listener clears `secondary`; tab body returns to active tab list/detail.

**Anti-pattern:** Adding `keydown` on `OptionDetail` that stops propagation before app listener — breaks hierarchy.
