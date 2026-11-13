# Vaultix storefront

Static shop site (no build step): `index.html`, `styles.css`, `app.js`, `logo.svg`.

- **Edit products:** change the `PRODUCTS` array at the top of `app.js` (name, category, price, emoji icon, card colors, optional `was` price and `tag`: `hot` / `new` / `sale`). Categories are built from the products automatically.
- **Run locally:** `python3 -m http.server` inside this folder, then open http://localhost:8000.
- **Payments:** checkout is a demo — it shows a confirmation but charges nothing. Hook the `#payForm` submit handler in `app.js` up to Stripe Checkout, PayPal, or a digital-goods platform (Sellix, Sellpass, etc.) before taking real orders.
