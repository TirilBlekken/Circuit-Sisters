with Ada.Execution_Time;
use type Ada.Execution_Time.CPU_Time;
with Ada.Real_Time;        use Ada.Real_Time;
with MicroBit.MotorDriver; use MicroBit.MotorDriver;
with MicroBit.Console;     use MicroBit.Console;
use MicroBit;

package body Car.Motor is

   Drive_Speed : constant Speeds :=
     (rf => 4095, rb => 4095, lf => 4095, lb => 4095);
   Turn_Speed  : constant Speeds :=
     (rf => 4095, rb => 4095, lf => 4095, lb => 4095);

   --function Room (D : Distance_cm) return Distance_cm
   --is (if D < 2 then Distance_cm'Last else D);

   task body Motor_Task is
      Period      : constant Time_Span := Milliseconds (100);
      Next        : Time := Clock;
      D           : Distances;
      Brake_Ticks : Natural := 0;
      Turn        : Directions := Rotating_Right;
      Last_Mode   : Modes := Avoiding;
      -- Measuring C (execution time) for the response time analysis.
      Start_C : Ada.Execution_Time.CPU_Time;
      Used_C  : Time_Span;
      Max_C   : Time_Span := Time_Span_Zero; -- the largest C seen so far
      Rounds  : Natural := 0; -- print Max_C every 10 rounds = 1000 ms
   begin
      loop
         Start_C := Ada.Execution_Time.Clock;

         D := State.Get_Distances;

         if not State.Is_Driving then
            State.Set_Mode (Stopped);
            MotorDriver.Drive (Stop);
-- fjerner Room 
         elsif (D (Left)) < Stop_Distance
           or else (D (Right)) < Stop_Distance
         then
            if State.Get_Mode /= Avoiding then

               if (D (Left)) > (D (Right)) then
                  Turn := Rotating_Left;
               else
                  Turn := Rotating_Right;
               end if;
               Log.Put_Line
                 ("Obstacle at"
                  & D (Left)'Image
                  & " cm, right"
                  & D (Right)'Image
                  & " cm: "
                  & Turn'Image);

               State.Set_Mode (Avoiding);
               Brake_Ticks := 3;

            end if;

            if Brake_Ticks > 0 then
               Brake_Ticks := Brake_Ticks - 1;
               MotorDriver.Drive (Stop);
            else
               MotorDriver.Drive (Turn, Turn_Speed);
            end if;

         else
            State.Set_Mode (Forward);
            MotorDriver.Drive (Forward, Drive_Speed);
         end if;

         if State.Get_Mode /= Last_Mode then
            Last_Mode := State.Get_Mode;
            Log.Put_Line ("Mode: " & Last_Mode'Image);
         end if;

         -- Printed regularly, not only on a new record: the records are set
         -- in the first second, usually before the serial monitor is
         -- connected. Printed before C is measured, so the time Put_Line
         -- takes is part of this round's C: the printing rounds are the
         -- most expensive ones, and the WCET must include them.
         Rounds := Rounds + 1;
         if Rounds >= 10 then
            Rounds := 0;
            Log.Put_Line ("Motor max C:" & Integer'Image (Max_C / Microseconds (1)) & " us");
         end if;

         -- C for this round: CPU time used since Start_C. Keep the largest;
         -- that is the WCET to use in the analysis.
         Used_C := Ada.Execution_Time.Clock - Start_C;
         if Used_C > Max_C then
            Max_C := Used_C;
         end if;
         

         Next := Next + Period;
         delay until Next;
      end loop;
   end Motor_Task;

end Car.Motor;
