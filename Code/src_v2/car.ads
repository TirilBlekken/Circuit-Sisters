-- forandring
with MicroBit.Types; use MicroBit.Types;

package Car is
   type Distance_cm is range 0 .. 400;
   type Modes is (Stopped, Forward, Avoiding);
   type Sides is (Left, Right);
   type Distances is array (Sides) of Distance_cm;
-- byttet fra 15 til 25
   Stop_Distance : constant Distance_cm := 25;
   -- lager en til protected
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
