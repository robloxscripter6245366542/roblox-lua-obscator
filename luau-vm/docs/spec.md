# Bytecode & ISA specification — v1

Versioned so serialized bytecode is forward-checkable. The version byte in the
header is bumped on any incompatible change; the loader rejects unknown versions
rather than mis-decoding.

## Container format

```
offset  bytes  field
0       3      magic  = "FVM"
3       1      version = 1
4       4      checksum (FNV-1a, 32-bit, little-endian) over body
8       4      bodyLength (little-endian)
12      …      body = proto (recursive)
```

The loader (`serializer.deserialize`) validates magic + version, then verifies
the FNV-1a checksum over the body before decoding — corrupt or tampered bytecode
fails closed.

## Integer & value encoding

- **Unsigned varint** (LEB128): 7 bits/byte, high bit = continuation.
- **Signed varint**: zig-zag (`n>=0 ? 2n : -2n-1`) then unsigned varint. Decoded
  with `math.floor` to keep an integer subtype on Lua 5.4.
- **String**: uvarint length + raw bytes.
- **Constant**: 1 tag byte + payload —
  `0 nil · 1 true · 2 false · 3 int(svarint) · 4 number(%.17g text) · 5 string`.
  Floats use `%.17g` so IEEE-754 doubles round-trip exactly without `string.pack`
  (portable across Lua 5.1+/Luau).

## Proto encoding

```
uvarint  numparams
byte     isVararg (0/1)
uvarint  maxstack
uvarint  numUpvals ;  repeat: byte kind(0=reg,1=up) , uvarint index
uvarint  numConsts ;  repeat: constant
uvarint  numCode   ;  repeat: byte op , then svarint per operand field
uvarint  numProtos ;  repeat: proto (recursive)
```

Instruction operand fields are those declared for the opcode in
`Opcodes.operands` (see [opcodes.md](opcodes.md)), so the encoder and decoder are
driven by a single source of truth and can never disagree.

## Determinism / reproducible builds

Compilation is a pure function of the source: the compiler uses no randomness,
timestamps, or map-iteration order in code generation, and constant dedup is
insertion-ordered. Therefore the same source yields **byte-identical** bytecode
(enforced by `test/determinism.lua`), and execution of a given program is
deterministic.

## Forward compatibility

- New opcodes append to the enum (existing numbers are stable) and add an entry
  to `Opcodes.operands`; old readers reject unknown ops via the checksum+version
  gate rather than silently.
- A format change (operand widths, new sections) bumps `version`; readers reject
  mismatches. A `version` negotiation table can be added when a v2 exists.

## ISA summary

Register-based, ~60 opcodes. Multi-value calls/returns/varargs use a count field
where `0` means "to top". Full opcode semantics and operand layouts:
[opcodes.md](opcodes.md). Architecture rationale: [architecture.md](architecture.md).
