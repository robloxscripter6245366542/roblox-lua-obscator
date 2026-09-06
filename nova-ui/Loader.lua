--[[
	NovaUI • Loader — load the whole shop UI from a Roblox asset id
	======================================================================
	Turn the NovaUI folder into ONE asset you (or anyone) can load with a
	single line. Two supported ways, depending on how you published it.

	----------------------------------------------------------------------
	OPTION A — Model asset (recommended, keeps all modules together)
	----------------------------------------------------------------------
	1. In Studio, put the NovaUI ModuleScripts inside a Folder named
	   "NovaUI" (Themes, Shop, Presets, Animations, ShopPacks, ShopHub).
	2. Right-click the folder ▸ "Save to Roblox…" → publish it. Copy the
	   asset id from the Creator Dashboard (Development Item → your model).
	3. Load it at runtime (this pattern; a Script or LocalScript):

		local InsertService = game:GetService("InsertService")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")

		local ASSET_ID = 0            -- ← your published model asset id
		local imported = InsertService:LoadAsset(ASSET_ID)
		local folder = imported:FindFirstChild("NovaUI")
		folder.Parent = ReplicatedStorage
		imported:Destroy()

		local ShopHub = require(folder.ShopHub)
		ShopHub.launch({
			Accent = Color3.fromRGB(255, 40, 45),
			GamePasses = { x2Coins = 0, VIP = 0 },  -- your real ids
		})

	   Notes: LoadAsset runs on the server; for a client-only menu, load on
	   the server and put the folder in ReplicatedStorage (as above) so the
	   client can require it, then run ShopHub.launch from a LocalScript.

	----------------------------------------------------------------------
	OPTION B — Single bundled ModuleScript (one require, no folder)
	----------------------------------------------------------------------
	If you build a single combined ModuleScript that returns ShopHub and
	inlines its dependencies, publish THAT script and load it directly:

		local ShopHub = require(ASSET_ID)     -- your module asset id
		ShopHub.launch({ Accent = Color3.fromRGB(255,40,45), GamePasses = {} })

	   `require(assetId)` works client-side for a ModuleScript you own or
	   that is public. A plain multi-file require needs its siblings, so use
	   Option A unless you have bundled everything into one file.

	----------------------------------------------------------------------
	Game passes
	----------------------------------------------------------------------
	Every item in ShopPacks that has `Pass = "<name>"` is wired to a game
	pass. Put your real ids in the `GamePasses` map above (name = id). The
	buy button then calls MarketplaceService:PromptGamePassPurchase, and with
	CheckOwnership on, passes the player already owns show as “Owned”.
]]

return nil
