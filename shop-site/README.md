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
- `data.js`: talks to the API, or uses demo mode if the API isn't available
- `styles.css`, `logo.svg`, `favicon.svg`
- `../api/market.js`: the server (a Vercel serverless function)

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

## Going live

1. Create a free Upstash Redis database at https://upstash.com and copy its REST URL and token.
2. In your Vercel project settings, add these environment variables:
   - `UPSTASH_REDIS_REST_URL`
   - `UPSTASH_REDIS_REST_TOKEN`
   - `MARKET_ADMIN_KEY`: a long random password. You type it into the Staff page.
   - `STRIPE_SECRET_KEY`: from the Stripe dashboard. Use `sk_test_…` until you're ready.
   - `STRIPE_WEBHOOK_SECRET`: in Stripe → Developers → Webhooks, add `https://<your-site>/api/stripe-webhook` with the events
     `checkout.session.completed`, `checkout.session.async_payment_succeeded`, `checkout.session.async_payment_failed`,
     `checkout.session.expired` and `account.updated`, then copy its signing secret here.
   - Optional: `SITE_URL`, `MARKET_FEE_PCT` (default 3), `MARKET_FEE_FIXED` (default 0.30), `MARKET_COMMISSION_PCT` (default 5).
   - In Stripe, turn on **Connect** (for seller payouts), and turn on Apple Pay, Google Pay and Crypto under payment methods.
3. Deploy this repo with `shop-site` as the site's output folder, so `/api/market` and the pages are on the same domain.
   (The current `vercel.json` publishes `granite-lock/out` instead. Use a separate Vercel project for the market, or change that file.)

## Demo mode

If `/api/market` can't be reached (you opened the file directly, or the env vars aren't set),
the site shows a black "Demo mode" bar and saves everything in that browser only.
This is handy for trying it out, but other people won't see your listings.

## Before taking real money

- **Stripe's rules:** Stripe (and PayPal) don't allow selling game accounts, or in-game currency/items for games you don't run. If they find out, they can close your account and hold the money. Check their restricted businesses list, or use a payment provider that allows gaming marketplaces, before switching to live keys.
- **Holding other people's money** (escrow and payouts) can need a licence or registration where you live. Check before going live.
- Withdrawals are approved by hand on purpose, so staff can catch fraud such as a stolen card buying something to cash out.
