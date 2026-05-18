with Interfaces;

package Ada_Msg_Pack.Packer is

   procedure Pack_Nil
     (Buffer : in out Byte_Vector);

   procedure Pack_Boolean
     (Buffer : in out Byte_Vector;
      Value  : Boolean);

   procedure Pack_Integer
     (Buffer : in out Byte_Vector;
      Value  : Interfaces.Integer_64);

   procedure Pack_Unsigned
     (Buffer : in out Byte_Vector;
      Value  : Interfaces.Unsigned_64);

   procedure Pack_Float
     (Buffer : in out Byte_Vector;
      Value  : Interfaces.IEEE_Float_32);

   procedure Pack_Double
     (Buffer : in out Byte_Vector;
      Value  : Interfaces.IEEE_Float_64);

   procedure Pack_String
     (Buffer : in out Byte_Vector;
      Value  : String);

   procedure Pack_Binary
     (Buffer : in out Byte_Vector;
      Value  : Byte_Array);

   procedure Pack_Extension
     (Buffer   : in out Byte_Vector;
      Ext_Type : Interfaces.Integer_8;
      Data     : Byte_Array);

   procedure Pack_Array_Header
     (Buffer : in out Byte_Vector;
      Length : Natural);

   procedure Pack_Map_Header
     (Buffer : in out Byte_Vector;
      Length : Natural);

end Ada_Msg_Pack.Packer;
