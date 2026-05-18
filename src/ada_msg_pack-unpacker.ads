with Interfaces;

package Ada_Msg_Pack.Unpacker is

   type Msg_Kind is
     (Kind_Nil,
      Kind_Boolean,
      Kind_Integer,
      Kind_Unsigned,
      Kind_Float_32,
      Kind_Float_64,
      Kind_String,
      Kind_Binary,
      Kind_Array,
      Kind_Map,
      Kind_Extension);

   function Peek_Kind
     (Data : Byte_Array; Position : Positive) return Msg_Kind;

   procedure Unpack_Nil
     (Data : Byte_Array; Position : in out Positive);

   function Unpack_Boolean
     (Data : Byte_Array; Position : in out Positive) return Boolean;

   function Unpack_Integer
     (Data : Byte_Array; Position : in out Positive)
      return Interfaces.Integer_64;

   function Unpack_Unsigned
     (Data : Byte_Array; Position : in out Positive)
      return Interfaces.Unsigned_64;

   function Unpack_Float
     (Data : Byte_Array; Position : in out Positive)
      return Interfaces.IEEE_Float_32;

   function Unpack_Double
     (Data : Byte_Array; Position : in out Positive)
      return Interfaces.IEEE_Float_64;

   function Unpack_String
     (Data : Byte_Array; Position : in out Positive) return String;

   function Unpack_Binary
     (Data : Byte_Array; Position : in out Positive) return Byte_Array;

   type Extension (Length : Natural) is record
      Ext_Type : Interfaces.Integer_8;
      Payload  : Byte_Array (1 .. Length);
   end record;

   function Unpack_Extension
     (Data : Byte_Array; Position : in out Positive) return Extension;

   function Unpack_Array_Header
     (Data : Byte_Array; Position : in out Positive) return Natural;

   function Unpack_Map_Header
     (Data : Byte_Array; Position : in out Positive) return Natural;

end Ada_Msg_Pack.Unpacker;
