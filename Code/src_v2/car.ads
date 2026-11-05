-- forandring
with MicroBit.Types; use MicroBit.Types;

package Car is
   type Distance_cm is range 0 .. 400;

   --modes the car can be in
   type Modes is (Stopped, Forward, Avoiding);

   --sides are left or right, and it is the distance
   type Sides is (Left, Right);
   type Distances is array (Sides) of Distance_cm;

-- we switched from 15 to 25, we did this because we notices the car was struggeling to see
-- the wall as an obstacle when it was 15 cm away, so we increased the distance to 25 cm
   Stop_Distance : constant Distance_cm := 25;

   -- protected object for logging, this so nothing can be changed while logging, and we can log from any task
   protected Log is
      procedure Put_Line (S : String);
   end Log;
   
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
