# Board Demonstration Script — Self-Healing Deployment

For: Nia, to read aloud while the pipeline runs.
Format: stage directions in brackets (may contain technical terms, not spoken); spoken lines in plain text.
Spoken word count: 216. The rollback figure of **12 seconds** is the measured value from `rollback-evidence.txt`.

---

**[Terminal 1 visible: `post-deploy-monitor.sh 90` running, showing green OK lines every 5 seconds. Terminal 2 ready with `switch-env.sh green`.]**

Good morning. In the next two minutes you will watch our payment system update itself, break on purpose, and repair itself — with nobody touching a keyboard after the break.

**[Point to Terminal 1's scrolling OK lines.]**

The window on the left is our watchdog. Every five seconds it asks the payment system, "are you healthy?" Right now, every answer is yes.

**[Run the switch in Terminal 2; the version field changes from 1.3 to 1.4.]**

We have just released a new version. Customers were never interrupted: we prepared the new version on standby, confirmed it was healthy, and only then moved customer traffic across. The old version stays running quietly in the background, ready to take over.

**[Run `systemctl stop kk-api-green` in Terminal 2. Say nothing for a beat.]**

Now we sabotage it. We have just given the new version a serious fault, the kind that once needed a person watching a screen at two in the morning.

**[Terminal 1 shows warnings, then ROLLBACK TRIGGERED, then healthy answers again.]**

Watch the left window. The watchdog notices the failed answers, decides the new version cannot be trusted, and moves every customer back to the proven old version. No pager. No phone call. No human.

**[Point to the healthy responses now showing version 1.3.]**

The system detected the problem and restored normal service in twelve seconds, measured, not estimated. The last time this happened with a person in the loop, it took four minutes. That difference, at fifty thousand requests an hour, is roughly three thousand payment attempts that now succeed instead of failing. That is what you are funding.

---

### Word-count and acronym check

- Spoken sections: 216 words (limit 250).
- Acronym scan of spoken text: no occurrences of nginx, SSH, CLI, API, SLO, SLI, HTTP, DNS, URL, or any other technical acronym. Technical terms appear only inside bracketed stage directions.
- "twelve seconds" matches T0→T2 = 12 s in `rollback-evidence.txt` exactly.
