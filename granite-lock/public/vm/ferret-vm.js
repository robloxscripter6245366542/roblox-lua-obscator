/* ferret-vm.js
 * Runs the validated luau-vm compiler in the browser via Fengari (Lua-in-JS) and
 * returns a self-contained VM-protected Luau script. Requires fengari-web.js and
 * modules.js (embedded Lua sources) to be loaded first.
 *
 * The user's source is compiled to custom bytecode and bundled with the VM
 * runtime + a base64 loader — no loadstring, no original source in the output.
 * Everything happens client-side; the source never leaves the page.
 */
(function () {
  'use strict';
  var L = null;

  function fengari() {
    if (!window.fengari) throw new Error('Fengari runtime not loaded');
    return window.fengari;
  }

  function initState() {
    var f = fengari();
    var lua = f.lua, lauxlib = f.lauxlib, lualib = f.lualib, tolua = f.to_luastring;
    var st = lauxlib.luaL_newstate();
    lualib.luaL_openlibs(st);

    // preload every compile-time module so require() resolves in-memory
    lua.lua_getglobal(st, tolua('package'));
    lua.lua_getfield(st, -1, tolua('preload'));
    var mods = window.LUAU_VM_MODULES;
    for (var name in mods) {
      if (!Object.prototype.hasOwnProperty.call(mods, name)) continue;
      if (lauxlib.luaL_loadbuffer(st, tolua(mods[name]), null, tolua('@' + name)) !== lua.LUA_OK) {
        throw new Error('luau-vm module "' + name + '": ' + f.to_jsstring(lua.lua_tostring(st, -1)));
      }
      lua.lua_setfield(st, -2, tolua(name)); // package.preload[name] = chunk
    }
    lua.lua_pop(st, 2);

    // expose runtime module sources (bundled into the output) as global RT
    lua.lua_newtable(st);
    var rt = window.LUAU_VM_RUNTIME;
    for (var rn in rt) {
      if (!Object.prototype.hasOwnProperty.call(rt, rn)) continue;
      lua.lua_pushstring(st, tolua(rt[rn]));
      lua.lua_setfield(st, -2, tolua(rn));
    }
    lua.lua_setglobal(st, tolua('RT'));
    return st;
  }

  // Compile Luau source -> self-contained VM-protected Luau string.
  function compile(source) {
    var f = fengari();
    var lua = f.lua, lauxlib = f.lauxlib, tolua = f.to_luastring;
    if (!L) L = initState();

    lua.lua_pushstring(L, tolua(source));
    lua.lua_setglobal(L, tolua('USER'));

    var driver = "local WB=require('webbundle') return WB.bundle(USER, RT, 'input')";
    if (lauxlib.luaL_dostring(L, tolua(driver)) !== lua.LUA_OK) {
      var err = f.to_jsstring(lua.lua_tostring(L, -1));
      lua.lua_pop(L, 1);
      throw new Error(err.replace(/^\[string [^\]]*\]:/, 'line '));
    }
    var out = f.to_jsstring(lua.lua_tostring(L, -1));
    lua.lua_pop(L, 1);
    return out;
  }

  window.FerretVM = { compile: compile, ready: function () { return !!window.fengari; } };
})();
