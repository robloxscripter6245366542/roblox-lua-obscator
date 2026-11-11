# Media folder

Drop your company photos here. The bot sends these when a customer asks.

The filenames must match what's referenced in `../config.js`. By default:

| File           | Sent when the customer says…                          |
| -------------- | ----------------------------------------------------- |
| `catalog.jpg`  | catalog, products, menu, price, pricelist             |
| `location.jpg` | location, address, where, directions, map             |

To add more photos:

1. Put the image in this folder (`.jpg` or `.png`).
2. Add an entry to the `catalog` array in `../config.js` with the filename,
   the keywords that should trigger it, and a caption.

If a referenced file is missing, the bot logs a warning and sends the caption
as plain text instead of crashing — so it's safe to run before you've added
all your images.
