with MicroBit.Types; use MicroBit.Types;


package Car is

   type Modes is (Stopped, Forward, Slowing, Avoiding);

   -- Two distance sensors, both pointing forward: one on the car's left
   -- side of the front, one on its right.
   type Sides is (Left, Right);
   type Distances is array (Sides) of Distance_cm;

   Slow_Distance : constant Distance_cm := 15; -- half speed from here, slowing down
   Stop_Distance : constant Distance_cm := 10; -- stop and turn when closer than this

   protected State is
      procedure Set_Distances (D : Distances);
      function Get_Distances return Distances;

      procedure Set_Driving (On : Boolean);
      function Is_Driving return Boolean;

      procedure Set_Mode (M : Modes);
      function Get_Mode return Modes;
   private
      Measured : Distances := (others => 0);
      Driving  : Boolean := False;
      Mode     : Modes := Stopped;
   end State;

end Car;
