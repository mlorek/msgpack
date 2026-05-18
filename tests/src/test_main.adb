with Ada.Text_IO;          use Ada.Text_IO;
with Ada.Command_Line;
with Interfaces;           use Interfaces;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada_Msg_Pack;         use Ada_Msg_Pack;
with Ada_Msg_Pack.Packer;
with Ada_Msg_Pack.Unpacker;
with Sample_Types;

procedure Test_Main is

   Failures : Natural := 0;

   procedure Check (Label : String; Condition : Boolean) is
   begin
      if Condition then
         Put_Line ("  ok  " & Label);
      else
         Failures := Failures + 1;
         Put_Line ("FAIL  " & Label);
      end if;
   end Check;

   procedure Round_Trip_Integer (V : Integer_64; Label : String) is
      B   : Byte_Vector;
      Pos : Positive := 1;
   begin
      Ada_Msg_Pack.Packer.Pack_Integer (B, V);
      declare
         Arr : constant Byte_Array := To_Byte_Array (B);
         R   : constant Integer_64 :=
           Ada_Msg_Pack.Unpacker.Unpack_Integer (Arr, Pos);
      begin
         Check (Label, R = V and Pos = Arr'Length + 1);
      end;
   end Round_Trip_Integer;

   type Int64_Sample is array (Positive range <>) of Integer_64;

   Wide_Samples : constant Int64_Sample :=
     (-1, 0, 1, 127, 128, 255, 256, 65535, 65536,
      -32, -33, -128, -129, -32768, -32769,
      Integer_64 (Unsigned_32'Last),
      Integer_64 (Unsigned_32'Last) + 1,
      Integer_64'First, Integer_64'Last);

   procedure Test_Integers is
   begin
      Put_Line ("integers:");
      for V in Integer_64 range -33 .. 127 loop
         Round_Trip_Integer (V, "small int" & Integer_64'Image (V));
      end loop;
      for V of Wide_Samples loop
         Round_Trip_Integer (V, "wide int" & Integer_64'Image (V));
      end loop;
   end Test_Integers;

   procedure Test_Booleans_And_Nil is
      Buf : Byte_Vector;
      P   : Positive := 1;
   begin
      Put_Line ("booleans and nil:");
      Ada_Msg_Pack.Packer.Pack_Nil (Buf);
      Ada_Msg_Pack.Packer.Pack_Boolean (Buf, True);
      Ada_Msg_Pack.Packer.Pack_Boolean (Buf, False);
      declare
         Arr : constant Byte_Array := To_Byte_Array (Buf);
         B1, B2 : Boolean;
      begin
         Ada_Msg_Pack.Unpacker.Unpack_Nil (Arr, P);
         B1 := Ada_Msg_Pack.Unpacker.Unpack_Boolean (Arr, P);
         B2 := Ada_Msg_Pack.Unpacker.Unpack_Boolean (Arr, P);
         Check ("nil byte",   Arr (1) = 16#C0#);
         Check ("true byte",  Arr (2) = 16#C3#);
         Check ("false byte", Arr (3) = 16#C2#);
         Check ("unpacked true",  B1);
         Check ("unpacked false", not B2);
      end;
   end Test_Booleans_And_Nil;

   procedure Test_Floats is
      Buf : Byte_Vector;
      P   : Positive := 1;
   begin
      Put_Line ("floats:");
      Ada_Msg_Pack.Packer.Pack_Float  (Buf, 1.5);
      Ada_Msg_Pack.Packer.Pack_Double (Buf, 3.141592653589793);
      declare
         Arr : constant Byte_Array := To_Byte_Array (Buf);
         F   : constant IEEE_Float_32 :=
           Ada_Msg_Pack.Unpacker.Unpack_Float (Arr, P);
         D   : constant IEEE_Float_64 :=
           Ada_Msg_Pack.Unpacker.Unpack_Double (Arr, P);
      begin
         Check ("float32 round-trip", F = 1.5);
         Check ("float64 round-trip", D = 3.141592653589793);
      end;
   end Test_Floats;

   procedure Test_String_And_Binary is
      Buf : Byte_Vector;
      P   : Positive := 1;
      Bin : constant Byte_Array := (16#DE#, 16#AD#, 16#BE#, 16#EF#);
   begin
      Put_Line ("string and binary:");
      Ada_Msg_Pack.Packer.Pack_String (Buf, "hello");
      Ada_Msg_Pack.Packer.Pack_String (Buf, (1 .. 40 => 'x'));
      Ada_Msg_Pack.Packer.Pack_Binary (Buf, Bin);
      declare
         Arr : constant Byte_Array := To_Byte_Array (Buf);
         S1  : constant String     := Ada_Msg_Pack.Unpacker.Unpack_String (Arr, P);
         S2  : constant String     := Ada_Msg_Pack.Unpacker.Unpack_String (Arr, P);
         B   : constant Byte_Array := Ada_Msg_Pack.Unpacker.Unpack_Binary (Arr, P);
      begin
         Check ("fixstr round-trip", S1 = "hello");
         Check ("str8 round-trip",   S2'Length = 40 and then S2 = (1 .. 40 => 'x'));
         Check ("bin8 round-trip",   B = Bin);
      end;
   end Test_String_And_Binary;

   procedure Round_Trip_Extension
     (Ext_Type : Integer_8;
      Payload  : Byte_Array;
      Label    : String)
   is
      Buf : Byte_Vector;
      P   : Positive := 1;
   begin
      Ada_Msg_Pack.Packer.Pack_Extension (Buf, Ext_Type, Payload);
      declare
         Arr : constant Byte_Array := To_Byte_Array (Buf);
         R   : constant Ada_Msg_Pack.Unpacker.Extension :=
           Ada_Msg_Pack.Unpacker.Unpack_Extension (Arr, P);
      begin
         Check (Label,
                R.Ext_Type = Ext_Type
                  and R.Length = Payload'Length
                  and R.Payload = Payload
                  and P = Arr'Length + 1);
      end;
   end Round_Trip_Extension;

   procedure Test_Extensions is
      Empty : constant Byte_Array (1 .. 0) := (others => 0);
      P1    : constant Byte_Array := (1 => 16#AA#);
      P2    : constant Byte_Array := (16#AA#, 16#BB#);
      P3    : constant Byte_Array := (16#01#, 16#02#, 16#03#);
      P4    : constant Byte_Array := (16#01#, 16#02#, 16#03#, 16#04#);
      P8    : constant Byte_Array (1 .. 8)  := (others => 16#5A#);
      P16   : constant Byte_Array (1 .. 16) := (others => 16#33#);
      P_E8  : constant Byte_Array (1 .. 17) := (others => 16#77#);
      P_E16 : constant Byte_Array (1 .. 300) := (others => 16#11#);
      Buf   : Byte_Vector;
   begin
      Put_Line ("extensions:");

      Round_Trip_Extension (1,   P1,    "fixext1");
      Round_Trip_Extension (2,   P2,    "fixext2");
      Round_Trip_Extension (4,   P4,    "fixext4");
      Round_Trip_Extension (8,   P8,    "fixext8");
      Round_Trip_Extension (16,  P16,   "fixext16");
      Round_Trip_Extension (-1,  P3,    "ext8 (odd len)");
      Round_Trip_Extension (-1,  Empty, "ext8 (empty)");
      Round_Trip_Extension (42,  P_E8,  "ext8");
      Round_Trip_Extension (-42, P_E16, "ext16");

      Ada_Msg_Pack.Packer.Pack_Extension (Buf, 7, P4);
      declare
         Arr : constant Byte_Array := To_Byte_Array (Buf);
      begin
         Check ("fixext4 header byte", Arr (1) = 16#D6#);
         Check ("fixext4 type byte",   Arr (2) = 16#07#);
      end;

      declare
         Buf2 : Byte_Vector;
      begin
         Ada_Msg_Pack.Packer.Pack_Extension (Buf2, -1, P3);
         Check ("ext8 header byte", Buf2.Element (1) = 16#C7#);
         Check ("ext8 length byte", Buf2.Element (2) = 16#03#);
         Check ("ext8 type byte (-1 sign-encoded)",
                Buf2.Element (3) = 16#FF#);
      end;

      declare
         Peek_Buf : Byte_Vector;
      begin
         Ada_Msg_Pack.Packer.Pack_Extension (Peek_Buf, 1, P1);
         declare
            Arr : constant Byte_Array := To_Byte_Array (Peek_Buf);
            use Ada_Msg_Pack.Unpacker;
         begin
            Check ("Peek_Kind on extension",
                   Peek_Kind (Arr, 1) = Kind_Extension);
         end;
      end;
   end Test_Extensions;

   procedure Test_Samples is
      use Sample_Types;
   begin
      Put_Line ("sample classes:");

      declare
         Original : constant Point := (X => 3.141592653589793, Y => -2.5);
         Buf      : Byte_Vector;
         Pos      : Positive := 1;
      begin
         Pack (Buf, Original);
         declare
            Arr : constant Byte_Array := To_Byte_Array (Buf);
            R   : constant Point := Unpack_Point (Arr, Pos);
         begin
            Check ("Point round-trip",
                   R.X = Original.X
                     and R.Y = Original.Y
                     and Pos = Arr'Length + 1);
         end;
      end;

      declare
         Tags : String_Vectors.Vector;
         Buf  : Byte_Vector;
         Pos  : Positive := 1;
      begin
         Tags.Append (To_Unbounded_String ("admin"));
         Tags.Append (To_Unbounded_String ("ada"));
         Tags.Append (To_Unbounded_String ("msgpack"));
         declare
            Original : constant Person :=
              (Name => To_Unbounded_String ("Ada Lovelace"),
               Age  => 36,
               Tags => Tags);
         begin
            Pack (Buf, Original);
            declare
               Arr : constant Byte_Array := To_Byte_Array (Buf);
               R   : constant Person := Unpack_Person (Arr, Pos);
            begin
               Check ("Person round-trip",
                      R = Original and Pos = Arr'Length + 1);
            end;
         end;
      end;

      --  Empty Person: zero-element tags vector + empty Name.
      declare
         Empty   : constant Person :=
           (Name => Null_Unbounded_String,
            Age  => 0,
            Tags => String_Vectors.Empty_Vector);
         Buf     : Byte_Vector;
         Pos     : Positive := 1;
      begin
         Pack (Buf, Empty);
         declare
            Arr : constant Byte_Array := To_Byte_Array (Buf);
            R   : constant Person := Unpack_Person (Arr, Pos);
         begin
            Check ("Empty Person round-trip", R = Empty);
         end;
      end;

      --  A Point nested inside a 2-element array packed by hand.
      declare
         A   : constant Point := (X => 1.0,  Y => 2.0);
         B   : constant Point := (X => -3.0, Y => 4.5);
         Buf : Byte_Vector;
         Pos : Positive := 1;
      begin
         Ada_Msg_Pack.Packer.Pack_Array_Header (Buf, 2);
         Pack (Buf, A);
         Pack (Buf, B);
         declare
            Arr : constant Byte_Array := To_Byte_Array (Buf);
            N   : constant Natural :=
              Ada_Msg_Pack.Unpacker.Unpack_Array_Header (Arr, Pos);
            R1  : constant Point := Unpack_Point (Arr, Pos);
            R2  : constant Point := Unpack_Point (Arr, Pos);
         begin
            Check ("Array of Points header", N = 2);
            Check ("Array of Points elem 0", R1.X = A.X and R1.Y = A.Y);
            Check ("Array of Points elem 1", R2.X = B.X and R2.Y = B.Y);
         end;
      end;
   end Test_Samples;

   procedure Test_Array_And_Map is
      Buf : Byte_Vector;
      P   : Positive := 1;
   begin
      Put_Line ("array and map:");
      Ada_Msg_Pack.Packer.Pack_Array_Header (Buf, 3);
      Ada_Msg_Pack.Packer.Pack_Integer      (Buf, 10);
      Ada_Msg_Pack.Packer.Pack_String       (Buf, "two");
      Ada_Msg_Pack.Packer.Pack_Boolean      (Buf, True);

      Ada_Msg_Pack.Packer.Pack_Map_Header   (Buf, 1);
      Ada_Msg_Pack.Packer.Pack_String       (Buf, "k");
      Ada_Msg_Pack.Packer.Pack_Integer      (Buf, 42);

      declare
         Arr   : constant Byte_Array := To_Byte_Array (Buf);
         N_Arr : constant Natural :=
           Ada_Msg_Pack.Unpacker.Unpack_Array_Header (Arr, P);
      begin
         Check ("array header length", N_Arr = 3);
         Check ("array elem 0",
                Ada_Msg_Pack.Unpacker.Unpack_Integer (Arr, P) = 10);
         declare
            S : constant String :=
              Ada_Msg_Pack.Unpacker.Unpack_String (Arr, P);
         begin
            Check ("array elem 1", S = "two");
         end;
         Check ("array elem 2",
                Ada_Msg_Pack.Unpacker.Unpack_Boolean (Arr, P));
         declare
            N_Map : constant Natural :=
              Ada_Msg_Pack.Unpacker.Unpack_Map_Header (Arr, P);
         begin
            Check ("map header length", N_Map = 1);
         end;
         declare
            K : constant String     := Ada_Msg_Pack.Unpacker.Unpack_String  (Arr, P);
            V : constant Integer_64 := Ada_Msg_Pack.Unpacker.Unpack_Integer (Arr, P);
         begin
            Check ("map key",   K = "k");
            Check ("map value", V = 42);
         end;
      end;
   end Test_Array_And_Map;

begin
   Test_Booleans_And_Nil;
   Test_Integers;
   Test_Floats;
   Test_String_And_Binary;
   Test_Extensions;
   Test_Array_And_Map;
   Test_Samples;

   New_Line;
   if Failures = 0 then
      Put_Line ("All tests passed.");
   else
      Put_Line ("FAILURES:" & Natural'Image (Failures));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Test_Main;
