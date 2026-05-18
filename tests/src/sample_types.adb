with Ada.Strings.Unbounded;     use Ada.Strings.Unbounded;
with Ada.Containers;             use Ada.Containers;
with Interfaces;                 use Interfaces;
with Ada_Msg_Pack.Packer;
with Ada_Msg_Pack.Unpacker;

package body Sample_Types is

   use Ada_Msg_Pack;

   procedure Pack
     (Buffer : in out Byte_Vector;
      Value  : Point) is
   begin
      Packer.Pack_Map_Header (Buffer, 2);
      Packer.Pack_String     (Buffer, "x");
      Packer.Pack_Double     (Buffer, Value.X);
      Packer.Pack_String     (Buffer, "y");
      Packer.Pack_Double     (Buffer, Value.Y);
   end Pack;

   function Unpack_Point
     (Data     : Byte_Array;
      Position : in out Positive) return Point
   is
      N      : constant Natural := Unpacker.Unpack_Map_Header (Data, Position);
      Result : Point := (X => 0.0, Y => 0.0);
   begin
      for I in 1 .. N loop
         declare
            Key : constant String := Unpacker.Unpack_String (Data, Position);
         begin
            if Key = "x" then
               Result.X := Unpacker.Unpack_Double (Data, Position);
            elsif Key = "y" then
               Result.Y := Unpacker.Unpack_Double (Data, Position);
            else
               raise Format_Error with "unknown Point field: " & Key;
            end if;
         end;
      end loop;
      return Result;
   end Unpack_Point;

   function "=" (L, R : Person) return Boolean is
      use String_Vectors;
   begin
      if L.Name /= R.Name or L.Age /= R.Age then
         return False;
      end if;
      if L.Tags.Length /= R.Tags.Length then
         return False;
      end if;
      for I in 1 .. Natural (L.Tags.Length) loop
         if L.Tags.Element (I) /= R.Tags.Element (I) then
            return False;
         end if;
      end loop;
      return True;
   end "=";

   procedure Pack
     (Buffer : in out Byte_Vector;
      Value  : Person) is
   begin
      Packer.Pack_Map_Header   (Buffer, 3);
      Packer.Pack_String       (Buffer, "name");
      Packer.Pack_String       (Buffer, To_String (Value.Name));
      Packer.Pack_String       (Buffer, "age");
      Packer.Pack_Integer      (Buffer, Value.Age);
      Packer.Pack_String       (Buffer, "tags");
      Packer.Pack_Array_Header (Buffer, Natural (Value.Tags.Length));
      for Tag of Value.Tags loop
         Packer.Pack_String (Buffer, To_String (Tag));
      end loop;
   end Pack;

   function Unpack_Person
     (Data     : Byte_Array;
      Position : in out Positive) return Person
   is
      N      : constant Natural := Unpacker.Unpack_Map_Header (Data, Position);
      Result : Person :=
        (Name => Null_Unbounded_String,
         Age  => 0,
         Tags => String_Vectors.Empty_Vector);
   begin
      for I in 1 .. N loop
         declare
            Key : constant String := Unpacker.Unpack_String (Data, Position);
         begin
            if Key = "name" then
               Result.Name :=
                 To_Unbounded_String (Unpacker.Unpack_String (Data, Position));
            elsif Key = "age" then
               Result.Age := Unpacker.Unpack_Integer (Data, Position);
            elsif Key = "tags" then
               declare
                  M : constant Natural :=
                    Unpacker.Unpack_Array_Header (Data, Position);
               begin
                  for J in 1 .. M loop
                     Result.Tags.Append
                       (To_Unbounded_String
                          (Unpacker.Unpack_String (Data, Position)));
                  end loop;
               end;
            else
               raise Format_Error with "unknown Person field: " & Key;
            end if;
         end;
      end loop;
      return Result;
   end Unpack_Person;

end Sample_Types;
