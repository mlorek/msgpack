# msg_pack for Ada

An Ada 2012 implementation of [MessagePack](https://github.com/msgpack/msgpack/blob/master/spec.md) serialization, packaged as an Alire library crate.

Covers the full base spec: nil, bool, signed/unsigned int (smallest-fit), float32, float64, str, bin, array & map headers, and the extension type (fixext 1/2/4/8/16 and ext 8/16/32).

## Prerequisites

[Alire](https://alire.ada.dev/) (`alr` on `PATH`). It pulls in the matching GNAT toolchain on first use.

## Build the library

```bash
alr build
```

Produces the static library at `lib/libMsg_Pack.a` and the compiled units under `obj/<build-profile>/`.

## Build and run the tests

The test program lives in a separate GPR (`tests/tests.gpr`) so the library has no test dependencies.

```bash
alr test                                     # builds tests + runs them
```

`alr test` invokes the `[[actions]]` of type `"test"` declared in `alire.toml`. The runner exits non-zero on any failure, so it's CI-friendly. To do the same thing manually:

```bash
alr build                                    # generates config/msg_pack_config.gpr
alr exec -- gprbuild -p -P tests/tests.gpr   # build the test binary
./tests/bin/test_main                        # run it
```

Expected tail of the output:

```
All tests passed.
```

## Use the library from your own crate

Add `msg_pack` as a dependency and `with` it:

```ada
with Msg_Pack;          use Msg_Pack;
with Msg_Pack.Packer;
with Msg_Pack.Unpacker;

procedure Example is
   Buf : Byte_Vector;
   Pos : Positive := 1;
begin
   Msg_Pack.Packer.Pack_String  (Buf, "hello");
   Msg_Pack.Packer.Pack_Integer (Buf, 42);

   declare
      Bytes : constant Byte_Array := To_Byte_Array (Buf);
      S     : constant String     :=
        Msg_Pack.Unpacker.Unpack_String (Bytes, Pos);
      N     : constant Interfaces.Integer_64 :=
        Msg_Pack.Unpacker.Unpack_Integer (Bytes, Pos);
   begin
      --  S = "hello", N = 42
      null;
   end;
end Example;
```

See `tests/src/sample_types.ads`/`.adb` for full examples of packing/unpacking user-defined record types (`Point` and `Person`) as MessagePack maps.

## License

MIT.
