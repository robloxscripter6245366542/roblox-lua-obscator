// Vercel entry point for the "vaultix-market" project (root directory: shop-site).
// Re-exports the real handler, including its config (raw body for the signature check).
module.exports = require('../../api/stripe-webhook.js')
