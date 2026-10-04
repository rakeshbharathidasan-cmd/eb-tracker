# ⚡ EB Tracker

Daily electricity tracker for **Ground Floor** and **First Floor**, with TN slab pricing, a 500-unit "cliff" dial, a calendar, stats and reports. Two people share one live database.

**Stack:** one static web app (GitHub Pages) + Supabase (database, login, live sync). Free tiers are enough.

---

## 1. Try it first (no setup)
Open `index.html` in a browser. With no Supabase keys it runs in **demo mode** with sample data saved only on that device.

## 2. Supabase (about 10 min)
1. Create a project at **supabase.com** (Region: Mumbai `ap-south-1`).
2. **SQL Editor → New query** → paste all of `schema.sql`. At the bottom, replace `you@example.com` / `wife@example.com` with your two real emails → **Run**.
3. **Authentication → Users → Add user → Create new user** for each of you (email + password, tick *Auto Confirm User*).
4. **Authentication → Sign In / Providers → Email**: turn **off** "Allow new users to sign up" so nobody else can create an account.
5. **Project Settings → API**: copy the **Project URL** and the **anon / publishable key**.
6. In `index.html`, near the top, paste them into:
   ```js
   SUPABASE_URL: "https://xxxx.supabase.co",
   SUPABASE_ANON_KEY: "eyJ..."
   ```
   The anon key is meant to be public. Your data is protected by login and the `household_members` allow-list (row-level security).

## 3. GitHub Pages
1. Create a new repo on GitHub, e.g. `eb-tracker`.
2. **Add file → Upload files** → drop in `index.html`, `manifest.json`, `sw.js`, `icon-192.png`, `icon-512.png` → Commit. (`schema.sql` and this README are optional.)
3. **Settings → Pages → Source: Deploy from a branch → `main` / root** → Save.
4. After about a minute the app is live at `https://<your-username>.github.io/eb-tracker/`.
5. On each phone, open the link in Chrome → ⋮ → **Add to Home screen**. It opens full-screen like an app.

## 4. First use
- **Settings → Display name**, so entries show "Rakesh" / your wife's name.
- **Home → Set up Ground Floor / First Floor** (or **New cycle / reset** later):
  - **EB reading taken — reset to 0**: use this on the day the assessor reads the meter. Enter today's meter reading if you'll log by meter reading.
  - **Joining mid-cycle**: enter the date the cycle began (last EB reading) and the units used so far, or let the app calculate them from *EB card reading* and *meter now*. Logs from the *as-of* date are added on top.
- **+ button** daily: pick a floor, enter the **meter reading** (the app works out the units) or **units used**. Every entry records who logged it and when. If you skip days, the app offers to spread the units across the missing days.

## Tariff used (TN domestic, from 10 May 2026, per 2-month cycle)
| ≤ 500 units | Rate | > 500 units (whole bill re-prices) | Rate |
|---|---|---|---|
| 0–200 | Free | 0–100 | Free |
| 201–400 | ₹4.70 | 101–400 | ₹4.70 |
| 401–500 | ₹6.30 | 401–500 | ₹6.30 |
| | | 501–600 | ₹8.40 |
| | | 601–800 | ₹9.45 |
| | | 801–1000 | ₹10.50 |
| | | 1000+ | ₹11.55 |

Check: 500 u = ₹1,570 · 510 u = ₹2,124 · 600 u = ₹2,880. You can edit all slabs, fixed charges, cycle length, and separate/combined meter in **Settings**.

**Daily cost** is the slab cost of that day's units within the running cycle. A day that crosses 500 carries the full re-pricing jump, because that's the day it happened.
