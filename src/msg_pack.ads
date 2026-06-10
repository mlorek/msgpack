with Interfaces;
with Ada.Containers.Vectors;

package Msg_Pack is

   subtype Byte is Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_8;

   type Byte_Array is array (Positive range <>) of Byte;

   package Byte_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Byte);

   subtype Byte_Vector is Byte_Vectors.Vector;

   function To_Byte_Array (V : Byte_Vector) return Byte_Array;

   Format_Error : exception;

end Msg_Pack;
