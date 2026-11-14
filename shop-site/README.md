# Vaultix Market

A game marketplace where anyone can sign up as a seller and post listings in six categories: Currency, Accounts, Top ups, Items, Boosting and Gift cards. Each listing names a game and can show an original price, which adds a discount tag.
It starts **empty**: there are no built-in products.

## How trust works

| Badge | Meaning |
| --- | --- |
| **Verified** (green) | The site owner checked this seller on the Staff page. |
| **Risky** (red) | Every new seller starts here. Buyers see a warning and have to click "I understand the risk" before the seller's contact details are shown. |

- Signing up gives the seller a secret token that's saved in their browser. Only that browser can post or delete that seller's listings, so nobody can post under someone else's name.
- Only someone with the admin key can verify, unverify or ban sellers. Banning also deletes all of that seller's listings.
- Buyers can switch on **Verified sellers only** to hide risky listings.
- Payments are held in escrow (see below). Contact details are only shown to the other side of an order and to staff.

## Game pictures

- Games listed in `games.js` (about 40: popular Roblox games, Fortnite, Minecraft, Pokemon Go, GTA V, and more) show their **official icon**.
  The API looks icons up live (Roblox thumbnails, App Store and Steam) and caches them, because Roblox icon links expire.
- For any other game, the seller picks **"Other game"**, types the name and **uploads their own picture**. The browser shrinks it,
  and the server only accepts real JPEG, PNG or WebP files up to 200 KB.
- To add a game, add a row to `games.js` with its Roblox universe ID, App Store app ID or Steam app ID.
- Game names, logos and icons belong to their owners. They're shown only to identify which game a listing is for.

## Files

- `index.html`, `app.js`: the market
- `admin.html`, `admin.js`: the Staff page (verify / ban sellers). It's linked as "Staff" in the footer.
- `games.js`: the game list (used by both the page and the API)
- `server.js`: the production server (site + API in one process); `dev-server.js` runs it with test data and a fake Stripe
- `data.js`: talks to the API, or uses demo mode if the API isn't available
- `styles.css`, `logo.svg`, `favicon.svg`
- `../api/market.js`: the server (a Vercel serverless function)

## Site owner

- The username **Kaitrades** is the site owner. To change or add owners, set `MARKET_OWNERS` to a comma-separated list of usernames.
- Owner usernames are **reserved**. When someone types one in the sign-up form, a **Staff password** box appears, and the account is only created if the password matches `MARKET_ADMIN_KEY`. So nobody else can take the name.
- The owner account gets a 👑 **Owner** badge and is always verified. It can't be banned or unverified, and it opens the **Staff page** without typing the password (via "Open Staff page" in the account menu).
- **To claim it on your live site:** once the database is set up, click the account icon, sign up as `Kaitrades`, and enter your `MARKET_ADMIN_KEY` as the staff password.

## Instant delivery (accounts, codes)

