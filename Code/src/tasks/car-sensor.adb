with Ada.Real_Time;          use Ada.Real_Time;
with nRF.GPIO;               use nRF.GPIO;
with MicroBit.Buttons;       use MicroBit.Buttons;
with MicroBit.TimeHighspeed; use MicroBit.TimeHighspeed;
use MicroBit;

package body Car.Sensor is

   -- Three HC-SR04 sensors, wired as in the ultrasonic example: one Trigger
   -- pin each, and one shared Echo pin. Only one sensor is triggered at a
   -- time, so they can share it.
   Front_Trigger : GPIO_Point renames MB_P16;
   Left_Trigger  : GPIO_Point renames MB_P15;
   Right_Trigger : GPIO_Point renames MB_P14;
   Echo          : GPIO_Point renames MB_P0;

   -- Not MicroBit.Ultrasonic: its wait loops never leave when the deadline
   -- passes, so a missing echo froze every task. This gives up instead.
   -- Worst case 3 + 24 = 27 ms. Returns 0 when there is no echo.
   function Read_Distance (Trigger : in out GPIO_Point) return Distance_cm is
      Start_Deadline : constant Time := Clock + Milliseconds (3);
      Echo_Start     : Time;
      Cm             : Integer;
   begin
      Trigger.Set;
      Delay_Us (10);
      Trigger.Clear;

      -- The sensor raises Echo shortly after the trigger pulse...
      loop
         exit when Echo.Set;
         if Clock >= Start_Deadline then
            return 0;
         end if;
      end loop;
      Echo_Start := Clock;

      -- ...and holds it high for 58 us per cm. 400 cm is about 23 ms.
      loop
         exit when not Echo.Set;
         if Clock >= Echo_Start + Milliseconds (24) then
            return 0;
         end if;
      end loop;

      Cm := (Clock - Echo_Start) / Microseconds (58);
      return Distance_cm (Integer'Min (Cm, Integer (Distance_cm'Last)));
   end Read_Distance;

   task body Sensor_Task is
      -- Three reads take at most 3 x 27 = 81 ms, so the period must be longer.
      Period : constant Time_Span := Milliseconds (100);
      Next   : Time := Clock;
      D      : Distances;
   begin
      loop
         D (Front) := Read_Distance (Front_Trigger);
         D (Left)  := Read_Distance (Left_Trigger);
         D (Right) := Read_Distance (Right_Trigger);
         State.Set_Distances (D);

         -- Written out in full: inside Car, "State" is the protected object.
         if MicroBit.Buttons.State (Button_A) = Pressed then
            State.Set_Driving (True);
         elsif MicroBit.Buttons.State (Button_B) = Pressed then
            State.Set_Driving (False);
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
begin
   Front_Trigger.Configure_IO (Output);
   Left_Trigger.Configure_IO (Output);
   Right_Trigger.Configure_IO (Output);
   Front_Trigger.Clear;
   Left_Trigger.Clear;
   Right_Trigger.Clear;

   Echo.Configure_IO ((Mode         => Mode_In,
                       Resistors    => No_Pull,
                       Input_Buffer => Input_Buffer_Connect,
                       Sense        => Sense_Disabled,
                       others       => <>));
end Car.Sensor;
