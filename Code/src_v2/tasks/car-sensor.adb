with Ada.Execution_Time;
use type Ada.Execution_Time.CPU_Time;
with Ada.Real_Time;          use Ada.Real_Time;
with nRF.GPIO;               use nRF.GPIO;
with MicroBit.Buttons;       use MicroBit.Buttons;
with MicroBit.Console;       use MicroBit.Console;
with MicroBit.TimeHighspeed; use MicroBit.TimeHighspeed;
use MicroBit;

package body Car.Sensor is

   Left_Trigger  : GPIO_Point renames MB_P15;
   Left_Echo     : GPIO_Point renames MB_P16;
   Right_Trigger : GPIO_Point renames MB_P13;
   Right_Echo    : GPIO_Point renames MB_P14;

   function Read_Distance
     (Trigger : in out GPIO_Point; Echo : GPIO_point) return Distance_cm
   is
      Start_Deadline : constant Time := Clock + Milliseconds (3);
      Echo_Start     : Time;
      Cm             : Integer;
   begin
      Trigger.Set;
      Delay_Us (10);
      Trigger.Clear;

      loop
      
         exit when Echo.Set;
         if Clock >= Start_Deadline then
            return 0;
         end if;
      end loop;
      Echo_Start := Clock;

      loop
      -- returns zero if the echo is not received within 24 ms, which means that the obstacle is further away than 400 cm, and the car should not stop for it.
         exit when not Echo.Set;
         if Clock >= Echo_Start + Milliseconds (24) then
            return Distance_cm'Last;
         end if;
      end loop;
-- echo is shorter than 58us, which means that the obstacle is closer than 1 cm
      Cm := (Clock - Echo_Start) / Microseconds (58);
      return Distance_cm (Integer'Min (Cm, Integer (Distance_cm'Last)));
   end Read_Distance;

   task body Sensor_Task is

      Period : constant Time_Span := Milliseconds (100);
      Next   : Time := Clock;
      D      : Distances;
      Ticks  : Natural := 0; --jin
      -- Measuring C (execution time) for the response time analysis.
      Start_C : Ada.Execution_Time.CPU_Time;
      Used_C  : Time_Span;
      Max_C   : Time_Span := Time_Span_Zero; -- the largest C seen so far
      Rounds  : Natural := 0; -- print Max_C every 10 rounds = 1000 ms
   begin
      loop

         Start_C := Ada.Execution_Time.Clock;

         D (Left) := Read_Distance (Left_Trigger, Left_Echo);
         D (Right) := Read_Distance (Right_Trigger, Right_Echo);
         State.Set_Distances (D);

         Ticks := Ticks + 1;
         if Ticks >= 10 then
            Ticks := 0;
            Log.Put_Line
              ("Left:"
               & D (Left)'Image
               & "cm, right"
               & D (Right)'Image
               & "cm");
         end if;

         if MicroBit.Buttons.State (Button_A) = Pressed then
            State.Set_Driving (True);
         elsif MicroBit.Buttons.State (Button_B) = Pressed then
            State.Set_Driving (False);
         end if;

         -- Printed regularly, not only on a new record: the records are set
         -- in the first second, usually before the serial monitor is
         -- connected. Printed before C is measured, so the time Put_Line
         -- takes is part of this round's C: the printing rounds are the
         -- most expensive ones, and the WCET must include them.
         Rounds := Rounds + 1;
         if Rounds >= 10 then
            Rounds := 0;
            Log.Put_Line ("Sensor max C:" & Integer'Image (Max_C / Microseconds (1)) & " us");
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
   end Sensor_Task;

   Output : constant GPIO_Configuration :=
     (Mode         => Mode_Out,
      Resistors    => No_Pull,
      Input_Buffer => Input_Buffer_Connect,
      Sense        => Sense_Disabled,
      others       => <>);
   --Jin
   Input  : constant GPIO_Configuration :=
     (Mode         => Mode_In,
      Resistors    => No_Pull,
      Input_Buffer => Input_Buffer_Connect,
      Sense        => Sense_Disabled,
      others       => <>);
begin
   Left_Trigger.Configure_IO (Output);
   Right_Trigger.Configure_IO (Output);
   Left_Trigger.Clear;
   Right_Trigger.Clear;

   Left_Echo.Configure_IO (Input);
   Right_Echo.Configure_IO (Input);

end Car.Sensor;
