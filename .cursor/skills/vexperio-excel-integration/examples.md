# Integration examples — Vexperio Excel add-in

## Example 1: Append tour with mirror

```javascript
await appendTourRow({
  id: "12345",
  name: "Nice Walking Tour",
  shorex: "NCE-WALK",
  status: "Published",
  port: "Nice",
});
await window.VEX_RELOAD?.();
```

**Expected:** New row at end of `France Shared (new)`; `POST /tours` attempted; on API failure, sync issue with Retry.

---

## Example 2: Write mapping columns + platform tour POST

```javascript
await writeMappingCols(rowNum, "GYG", {
  platformName: "Listing title",
  platformId: "GYG-999",
  status: "Active",
  link: "https://...",
}, vexId);
await window.VEX_RELOAD?.();
```

**Expected:** Cells X:AA on `rowNum` set; `mirrorToApi` calls `POST /platforms/2/tours` with external_id.

---

## Example 3: Schedule update without API ID

```javascript
await updateScheduleRow(row._row, { status: "cancelled" }, undefined);
await window.VEX_RELOAD?.();
```

**Expected:** Sheet column I updated; **no** `PATCH /schedules/{id}` because `scheduleId` omitted.

---

## Example 4: Retry sync issue

```javascript
import { retrySyncIssue, getSyncIssues } from "./api.js";

const issue = getSyncIssues()[0];
await retrySyncIssue(issue.id);
```

**Expected:** Re-runs stored `retry` fn; removes issue on success.

---

## Example 5: Link platform option

```javascript
await linkPlatformOption(platformOptionId, "OPT-42");
clearAllPlatformOptionsCache();
await window.VEX_RELOAD?.();
```

**Expected:** `PATCH /platform-options/{platformOptionId}`; Mappings tab reflects after reload.

---

## Example 6: Force load failure messaging

Open `dialog.html` in Chrome without Office:

**Expected:** `loadVEX` throws *Office.js not available*; error UI from `main.jsx` with Retry calling `VEX_RELOAD`.