- When posting (it's switched on by default for **Accounts**), the seller ticks **⚡ Instant delivery** and adds one login per account: username and password, plus optional email, email password and notes. The stock is the number of logins.
- Logins are **encrypted** (AES-256-GCM) before they're stored. They never appear in listings or profiles. Only the buyer of that order, the seller and staff can see them.
- The moment an order is paid, the next login is handed out (each one goes to exactly one buyer) and shown on the buyer's order page with **Show** and **Copy** buttons.
- The money still stays in escrow. The buyer checks the login and confirms, or reports a problem if it doesn't work. A refunded login is not put back on sale.
- Set `MARKET_ENCRYPTION_KEY` (a long random string) on the server. If it's missing, a key is made from `MARKET_ADMIN_KEY`. **Don't change whichever key you use once logins are stored**, or they can't be read anymore.

## Checking listings are real (Staff → Listings)

- The Staff page has a **Listings** tab with everything for sale. Unchecked listings come first, and the tab shows how many are waiting.
- For ⚡ instant-delivery accounts, **🔍 View logins** opens the logins that haven't sold yet, so you can try them. Only staff and the owner can see them.
- **Remove bad login** deletes a login that doesn't work (stock goes down by one). **Remove listing** takes the whole listing down and deletes its unsold logins.
- **✓ Mark checked** adds a **"✓ Checked"** badge to the listing card, its details and checkout, so buyers can see staff tested it.

## Saved cards (one-click pay)

- On Stripe's checkout page, buyers can tick **"Save my card"**. They can also add or remove cards in the account menu → **Cards**.
- Next time, checkout shows **"Your saved cards"** (e.g. VISA •••• 4242 · *Pay in one click!*). Paying charges that card straight away. If the bank wants a security check (3-D Secure), Stripe shows it.
- **Card numbers are stored by Stripe, never by Vaultix.** The database only keeps each user's Stripe customer id. The site shows just the brand, the last 4 digits and the expiry date.
- Users can only pay with or remove their own cards.

## Buying, escrow and payouts

1. **Checkout:** the buyer picks card, Apple Pay, Google Pay, crypto or their Vaultix balance. Card, wallet and crypto payments happen on **Stripe's hosted checkout page**, so Vaultix never sees card numbers.
2. **Escrow:** Vaultix holds the money. The order page has a status tracker and a chat between buyer and seller.
3. **Delivery:** the seller adds the delivery details (login, trade info, code…), which only the buyer can see.
4. **Release:** the buyer confirms and leaves a 👍/👎 review, and the seller's share (price minus commission) becomes withdrawable. If the buyer doesn't respond, the order confirms itself 3 days after delivery.
5. **Problems:** the buyer can report a problem, which holds the money. Staff then **refund** the buyer or **release** the money to the seller on the Staff page. A seller who can't deliver can refund the buyer themselves.
6. **Wallet:** shows available, pending and earned money. The balance can be spent at checkout (no fee) or withdrawn by **bank or debit card (Stripe Connect)**, **PayPal**, **crypto (USDT/BTC/ETH/LTC)** or **bank transfer**. Staff approve every withdrawal. Stripe withdrawals are transferred automatically; for the others, staff send the money themselves and click "Mark as sent".
7. **Profiles:** clicking any seller opens a side panel with their badge, "Verified since", % positive, reviews, sales and listings. Your own panel has your purchases, sales, wallet, listings and profile settings.

Fees (change them with env vars): the buyer pays a payment fee of 3% + $0.30 (none when paying by balance), and the seller pays a 5% commission.

### Try it locally (no accounts needed)

```
node shop-site/dev-server.js
```

Open http://localhost:8787. The test data is saved in `shop-site/.dev-data.json`, and the Staff page key is `admin`.
Without `STRIPE_SECRET_KEY`, a **pretend Stripe** shows test "Pay" and "Finish setup" pages, so you can try buying, delivery, the wallet and withdrawals end to end.
With a real `sk_test_…` key it uses Stripe test mode. Forward webhooks with `stripe listen --forward-to localhost:8787/api/stripe-webhook`.

## Going live on Vercel (vaultix-market.vercel.app)

1. **Database (one click):** in Vercel open the **vaultix-market** project, go to the **Storage** tab, click **Create Database**, and choose **Upstash → Redis** (free plan). Connect it to the vaultix-market project.
   Vercel adds `KV_REST_API_URL` and `KV_REST_API_TOKEN` for you, and the site accepts those names as well as `UPSTASH_REDIS_REST_URL` / `UPSTASH_REDIS_REST_TOKEN`.
2. In **Settings → Environment Variables**, add `MARKET_ADMIN_KEY` (your staff password) and `MARKET_ENCRYPTION_KEY` (a long random string; never change it later).
3. **Redeploy:** Deployments → ⋯ → Redeploy. The black "Demo mode" bar disappears once the database is connected.
4. Sign up as **Kaitrades** with your `MARKET_ADMIN_KEY` in the Staff password box to become the owner.

## Going live (Render, free)

The site and API run as one small Node server (`shop-site/server.js`). `render.yaml` at the repo root tells Render how to run it.

1. **Put it online.** Sign up at https://render.com with GitHub, then go to **New → Blueprint**, pick this repository and click **Apply**.
   You can leave the settings empty for now. Your site is then live at `https://vaultix.onrender.com`, or `https://vaultix-xxxx.onrender.com` if that name is taken.
   It starts in **demo mode**.
   On the free plan the site goes to sleep after 15 minutes without visitors, and the next visit takes about a minute to wake it up.
2. **Database.** Create a free Redis database at https://upstash.com. In Render → your service → **Environment**, set
   `UPSTASH_REDIS_REST_URL` and `UPSTASH_REDIS_REST_TOKEN`, plus `MARKET_ADMIN_KEY` (a long random password for the Staff page)
   and `MARKET_ENCRYPTION_KEY` (another long random string, used to encrypt account logins; never change it later).
   Buyers and sellers now share one real market.
3. **Payments (Stripe test mode).**
   - Set `STRIPE_SECRET_KEY` (`sk_test_…`).
   - In Stripe → Developers → Webhooks, add `https://<your-site>.onrender.com/api/stripe-webhook` with the events
     `checkout.session.completed`, `checkout.session.async_payment_succeeded`, `checkout.session.async_payment_failed`,
     `checkout.session.expired`, `account.updated`, `payment_intent.succeeded` and `payment_intent.payment_failed`. Copy its signing secret into `STRIPE_WEBHOOK_SECRET`.
   - In Stripe, turn on **Connect** (for seller payouts) and turn on Apple Pay, Google Pay and Crypto under payment methods.
4. Optional settings: `SITE_URL` (only needed with a custom domain), `MARKET_FEE_PCT` (default 3), `MARKET_FEE_FIXED` (default 0.30),
   `MARKET_COMMISSION_PCT` (default 5).

Render redeploys automatically whenever `main` changes. You can also run the production server yourself with `node shop-site/server.js`.

## Demo mode

If `/api/market` can't be reached (you opened the file directly, or the env vars aren't set),
the site shows a black "Demo mode" bar and saves everything in that browser only.
This is handy for trying it out, but other people won't see your listings.

## Before taking real money

- **Stripe's rules:** Stripe (and PayPal) don't allow selling game accounts, or in-game currency/items for games you don't run. If they find out, they can close your account and hold the money. Check their restricted businesses list, or use a payment provider that allows gaming marketplaces, before switching to live keys.
- **Holding other people's money** (escrow and payouts) can need a licence or registration where you live. Check before going live.
- Withdrawals are approved by hand on purpose, so staff can catch fraud such as a stolen card buying something to cash out.
