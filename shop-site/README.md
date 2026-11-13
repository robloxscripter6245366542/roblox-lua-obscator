# Vaultix Market

A marketplace where anyone can sign up as a seller and post listings (accounts, keys, items, services).
It starts **empty**: there are no built-in products.

## How trust works

| Badge | Meaning |
| --- | --- |
| **Verified** (green) | The site owner checked this seller on the Staff page. |
| **Risky** (red) | Every new seller starts here. Buyers see a warning and have to click "I understand the risk" before the seller's contact details are shown. |

- Signing up gives the seller a secret token that's saved in their browser. Only that browser can post or delete that seller's listings, so nobody can post under someone else's name.
- Only someone with the admin key can verify, unverify or ban sellers. Banning also deletes all of that seller's listings.
- Buyers can switch on **Verified sellers only** to hide risky listings.
- Vaultix doesn't handle payments. Buyers contact the seller directly.

## Files

- `index.html`, `app.js`: the market
- `admin.html`, `admin.js`: the Staff page (verify / ban sellers). It's linked as "Staff" in the footer.
- `data.js`: talks to the API, or uses demo mode if the API isn't available
- `styles.css`, `logo.svg`, `favicon.svg`
- `../api/market.js`: the server (a Vercel serverless function)

## Going live

1. Create a free Upstash Redis database at https://upstash.com and copy its REST URL and token.
2. In your Vercel project settings, add these environment variables:
   - `UPSTASH_REDIS_REST_URL`
   - `UPSTASH_REDIS_REST_TOKEN`
   - `MARKET_ADMIN_KEY`: a long random password. You type it into the Staff page.
3. Deploy this repo with `shop-site` as the site's output folder, so `/api/market` and the pages are on the same domain.
   (The current `vercel.json` publishes `granite-lock/out` instead. Use a separate Vercel project for the market, or change that file.)

## Demo mode

If `/api/market` can't be reached (you opened the file directly, or the env vars aren't set),
the site shows a black "Demo mode" bar and saves everything in that browser only.
This is handy for trying it out, but other people won't see your listings.
