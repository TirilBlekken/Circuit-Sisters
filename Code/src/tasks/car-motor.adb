with Ada.Real_Time;         use Ada.Real_Time;
with HAL;                  use HAL;
with MicroBit.MotorDriver; use MicroBit.MotorDriver;
with MicroBit.Console;     use MicroBit.Console;
use MicroBit;

package body Car.Motor is

   -- Speed per wheel, 0 .. 4095, named as in the motor_drive_dfr0548 example:
   --   rf = right front (M4)   rb = right back (M3)
   --   lf = left front  (M2)   lb = left back  (M1)
   -- If the car pulls to one side, lower the faster side here.
   Drive_Speed : constant Speeds := (rf => 4095, rb => 4095, lf => 4095, lb => 4095);
   Turn_Speed  : constant Speeds := (rf => 4095, rb => 4095, lf => 4095, lb => 4095);

   -- Between Slow_Distance and Stop_Distance the speed falls from half to
   -- Min_Factor. Not to zero: below roughly 40 % the motors stall and just hum.
   Half_Factor : constant Float := 0.5;
   Min_Factor  : constant Float := 0.4;

   function Scale (S : Speeds; Factor : Float) return Speeds is
     (rf => UInt12 (Float (S.rf) * Factor),
      rb => UInt12 (Float (S.rb) * Factor),
      lf => UInt12 (Float (S.lf) * Factor),
      lb => UInt12 (Float (S.lb) * Factor));

   -- 0.5 at 15 cm, falling in a straight line to 0.4 at 10 cm.
   function Slow_Factor (Front : Distance_cm) return Float is
     (Min_Factor + (Half_Factor - Min_Factor)
        * Float (Front - Stop_Distance) / Float (Slow_Distance - Stop_Distance));

   -- A reading of 0 or 1 means no echo: nothing within 4 m, so the way is
   -- clear. Count it as the farthest distance when comparing sides.
   function Room (D : Distance_cm) return Distance_cm is
     (if D < 2 then Distance_cm'Last else D);

   task body Motor_Task is
      Period      : constant Time_Span := Milliseconds (100);
      Next        : Time := Clock;
      D           : Distances;
      Front       : Distance_cm; -- the nearer of the two: that is what we hit first
      Brake_Ticks : Natural := 0;
      Turn        : Directions := Rotating_Right; -- chosen when an obstacle appears
      Last_Mode   : Modes := Avoiding; -- anything but Stopped, so the start is printed
   begin
      loop
         D := State.Get_Distances;
         Front := Distance_cm'Min (Room (D (Left)), Room (D (Right)));

         if not State.Is_Driving then
            State.Set_Mode (Stopped);
            MotorDriver.Drive (Stop);

         elsif Front < Stop_Distance then
            if State.Get_Mode /= Avoiding then
               -- Turn towards the sensor that sees farther: that side has
               -- more room. Decide once, when the obstacle appears, and keep
               -- turning that way until the front is clear; deciding again
               -- every period would make the car wobble between left and right.
               if Room (D (Left)) > Room (D (Right)) then
                  Turn := Rotating_Left;
               else
                  Turn := Rotating_Right;
               end if;
               Put_Line ("Obstacle: left" & D (Left)'Image & " cm, right"
                         & D (Right)'Image & " cm: " & Turn'Image);
               State.Set_Mode (Avoiding);
               Brake_Ticks := 3; -- 3 x 100 ms = 300 ms standing still
            end if;

            -- Never "delay" inside a periodic task: count periods instead.
            if Brake_Ticks > 0 then
               Brake_Ticks := Brake_Ticks - 1;
               MotorDriver.Drive (Stop);
            else
               MotorDriver.Drive (Turn, Turn_Speed);
            end if;

         elsif Front <= Slow_Distance then
            State.Set_Mode (Slowing);
            MotorDriver.Drive (Forward, Scale (Drive_Speed, Slow_Factor (Front)));

         else
            State.Set_Mode (Forward);
            MotorDriver.Drive (Forward, Drive_Speed);
         end if;

         -- Print after deciding, so the line shows the mode just entered.
         if State.Get_Mode /= Last_Mode then
            Last_Mode := State.Get_Mode;
            Put_Line ("Mode: " & Last_Mode'Image);
         end if;

         Next := Next + Period;
         delay until Next;
      end loop;
   end Motor_Task;

end Car.Motor;
