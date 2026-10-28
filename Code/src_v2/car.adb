with MicroBit.Console;
package body Car is

protected body Log is
      procedure Put_Line (S : String) is
      begin
         MicroBit.Console.Put_Line (S);
      end Put_Line;
   end Log;

   protected body State is
      -- All three in one call, so a reader never gets a new front distance
      -- together with old side distances.
      procedure Set_Distances (D : Distances) is
      begin
         Measured := D;
      end Set_Distances;

      function Get_Distances return Distances is (Measured);

      procedure Set_Driving (On : Boolean) is
      begin
         Driving := On;
      end Set_Driving;

      function Is_Driving return Boolean is (Driving);

      procedure Set_Mode (M : Modes) is
      begin
         Mode := M;
      end Set_Mode;

      function Get_Mode return Modes is (Mode);
   end State;

end Car;
