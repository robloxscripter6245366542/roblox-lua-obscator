# Vaultix Market

A game marketplace where anyone can sign up as a seller and post listings in six categories: Currency, Accounts, Top ups, Items, Boosting and Gift cards. Each listing names a game and can show an original price, which adds a discount tag.
It starts **empty**: there are no built-in products.

## How trust works

| Badge | Meaning |
| --- | --- |
| **Verified** (green) | The site owner checked this seller on the Staff page. |
| **Risky** (red) | Every new seller starts here. Buyers see a warning and have to click "I understand the risk" before the seller's contact details are shown. |

- **Accounts:** sign up with a username, email and password (at least 8 characters). Sign in on any device with your email or username. Passwords are stored as salted scrypt hashes, never in plain text, and 8 wrong tries lock the account for 15 minutes. Each device gets its own sign-in token; changing the password signs out every other device.
- **Forgot password:** "Forgot your password?" under Sign in emails a link to the account's email. The link works once, for 30 minutes, and lets you pick a new password; saving it signs out every other device and unlocks a locked account. The page gives the same answer whether or not an email has an account, so nobody can use it to find out who's signed up. At most 1 email a minute and 5 an hour go to one account. Emails need `RESEND_API_KEY` (see "Emails" below).
- **Change notices:** when a password is changed, or the account's email is changed (the old address is told), Vaultix emails a notice with a "wasn't you?" reset link, so a stolen account doesn't go unnoticed.
- **Without email set up**, or for an older account that has no email, "Forgot your password?" tells people to message the site owner; staff use **Reset password** on the Staff page (after checking it's really that person) and send them a temporary password. Older accounts made before passwords existed can add an email and password under account menu → Profile.
- Only someone with the admin key can verify, unverify or ban sellers. Banning also deletes all of that seller's listings.
- Buyers can switch on **Verified sellers only** to hide risky listings.
- Payments are held in escrow (see below). Contact details are only shown to the other side of an order and to staff.

## Emails (forgot password)

Vaultix sends emails through [Resend](https://resend.com) (free for 3,000 emails a month).

1. Sign up at resend.com. Under **Domains**, add a domain you own and add the DNS records it shows, so emails don't land in spam.
2. Under **API Keys**, create a key with "Sending access".
3. On the server (Vercel: Settings → Environment Variables; Render: Environment), set:
   - `RESEND_API_KEY`: the key (`re_…`).
   - `MARKET_EMAIL_FROM`: the sender, e.g. `Vaultix <no-reply@your-domain.com>`, using the domain from step 1.
   - `SITE_URL`: your site's address, e.g. `https://vaultix-market.vercel.app`. Reset links are built from this (on Vercel and Render the site's own address is used if it's missing; never the address a request claims to come from).
4. Redeploy.

Without a verified domain, Resend only delivers to the email you signed up to Resend with, which is fine for a test but not for real users.
Without `RESEND_API_KEY`, everything else works and "Forgot your password?" points people to staff.
The local dev server doesn't send real emails: it prints them and lists them at http://localhost:8787/__dev/mail.

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

## Add funds (no card needed)

People without a card can top up their Vaultix balance by **bank transfer or crypto**, then spend it at checkout (no payment fee).

1. On the **Staff page → Add funds**, fill in where people should send money: your bank details and/or a crypto address per network (USDT TRC20/ERC20, BTC, ETH, LTC). Leave a box empty to turn that method off.
2. A user opens **Wallet → Add funds**, enters $5–$2,000 and picks a method. They get your details and a reference code (e.g. `VX-042F3F`) to put in the transfer note, send the money, and tap **I've sent it** (with the sender name or transaction ID).
3. On **Staff page → Add funds**, check the money really arrived, then click **Add to balance** and enter the amount that arrived (or **Reject**). Nothing is added automatically.

Added funds can be **spent but not withdrawn**: otherwise anyone could pass money through Vaultix. Purchases use added funds first, then sales earnings; only sales earnings can be withdrawn. A user can have at most 3 open requests.

## Saved cards (one-click pay)

- On Stripe's checkout page, buyers can tick **"Save my card"**. They can also add or remove cards in the account menu → **Cards**.
- Next time, checkout shows **"Your saved cards"** (e.g. VISA •••• 4242 · *Pay in one click!*). Paying charges that card straight away. If the bank wants a security check (3-D Secure), Stripe shows it.
- **Card numbers are stored by Stripe, never by Vaultix.** The database only keeps each user's Stripe customer id. The site shows just the brand, the last 4 digits and the expiry date.
- Users can only pay with or remove their own cards.

## Buying, escrow and payouts

1. **Checkout:** the buyer picks card, Apple Pay, Google Pay, crypto or their Vaultix balance. Card, wallet and crypto payments happen on **Stripe's hosted checkout page**, so Vaultix never sees card numbers. Stripe only gets the order number ("Vaultix Market order o_…"), not the game or listing title; the item is shown on the buyer's Vaultix order page.
2. **Escrow:** Vaultix holds the money. The order page has a status tracker and a chat between buyer and seller.
3. **Delivery:** the seller adds the delivery details (login, trade info, code…), which only the buyer can see.
4. **Release:** the buyer confirms and leaves a 👍/👎 review, and the seller's share (price minus commission) becomes withdrawable. If the buyer doesn't respond, the order confirms itself 3 days after delivery.
5. **All sales are final once delivered.** At checkout the buyer must tick "I understand there are no refunds once the item is delivered". After delivery the buyer can't report a problem and staff can't refund; the buyer must check the item straight away. **Before delivery** the buyer can still report that the seller isn't delivering, and staff can **refund** them (or the seller can refund). This protects buyers from scam sellers who take the money and never deliver, which would otherwise end up as chargebacks. Staff can always **release** money to the seller.
6. **Wallet:** shows available, pending and earned money. The balance can be spent at checkout (no fee) or withdrawn by **bank or debit card (Stripe Connect)**, **PayPal**, **crypto (USDT/BTC/ETH/LTC)** or **bank transfer**. Stripe withdrawals up to $200 per seller a day (`MARKET_AUTO_PAYOUT_MAX`) are sent automatically, with no staff step. Bigger ones, and any Stripe refuses (for example before the money is available in your Stripe balance), wait on the Staff page. For PayPal, crypto and bank transfer, staff send the money themselves and click "Mark as sent".
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
2. In **Settings → Environment Variables**, add `MARKET_ADMIN_KEY` (your staff password) and `MARKET_ENCRYPTION_KEY` (a long random string; never change it later). For "forgot password" emails, also add `RESEND_API_KEY`, `MARKET_EMAIL_FROM` and `SITE_URL` (see "Emails" above).
3. **Redeploy:** Deployments → ⋯ → Redeploy. The black "Demo mode" bar disappears once the database is connected.
4. Sign up as **Kaitrades** with your `MARKET_ADMIN_KEY` in the Staff password box to become the owner. If you already did that before passwords existed, open account menu → Profile and add an email and password, so you can sign in on any device.
5. **Stripe** (card payments, saved cards, seller payouts): follow "Stripe setup" below, using `https://vaultix-market.vercel.app/api/stripe-webhook` as the webhook URL.

## Stripe setup

Vaultix follows Stripe's current best practices:

- **Payments:** Stripe Checkout with *dynamic payment methods*, so the code doesn't list payment methods. Turn cards, Apple Pay, Google Pay, crypto and others on or off in Stripe → Settings → Payment methods.
- **Saved cards:** buyers get a Stripe Customer; Checkout offers "save my card", and one-click pay uses a PaymentIntent.
- **Seller payouts (Connect):** sellers get an Accounts v2 *recipient* account with the Express dashboard. Vaultix keeps the money in escrow and sends each seller's share with a transfer when they withdraw: automatically up to the daily limit, otherwise once staff approve it.
- **The API version is pinned** (`2026-10-28.endive`, change it with `STRIPE_API_VERSION`), and webhook signatures are always checked.

Steps:

1. **Use a test key first.** In Stripe (Test mode on) go to Developers → API keys. A **restricted key** (`rk_test_…`) is safer than the secret key: give it write access to Checkout Sessions, Customers, PaymentIntents, PaymentMethods, Refunds, Transfers, Connect Accounts/Account Links and read access to Tax. Put it in `STRIPE_SECRET_KEY`.
2. **Webhook:** Developers → Webhooks → Add endpoint `https://<your-site>/api/stripe-webhook` with the 7 events listed in "Going live (Render)" step 3. Copy its signing secret into `STRIPE_WEBHOOK_SECRET`.
3. **Connect (needed for seller payouts):** open Stripe → Connect and finish setup. Then go to **Settings → Connect → Platform profile** (https://dashboard.stripe.com/settings/connect/platform-profile) and complete the **loss-liability acknowledgement**. Because Vaultix holds money in escrow, Stripe requires the platform to accept responsibility for refunds/disputes it can't recover from sellers. Until this is done, "Connect with Stripe" shows an error.
4. **Stripe Tax (optional):** Tax is **off** by default. To turn it on: Stripe → Tax → Settings → set your business (head office) address and a default product tax code; then Tax → Registrations → add every place you're registered to collect tax; then set `STRIPE_TAX=on`. Without a registration Stripe collects **no** tax even when it's "on". With tax on, one-click payments go through Stripe's checkout page instead (it still shows saved cards), so tax can be added. Ask a tax advisor which registrations you need.
5. Redeploy.

Notes:
- Prices are in USD. If your Stripe account settles in another currency (for example AED), add a USD bank account or turn on USD settlement in Stripe, or seller transfers in USD can fail for lack of USD balance.
- Paying sellers in other countries from your platform depends on Stripe's cross-border payout rules for your country.

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
   - In Stripe, turn on **Connect** and complete the platform profile (see "Stripe setup" step 3), and turn on Apple Pay, Google Pay and Crypto under payment methods.
4. Optional settings: `RESEND_API_KEY` and `MARKET_EMAIL_FROM` ("forgot password" emails, see "Emails" above), `SITE_URL` (only needed with a custom domain), `MARKET_FEE_PCT` (default 3), `MARKET_FEE_FIXED` (default 0.30),
   `MARKET_COMMISSION_PCT` (default 5), `MARKET_AUTO_PAYOUT_MAX` (default 200; dollars per seller per day sent to Stripe without staff, 0 = staff approve every withdrawal).

Render redeploys automatically whenever `main` changes. You can also run the production server yourself with `node shop-site/server.js`.

## Demo mode

If `/api/market` can't be reached (you opened the file directly, or the env vars aren't set),
the site shows a black "Demo mode" bar and saves everything in that browser only.
This is handy for trying it out, but other people won't see your listings.

## Before taking real money

- **Stripe's rules:** Stripe (and PayPal) don't allow selling game accounts, or in-game currency/items for games you don't run. If they find out, they can close your account and hold the money. Check their restricted businesses list, or use a payment provider that allows gaming marketplaces, before switching to live keys.
- **Holding other people's money** (escrow and payouts) can need a licence or registration where you live. Check before going live.
- Small Stripe withdrawals go out automatically. That's convenient, but it means nobody looks before money leaves: someone with a stolen card could buy their own listing from a second account and cash out, and when the card owner disputes the payment, you pay it back. Keep `MARKET_AUTO_PAYOUT_MAX` low, or set it to 0 to approve every withdrawal by hand.
