# Adding Vexperio skills in Cursor

Skills in this folder are **already installed** for this repo. Use the steps below if they do not appear in the IDE.

## 1. Open the right workspace

Open the folder **`vexperio-db`** (repo root), not only `excel-addin/`. Cursor loads project skills from `.cursor/skills/` at the workspace root.

## 2. Confirm in Cursor Settings

1. **Cursor Settings** — `Cmd+Shift+J` (Mac) or `Ctrl+Shift+J` (Windows/Linux)
2. Go to **Rules** (or **Rules, Skills, Subagents**)
3. Under **Agent Decides** (or **Skills**), you should see:

   - `vexperio-excel-addin-ui`
   - `vexperio-excel-integration`
   - `vexperio-excel-addin-test`
   - `vexperio-excel-addin-docs`

4. If missing: **Reload Window** (`Cmd+Shift+P` → “Developer: Reload Window”)

## 3. Use skills in Agent chat

| Skill | How to invoke |
|-------|----------------|
| UI | Auto when editing `tab-*.jsx`, `components.jsx`, etc., or type `/vexperio-excel-addin-ui` |
| Integration | Type `/vexperio-excel-integration` (manual-only) |
| Test | Type `/vexperio-excel-addin-test` (manual-only) |
| Docs | Type `/vexperio-excel-addin-docs` (manual-only) |

Type `/` in **Agent** chat to see the skill list.

## 4. Optional: all projects (user skills)

Symlinks may exist at `~/.cursor/skills/` pointing here so the same skills work outside this repo. To recreate:

```bash
mkdir -p ~/.cursor/skills
for s in vexperio-excel-addin-ui vexperio-excel-integration vexperio-excel-addin-test vexperio-excel-addin-docs; do
  ln -sf "$(pwd)/.cursor/skills/$s" ~/.cursor/skills/$s
done
```

(Run from the `vexperio-db` repo root.)

## 5. Version control

Commit `.cursor/skills/` so teammates get the same skills after clone.

See [README.md](./README.md) for what each skill covers.
