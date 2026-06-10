with Interfaces;          use Interfaces;
with Ada.Containers;      use Ada.Containers;
with Ada.Unchecked_Conversion;

package body Msg_Pack.Packer is

   function To_U32 is new
     Ada.Unchecked_Conversion (IEEE_Float_32, Unsigned_32);
   function To_U64 is new
     Ada.Unchecked_Conversion (IEEE_Float_64, Unsigned_64);
   function To_U64 is new
     Ada.Unchecked_Conversion (Integer_64, Unsigned_64);
   function To_U8 is new
     Ada.Unchecked_Conversion (Integer_8, Unsigned_8);

   procedure Append_U16_BE (Buffer : in out Byte_Vector; V : Unsigned_16);
   procedure Append_U32_BE (Buffer : in out Byte_Vector; V : Unsigned_32);
   procedure Append_U64_BE (Buffer : in out Byte_Vector; V : Unsigned_64);
   pragma Inline (Append_U16_BE, Append_U32_BE, Append_U64_BE);

   --  Smallest-fit width selector for u8/u16/u32-length headers
   --  (str/bin/ext after the fixstr/fixext fast paths).
   procedure Append_Sized_Header
     (Buffer : in out Byte_Vector;
      Len    : Natural;
      Tag_8, Tag_16, Tag_32 : Byte);

   --  Smallest-fit width selector for u16/u32-length headers
   --  (array/map; the spec has no u8-length variant for these).
   procedure Append_Sized_Big_Header
     (Buffer : in out Byte_Vector;
      Len    : Natural;
      Tag_16, Tag_32 : Byte);
   pragma Inline (Append_Sized_Header, Append_Sized_Big_Header);

   procedure Append_U16_BE (Buffer : in out Byte_Vector; V : Unsigned_16) is
   begin
      Buffer.Append (Byte (Shift_Right (V, 8) and 16#FF#));
      Buffer.Append (Byte (V and 16#FF#));
   end Append_U16_BE;

   procedure Append_U32_BE (Buffer : in out Byte_Vector; V : Unsigned_32) is
   begin
      Buffer.Append (Byte (Shift_Right (V, 24) and 16#FF#));
      Buffer.Append (Byte (Shift_Right (V, 16) and 16#FF#));
      Buffer.Append (Byte (Shift_Right (V,  8) and 16#FF#));
      Buffer.Append (Byte (V and 16#FF#));
   end Append_U32_BE;

   procedure Append_U64_BE (Buffer : in out Byte_Vector; V : Unsigned_64) is
   begin
      Buffer.Append (Byte (Shift_Right (V, 56) and 16#FF#));
      Buffer.Append (Byte (Shift_Right (V, 48) and 16#FF#));
      Buffer.Append (Byte (Shift_Right (V, 40) and 16#FF#));
      Buffer.Append (Byte (Shift_Right (V, 32) and 16#FF#));
      Buffer.Append (Byte (Shift_Right (V, 24) and 16#FF#));
      Buffer.Append (Byte (Shift_Right (V, 16) and 16#FF#));
      Buffer.Append (Byte (Shift_Right (V,  8) and 16#FF#));
      Buffer.Append (Byte (V and 16#FF#));
   end Append_U64_BE;

   procedure Append_Sized_Header
     (Buffer : in out Byte_Vector;
      Len    : Natural;
      Tag_8, Tag_16, Tag_32 : Byte) is
   begin
      if Len <= 16#FF# then
         Buffer.Append (Tag_8);
         Buffer.Append (Byte (Len));
      elsif Len <= 16#FFFF# then
         Buffer.Append (Tag_16);
         Append_U16_BE (Buffer, Unsigned_16 (Len));
      else
         Buffer.Append (Tag_32);
         Append_U32_BE (Buffer, Unsigned_32 (Len));
      end if;
   end Append_Sized_Header;

   procedure Append_Sized_Big_Header
     (Buffer : in out Byte_Vector;
      Len    : Natural;
      Tag_16, Tag_32 : Byte) is
   begin
      if Len <= 16#FFFF# then
         Buffer.Append (Tag_16);
         Append_U16_BE (Buffer, Unsigned_16 (Len));
      else
         Buffer.Append (Tag_32);
         Append_U32_BE (Buffer, Unsigned_32 (Len));
      end if;
   end Append_Sized_Big_Header;

   procedure Pack_Nil (Buffer : in out Byte_Vector) is
   begin
      Buffer.Append (16#C0#);
   end Pack_Nil;

   procedure Pack_Boolean (Buffer : in out Byte_Vector; Value : Boolean) is
   begin
      if Value then
         Buffer.Append (16#C3#);
      else
         Buffer.Append (16#C2#);
      end if;
   end Pack_Boolean;

   procedure Pack_Unsigned
     (Buffer : in out Byte_Vector; Value : Unsigned_64) is
   begin
      if Value <= 16#7F# then
         Buffer.Append (Byte (Value));
      elsif Value <= 16#FF# then
         Buffer.Append (16#CC#);
         Buffer.Append (Byte (Value));
      elsif Value <= 16#FFFF# then
         Buffer.Append (16#CD#);
         Append_U16_BE (Buffer, Unsigned_16 (Value));
      elsif Value <= 16#FFFF_FFFF# then
         Buffer.Append (16#CE#);
         Append_U32_BE (Buffer, Unsigned_32 (Value));
      else
         Buffer.Append (16#CF#);
         Append_U64_BE (Buffer, Value);
      end if;
   end Pack_Unsigned;

   procedure Pack_Integer
     (Buffer : in out Byte_Vector; Value : Integer_64)
   is
      U64 : constant Unsigned_64 := To_U64 (Value);
   begin
      if Value >= 0 then
         Pack_Unsigned (Buffer, U64);
      elsif Value >= -32 then
         --  negative fixint (5-bit, sign-extends to byte 0xE0..0xFF)
         Buffer.Append (Byte (U64 and 16#FF#));
      elsif Value >= -128 then
         Buffer.Append (16#D0#);
         Buffer.Append (Byte (U64 and 16#FF#));
      elsif Value >= -32768 then
         Buffer.Append (16#D1#);
         Append_U16_BE (Buffer, Unsigned_16 (U64 and 16#FFFF#));
      elsif Value >= -(2 ** 31) then
         Buffer.Append (16#D2#);
         Append_U32_BE (Buffer, Unsigned_32 (U64 and 16#FFFF_FFFF#));
      else
         Buffer.Append (16#D3#);
         Append_U64_BE (Buffer, U64);
      end if;
   end Pack_Integer;

   procedure Pack_Float
     (Buffer : in out Byte_Vector; Value : IEEE_Float_32) is
   begin
      Buffer.Append (16#CA#);
      Append_U32_BE (Buffer, To_U32 (Value));
   end Pack_Float;

   procedure Pack_Double
     (Buffer : in out Byte_Vector; Value : IEEE_Float_64) is
   begin
      Buffer.Append (16#CB#);
      Append_U64_BE (Buffer, To_U64 (Value));
   end Pack_Double;

   procedure Pack_String (Buffer : in out Byte_Vector; Value : String) is
      Len : constant Natural := Value'Length;
   begin
      Buffer.Reserve_Capacity (Buffer.Length + Count_Type (Len) + 5);
      if Len <= 31 then
         Buffer.Append (16#A0# or Byte (Len));
      else
         Append_Sized_Header (Buffer, Len, 16#D9#, 16#DA#, 16#DB#);
      end if;
      for C of Value loop
         Buffer.Append (Byte (Character'Pos (C)));
      end loop;
   end Pack_String;

   procedure Pack_Binary (Buffer : in out Byte_Vector; Value : Byte_Array) is
      Len : constant Natural := Value'Length;
   begin
      Buffer.Reserve_Capacity (Buffer.Length + Count_Type (Len) + 5);
      Append_Sized_Header (Buffer, Len, 16#C4#, 16#C5#, 16#C6#);
      for B of Value loop
         Buffer.Append (B);
      end loop;
   end Pack_Binary;

   procedure Pack_Extension
     (Buffer   : in out Byte_Vector;
      Ext_Type : Integer_8;
      Data     : Byte_Array)
   is
      Len : constant Natural := Data'Length;
   begin
      Buffer.Reserve_Capacity (Buffer.Length + Count_Type (Len) + 6);
      case Len is
         when 1  => Buffer.Append (16#D4#);
         when 2  => Buffer.Append (16#D5#);
         when 4  => Buffer.Append (16#D6#);
         when 8  => Buffer.Append (16#D7#);
         when 16 => Buffer.Append (16#D8#);
         when others =>
            Append_Sized_Header (Buffer, Len, 16#C7#, 16#C8#, 16#C9#);
      end case;
      Buffer.Append (To_U8 (Ext_Type));
      for B of Data loop
         Buffer.Append (B);
      end loop;
   end Pack_Extension;

   procedure Pack_Array_Header
     (Buffer : in out Byte_Vector; Length : Natural) is
   begin
      if Length <= 15 then
         Buffer.Append (16#90# or Byte (Length));
      else
         Append_Sized_Big_Header (Buffer, Length, 16#DC#, 16#DD#);
      end if;
   end Pack_Array_Header;

   procedure Pack_Map_Header
     (Buffer : in out Byte_Vector; Length : Natural) is
   begin
      if Length <= 15 then
         Buffer.Append (16#80# or Byte (Length));
      else
         Append_Sized_Big_Header (Buffer, Length, 16#DE#, 16#DF#);
      end if;
   end Pack_Map_Header;

end Msg_Pack.Packer;
