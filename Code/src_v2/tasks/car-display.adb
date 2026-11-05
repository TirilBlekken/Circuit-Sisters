with Ada.Execution_Time;
use type Ada.Execution_Time.CPU_Time;
with Ada.Real_Time; use Ada.Real_Time;
with MicroBit.DisplayRT;
with MicroBit.Console; use MicroBit.Console;
with MicroBit.DisplayRT.Symbols;

package body Car.Display is

   task body Display_Task is
      Period : constant Time_Span := Milliseconds (200);
      Next   : Time := Clock;
      Shown  : Modes := Avoiding;
      Mode   : Modes;
      -- Measuring C (execution time) for the response time analysis.
      Start_C : Ada.Execution_Time.CPU_Time;
      Used_C  : Time_Span;
      Max_C   : Time_Span := Time_Span_Zero; -- the largest C seen so far
      Rounds  : Natural := 0; -- print Max_C every 5 rounds = 1000 ms
   begin
      loop
         Start_C := Ada.Execution_Time.Clock;
         -- gets the current mode
         Mode := State.Get_Mode;

         --shown remebers the last mode shown
         if Mode /= Shown then
            MicroBit.DisplayRT.Clear;

         -- case for the different modes
            case Mode is
               when Stopped | Forward =>
                  MicroBit.DisplayRT.Symbols.Smile;

               when Avoiding          =>
                  MicroBit.DisplayRT.Symbols.Frown;

               when others            =>
                  null;
            end case;
            Shown := Mode;
         end if;

         -- Printed regularly, not only on a new record: the records are set
         -- in the first second, usually before the serial monitor is
         -- connected. Printed before C is measured, so the time Put_Line
         -- takes is part of this round's C: the printing rounds are the
         -- most expensive ones, and the WCET must include them.
         Rounds := Rounds + 1;
         if Rounds >= 5 then
            Rounds := 0;
            Log.Put_Line ("Display max C:" & Integer'Image (Max_C / Microseconds (1)) & " us");
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
   end Display_Task;

end Car.Display;
