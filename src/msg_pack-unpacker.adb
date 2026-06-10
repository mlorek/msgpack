with Interfaces;          use Interfaces;
with Ada.Unchecked_Conversion;

package body Msg_Pack.Unpacker is

   function To_Float is new
     Ada.Unchecked_Conversion (Unsigned_32, IEEE_Float_32);
   function To_Double is new
     Ada.Unchecked_Conversion (Unsigned_64, IEEE_Float_64);
   function To_Int64 is new
     Ada.Unchecked_Conversion (Unsigned_64, Integer_64);
   function To_Int8 is new
     Ada.Unchecked_Conversion (Unsigned_8, Integer_8);

   procedure Require
     (Data : Byte_Array; Position : Positive; Count : Natural);
   pragma Inline (Require);

   function Read_U8
     (Data : Byte_Array; Position : in out Positive) return Unsigned_8;
   function Read_U16_BE
     (Data : Byte_Array; Position : in out Positive) return Unsigned_16;
   function Read_U32_BE
     (Data : Byte_Array; Position : in out Positive) return Unsigned_32;
   function Read_U64_BE
     (Data : Byte_Array; Position : in out Positive) return Unsigned_64;
   pragma Inline (Read_U8, Read_U16_BE, Read_U32_BE, Read_U64_BE);

   procedure Require
     (Data : Byte_Array; Position : Positive; Count : Natural) is
   begin
      if Count > 0 and then Position + Count - 1 > Data'Last then
         raise Format_Error with "truncated input";
      end if;
   end Require;

   function Read_U8
     (Data : Byte_Array; Position : in out Positive) return Unsigned_8
   is
      B : Unsigned_8;
   begin
      Require (Data, Position, 1);
      B := Data (Position);
      Position := Position + 1;
      return B;
   end Read_U8;

   function Read_U16_BE
     (Data : Byte_Array; Position : in out Positive) return Unsigned_16
   is
      B0, B1 : Unsigned_8;
   begin
      Require (Data, Position, 2);
      B0 := Data (Position);
      B1 := Data (Position + 1);
      Position := Position + 2;
      return Shift_Left (Unsigned_16 (B0), 8) or Unsigned_16 (B1);
   end Read_U16_BE;

   function Read_U32_BE
     (Data : Byte_Array; Position : in out Positive) return Unsigned_32
   is
      R : Unsigned_32 := 0;
   begin
      Require (Data, Position, 4);
      for I in 0 .. 3 loop
         R := Shift_Left (R, 8) or Unsigned_32 (Data (Position + I));
      end loop;
      Position := Position + 4;
      return R;
   end Read_U32_BE;

   function Read_U64_BE
     (Data : Byte_Array; Position : in out Positive) return Unsigned_64
   is
      R : Unsigned_64 := 0;
   begin
      Require (Data, Position, 8);
      for I in 0 .. 7 loop
         R := Shift_Left (R, 8) or Unsigned_64 (Data (Position + I));
      end loop;
      Position := Position + 8;
      return R;
   end Read_U64_BE;

   function Sign_Extend_16 (V : Unsigned_16) return Integer_64 is
   begin
      if (V and 16#8000#) /= 0 then
         return Integer_64 (V) - 2 ** 16;
      else
         return Integer_64 (V);
      end if;
   end Sign_Extend_16;

   function Sign_Extend_32 (V : Unsigned_32) return Integer_64 is
   begin
      if (V and 16#8000_0000#) /= 0 then
         return Integer_64 (V) - 2 ** 32;
      else
         return Integer_64 (V);
      end if;
   end Sign_Extend_32;

   function Peek_Kind
     (Data : Byte_Array; Position : Positive) return Msg_Kind
   is
      B : Unsigned_8;
   begin
      if Position > Data'Last then
         raise Format_Error with "empty input";
      end if;
      B := Data (Position);
      case B is
         when 16#00# .. 16#7F# => return Kind_Unsigned;
         when 16#80# .. 16#8F# => return Kind_Map;
         when 16#90# .. 16#9F# => return Kind_Array;
         when 16#A0# .. 16#BF# => return Kind_String;
         when 16#C0#           => return Kind_Nil;
         when 16#C2# | 16#C3#  => return Kind_Boolean;
         when 16#C4# .. 16#C6# => return Kind_Binary;
         when 16#C7# .. 16#C9# => return Kind_Extension;
         when 16#CA#           => return Kind_Float_32;
         when 16#CB#           => return Kind_Float_64;
         when 16#CC# .. 16#CF# => return Kind_Unsigned;
         when 16#D0# .. 16#D3# => return Kind_Integer;
         when 16#D4# .. 16#D8# => return Kind_Extension;
         when 16#D9# .. 16#DB# => return Kind_String;
         when 16#DC# .. 16#DD# => return Kind_Array;
         when 16#DE# .. 16#DF# => return Kind_Map;
         when 16#E0# .. 16#FF# => return Kind_Integer;
         when others           => raise Format_Error with "reserved type byte";
      end case;
   end Peek_Kind;

   procedure Unpack_Nil
     (Data : Byte_Array; Position : in out Positive)
   is
      B : constant Unsigned_8 := Read_U8 (Data, Position);
   begin
      if B /= 16#C0# then
         raise Format_Error with "expected nil";
      end if;
   end Unpack_Nil;

   function Unpack_Boolean
     (Data : Byte_Array; Position : in out Positive) return Boolean
   is
      B : constant Unsigned_8 := Read_U8 (Data, Position);
   begin
      case B is
         when 16#C2# => return False;
         when 16#C3# => return True;
         when others => raise Format_Error with "expected boolean";
      end case;
   end Unpack_Boolean;

   function Unpack_Unsigned
     (Data : Byte_Array; Position : in out Positive) return Unsigned_64
   is
      B : constant Unsigned_8 := Read_U8 (Data, Position);
   begin
      case B is
         when 16#00# .. 16#7F# => return Unsigned_64 (B);
         when 16#CC# => return Unsigned_64 (Read_U8  (Data, Position));
         when 16#CD# => return Unsigned_64 (Read_U16_BE (Data, Position));
         when 16#CE# => return Unsigned_64 (Read_U32_BE (Data, Position));
         when 16#CF# => return Read_U64_BE (Data, Position);
         when others => raise Format_Error with "expected unsigned integer";
      end case;
   end Unpack_Unsigned;

   function Unpack_Integer
     (Data : Byte_Array; Position : in out Positive) return Integer_64
   is
      B : constant Unsigned_8 := Read_U8 (Data, Position);
   begin
      case B is
         when 16#00# .. 16#7F# =>
            return Integer_64 (B);
         when 16#E0# .. 16#FF# =>
            return Integer_64 (B) - 2 ** 8;
         when 16#CC# =>
            return Integer_64 (Read_U8 (Data, Position));
         when 16#CD# =>
            return Integer_64 (Read_U16_BE (Data, Position));
         when 16#CE# =>
            return Integer_64 (Read_U32_BE (Data, Position));
         when 16#CF# =>
            declare
               U : constant Unsigned_64 := Read_U64_BE (Data, Position);
            begin
               if U > Unsigned_64 (Integer_64'Last) then
                  raise Format_Error with "uint64 exceeds Integer_64 range";
               end if;
               return Integer_64 (U);
            end;
         when 16#D0# =>
            declare
               U : constant Unsigned_8 := Read_U8 (Data, Position);
            begin
               if (U and 16#80#) /= 0 then
                  return Integer_64 (U) - 2 ** 8;
               else
                  return Integer_64 (U);
               end if;
            end;
         when 16#D1# => return Sign_Extend_16 (Read_U16_BE (Data, Position));
         when 16#D2# => return Sign_Extend_32 (Read_U32_BE (Data, Position));
         when 16#D3# => return To_Int64 (Read_U64_BE (Data, Position));
         when others => raise Format_Error with "expected integer";
      end case;
   end Unpack_Integer;

   function Unpack_Float
     (Data : Byte_Array; Position : in out Positive) return IEEE_Float_32
   is
      B : constant Unsigned_8 := Read_U8 (Data, Position);
   begin
      if B /= 16#CA# then
         raise Format_Error with "expected float32";
      end if;
      return To_Float (Read_U32_BE (Data, Position));
   end Unpack_Float;

   function Unpack_Double
     (Data : Byte_Array; Position : in out Positive) return IEEE_Float_64
   is
      B : constant Unsigned_8 := Read_U8 (Data, Position);
   begin
      if B /= 16#CB# then
         raise Format_Error with "expected float64";
      end if;
      return To_Double (Read_U64_BE (Data, Position));
   end Unpack_Double;

   function Read_String_Length
     (Data : Byte_Array; Position : in out Positive) return Natural
   is
      B : constant Unsigned_8 := Read_U8 (Data, Position);
   begin
      if (B and 16#E0#) = 16#A0# then
         return Natural (B and 16#1F#);
      end if;
      case B is
         when 16#D9# => return Natural (Read_U8     (Data, Position));
         when 16#DA# => return Natural (Read_U16_BE (Data, Position));
         when 16#DB# => return Natural (Read_U32_BE (Data, Position));
         when others => raise Format_Error with "expected string";
      end case;
   end Read_String_Length;

   function Unpack_String
     (Data : Byte_Array; Position : in out Positive) return String
   is
      Len : constant Natural := Read_String_Length (Data, Position);
   begin
      Require (Data, Position, Len);
      declare
         Result : String (1 .. Len);
      begin
         for I in 1 .. Len loop
            Result (I) := Character'Val (Natural (Data (Position + I - 1)));
         end loop;
         Position := Position + Len;
         return Result;
      end;
   end Unpack_String;

   function Read_Binary_Length
     (Data : Byte_Array; Position : in out Positive) return Natural
   is
      B : constant Unsigned_8 := Read_U8 (Data, Position);
   begin
      case B is
         when 16#C4# => return Natural (Read_U8     (Data, Position));
         when 16#C5# => return Natural (Read_U16_BE (Data, Position));
         when 16#C6# => return Natural (Read_U32_BE (Data, Position));
         when others => raise Format_Error with "expected binary";
      end case;
   end Read_Binary_Length;

   function Unpack_Binary
     (Data : Byte_Array; Position : in out Positive) return Byte_Array
   is
      Len : constant Natural := Read_Binary_Length (Data, Position);
   begin
      Require (Data, Position, Len);
      declare
         Result : constant Byte_Array :=
           Data (Position .. Position + Len - 1);
      begin
         Position := Position + Len;
         return Result;
      end;
   end Unpack_Binary;

   procedure Read_Extension_Header
     (Data     : Byte_Array;
      Position : in out Positive;
      Ext_Type : out Integer_8;
      Length   : out Natural)
   is
      B : constant Unsigned_8 := Read_U8 (Data, Position);
   begin
      case B is
         when 16#D4# => Length := 1;
         when 16#D5# => Length := 2;
         when 16#D6# => Length := 4;
         when 16#D7# => Length := 8;
         when 16#D8# => Length := 16;
         when 16#C7# => Length := Natural (Read_U8     (Data, Position));
         when 16#C8# => Length := Natural (Read_U16_BE (Data, Position));
         when 16#C9# => Length := Natural (Read_U32_BE (Data, Position));
         when others => raise Format_Error with "expected extension";
      end case;
      Ext_Type := To_Int8 (Read_U8 (Data, Position));
   end Read_Extension_Header;

   function Unpack_Extension
     (Data : Byte_Array; Position : in out Positive) return Extension
   is
      T   : Integer_8;
      Len : Natural;
   begin
      Read_Extension_Header (Data, Position, T, Len);
      Require (Data, Position, Len);
      declare
         Result : Extension (Length => Len);
      begin
         Result.Ext_Type := T;
         if Len > 0 then
            Result.Payload := Data (Position .. Position + Len - 1);
         end if;
         Position := Position + Len;
         return Result;
      end;
   end Unpack_Extension;

   function Unpack_Array_Header
     (Data : Byte_Array; Position : in out Positive) return Natural
   is
      B : constant Unsigned_8 := Read_U8 (Data, Position);
   begin
      if (B and 16#F0#) = 16#90# then
         return Natural (B and 16#0F#);
      end if;
      case B is
         when 16#DC# => return Natural (Read_U16_BE (Data, Position));
         when 16#DD# => return Natural (Read_U32_BE (Data, Position));
         when others => raise Format_Error with "expected array";
      end case;
   end Unpack_Array_Header;

   function Unpack_Map_Header
     (Data : Byte_Array; Position : in out Positive) return Natural
   is
      B : constant Unsigned_8 := Read_U8 (Data, Position);
   begin
      if (B and 16#F0#) = 16#80# then
         return Natural (B and 16#0F#);
      end if;
      case B is
         when 16#DE# => return Natural (Read_U16_BE (Data, Position));
         when 16#DF# => return Natural (Read_U32_BE (Data, Position));
         when others => raise Format_Error with "expected map";
      end case;
   end Unpack_Map_Header;

end Msg_Pack.Unpacker;
