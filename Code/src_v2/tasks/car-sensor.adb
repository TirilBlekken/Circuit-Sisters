with Ada.Real_Time;          use Ada.Real_Time;
with nRF.GPIO;               use nRF.GPIO;
with MicroBit.Buttons;       use MicroBit.Buttons;
with MicroBit.Console;       use MicroBit.Console;
with MicroBit.TimeHighspeed; use MicroBit.TimeHighspeed;
use MicroBit;

package body Car.Sensor is

   Left_Trigger  : GPIO_Point renames MB_P13;
   Left_Echo     : GPIO_Point renames MB_P14;
   Right_Trigger : GPIO_Point renames MB_P15;
   Right_Echo    : GPIO_Point renames MB_P16;

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
         exit when not Echo.Set;
         if Clock >= Echo_Start + Milliseconds (24) then
            return 0;
         end if;
      end loop;

      Cm := (Clock - Echo_Start) / Microseconds (58);
      return Distance_cm (Integer'Min (Cm, Integer (Distance_cm'Last)));
   end Read_Distance;

   task body Sensor_Task is

      Period : constant Time_Span := Milliseconds (100);
      Next   : Time := Clock;
      D      : Distances;
      Ticks  : Natural := 0; --jin
   begin
      loop

         D (Left) := Read_Distance (Left_Trigger, Left_Echo);
         D (Right) := Read_Distance (Right_Trigger, Right_Echo);
         State.Set_Distances (D);

         Ticks := Ticks + 1;
         if Ticks >= 10 then
            Ticks := 0;
            Put_Line
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
