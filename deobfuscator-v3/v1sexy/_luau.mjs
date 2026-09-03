const { LuauState, Mutable } = await import("luau-web");

const Mutated = Mutable([10, 20, 30]); // array, not object

const State = await LuauState.createAsync({
    print: (...args) => console.log(...args)
});

const Run = async (Code, ...Args) => await State.loadstring(Code, "chunk", true)(...Args);

const result = (await Run(`local tbl = {} for i = 1, 10000 do tbl[i] = true end return tbl`))[0];

const s = performance.now()
for (let i = 1; i < 10001; i++) {
    result.get(i)
}
console.log(performance.now()-s)