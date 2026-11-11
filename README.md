# EGU27 · HS4.10 convener calendar

Checklist and calendar of convener tasks for EGU General Assembly 2027 session **HS4.10**, *Probabilistic and ensemble forecasting of streamflow and other environmental variables* (Vienna and online, 4–9 April 2027).

- **Page:** https://rafael3442.github.io/egu27-hs410/
- **Calendar feed:** https://rafael3442.github.io/egu27-hs410/egu27-hs410.ics

## Using it

- Tick items as you go. Ticks are saved in your own browser only, so each convener keeps their own.
- Subscribe to the calendar feed once to get every date in your calendar, with reminders before EGU deadlines:
  - Google Calendar: *Other calendars → + → From URL*, then paste the feed link.
  - Outlook: *Add calendar → Subscribe from web*, then paste the feed link.
  - Apple Calendar: *File → New Calendar Subscription*.
- **EGU date** items come from the EGU27 [deadlines and milestones](https://www.egu27.eu/about/deadlines_and_milestones.html) and [convener guidelines](https://www.egu27.eu/conveners/convener-guidelines.html), checked on 10 Nov 2026. **Team target** items are suggested dates for our own planning.

## Editing

All tasks live in the `tasks-data` JSON block in `index.html` (dates, details, links, and an `owner` field for initials such as `RF`). After an edit, rebuild the feed and commit both files:

```powershell
powershell -ExecutionPolicy Bypass -File tools/build-ics.ps1
```
