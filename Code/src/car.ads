with MicroBit.Types; use MicroBit.Types;


package Car is

   type Modes is (Stopped, Forward, Avoiding);

   Stop_Distance : constant Distance_cm := 20; 

   task Sensor  with Priority => 3;
   task Motor   with Priority => 2;
   task Display with Priority => 1;

   
   protected State is
      procedure Set_Distance (D : Distance_cm);
      function Get_Distance return Distance_cm;

      procedure Set_Driving (On : Boolean);
      function Is_Driving return Boolean;

      procedure Set_Mode (M : Modes);
      function Get_Mode return Modes;
   private
      Distance : Distance_cm := 0;
      Driving  : Boolean := False;
      Mode     : Modes := Stopped;
   end State;

end Car;
