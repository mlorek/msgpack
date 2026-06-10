package body Msg_Pack is

   function To_Byte_Array (V : Byte_Vector) return Byte_Array is
      Result : Byte_Array (1 .. Natural (V.Length));
      I      : Positive := 1;
   begin
      for B of V loop
         Result (I) := B;
         I := I + 1;
      end loop;
      return Result;
   end To_Byte_Array;

end Msg_Pack;
