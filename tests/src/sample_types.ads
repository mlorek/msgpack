with Ada.Strings.Unbounded;
with Ada.Containers.Vectors;
with Interfaces;
with Ada_Msg_Pack;

package Sample_Types is

   --  Point: a value record packed as a 2-key map {"x": ..., "y": ...}
   type Point is record
      X : Interfaces.IEEE_Float_64;
      Y : Interfaces.IEEE_Float_64;
   end record;

   procedure Pack
     (Buffer : in out Ada_Msg_Pack.Byte_Vector;
      Value  : Point);

   function Unpack_Point
     (Data     : Ada_Msg_Pack.Byte_Array;
      Position : in out Positive) return Point;

   --  Person: a record with a string, integer, and string vector,
   --  packed as a 3-key map {"name": ..., "age": ..., "tags": [...]}.
   package String_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Ada.Strings.Unbounded.Unbounded_String,
      "="          => Ada.Strings.Unbounded."=");

   type Person is record
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Age  : Interfaces.Integer_64;
      Tags : String_Vectors.Vector;
   end record;

   function "=" (L, R : Person) return Boolean;

   procedure Pack
     (Buffer : in out Ada_Msg_Pack.Byte_Vector;
      Value  : Person);

   function Unpack_Person
     (Data     : Ada_Msg_Pack.Byte_Array;
      Position : in out Positive) return Person;

end Sample_Types;
