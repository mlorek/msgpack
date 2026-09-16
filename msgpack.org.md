# MessagePack for Ada

An Ada 2012 implementation of MessagePack, available as an [Alire](https://alire.ada.dev/) crate.
It supports every MessagePack type (nil, boolean, integer, float, string, binary, array, map and extension), and integers and lengths are always packed in the smallest encoding that fits.

## Install

In your Alire crate:

```sh
alr with msg_pack
```

Alire adds `msg_pack.gpr` to your build, so `with Msg_Pack;` works right away.

## Example

```ada
with Ada.Text_IO;       use Ada.Text_IO;
with Interfaces;        use Interfaces;
with Msg_Pack;          use Msg_Pack;
with Msg_Pack.Packer;   use Msg_Pack.Packer;
with Msg_Pack.Unpacker; use Msg_Pack.Unpacker;

procedure Example is
   Buffer : Byte_Vector;
   Pos    : Positive := 1;
begin
   --  Encode ["hello", 42]
   Pack_Array_Header (Buffer, 2);
   Pack_String (Buffer, "hello");
   Pack_Integer (Buffer, 42);

   --  Decode it again; each Unpack_* call advances Pos
   declare
      Data  : constant Byte_Array := To_Byte_Array (Buffer);
      Count : constant Natural    := Unpack_Array_Header (Data, Pos);
      Text  : constant String     := Unpack_String (Data, Pos);
      Num   : constant Integer_64 := Unpack_Integer (Data, Pos);
   begin
      Put_Line ("items:" & Natural'Image (Count));  --  items: 2
      Put_Line (Text & Integer_64'Image (Num));     --  hello 42
   end;
end Example;
```

## Usage notes

* Packing appends to a `Byte_Vector`. `To_Byte_Array` turns it into the `Byte_Array` that the unpacker reads.
* Arrays and maps are written as a header with the element count, followed by the elements. For a map, pack each key and then its value.
* For data whose shape you don't know in advance, `Peek_Kind (Data, Pos)` returns the kind of the next value without consuming it. Non-negative integers are encoded in the unsigned formats, so treat `Kind_Unsigned` like `Kind_Integer`; `Unpack_Integer` reads both.
* Reading a value as the wrong type, or past the end of the data, raises `Msg_Pack.Format_Error`.

## Links

* Source and README: https://github.com/mlorek/msgpack
* Packing your own record types as maps: [sample_types.adb](https://github.com/mlorek/msgpack/blob/main/tests/src/sample_types.adb)
* Alire crate page: https://alire.ada.dev/crates/msg_pack
