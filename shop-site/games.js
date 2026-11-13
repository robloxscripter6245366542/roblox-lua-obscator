// Vaultix game catalogue — shared by the page (window.VAULTIX_GAMES) and the API (require).
// Icons are looked up at runtime by api/market.js?action=icons because Roblox icon URLs expire:
//   roblox: Roblox universe ID  -> thumbnails.roblox.com game icon
//   apple:  App Store app ID    -> itunes.apple.com artwork
//   steam:  Steam app ID        -> fixed Steam header image
// To add a game, add a row here. Anything not listed is "Other": the seller uploads their own image.
(function (root) {
  const GAMES = [
    // Roblox platform + experiences
    { name: "Roblox", apple: 431946152 },
    { name: "Blox Fruits", roblox: 994732206 },
    { name: "Grow a Garden", roblox: 7436755782 },
    { name: "Steal a Brainrot", roblox: 7709344486 },
    { name: "Murder Mystery 2", roblox: 66654135 },
    { name: "Adopt Me", roblox: 383310974 },
    { name: "Pet Simulator 99", roblox: 3317771874 },
    { name: "Blade Ball", roblox: 4777817887 },
    { name: "Brookhaven", roblox: 1686885941 },
    { name: "99 Nights in the Forest", roblox: 7326934954 },
    { name: "The Strongest Battlegrounds", roblox: 3808081382 },
    { name: "Rivals", roblox: 6035872082 },
    { name: "Jailbreak", roblox: 245662005 },
    { name: "Da Hood", roblox: 1008451066 },
    { name: "Doors", roblox: 2440500124 },
    { name: "Dress to Impress", roblox: 5203828273 },
    { name: "Fisch", roblox: 5750914919 },
    { name: "Jujutsu Shenanigans", roblox: 3508322461 },
    { name: "Blue Lock: Rivals", roblox: 6325068386 },
    { name: "King Legacy", roblox: 1451439645 },
    { name: "Dead Rails", roblox: 7018190066 },
    { name: "Forsaken", roblox: 6331902150 },
    { name: "Bee Swarm Simulator", roblox: 601130232 },
    { name: "Arsenal", roblox: 111958650 },
    { name: "Tower of Hell", roblox: 703124385 },
    { name: "Prison Life", roblox: 73885730 },
    // Mobile / cross-platform
    { name: "Fortnite", apple: 6483539426 },
    { name: "Minecraft", apple: 479516143 },
    { name: "Pokemon Go", apple: 1094591345 },
    { name: "Clash of Clans", apple: 529479190 },
    { name: "Clash Royale", apple: 1053012308 },
    { name: "Brawl Stars", apple: 1229016807 },
    { name: "Call of Duty: Mobile", apple: 1287282214 },
    { name: "Genshin Impact", apple: 1517783697 },
    // PC (Steam)
    { name: "Steam", apple: 495369748 },
    { name: "GTA V", steam: 271590 },
    { name: "Counter-Strike 2", steam: 730 },
    { name: "Rust", steam: 252490 },
    { name: "Dota 2", steam: 570 },
    { name: "Apex Legends", steam: 1172470 },
    { name: "Rainbow Six Siege", steam: 359550 },
  ];
  const find = (name) => {
    const k = String(name || "").trim().toLowerCase();
    return GAMES.find((g) => g.name.toLowerCase() === k) || null;
  };
  const steamIcon = (id) => `https://cdn.cloudflare.steamstatic.com/steam/apps/${id}/header.jpg`;
  const api = { GAMES, find, steamIcon };
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  else root.VAULTIX_GAMES = api;
})(typeof self !== "undefined" ? self : this);
