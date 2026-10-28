with Ada.Real_Time;          use Ada.Real_Time;
with nRF.GPIO;               use nRF.GPIO;
with MicroBit.Buttons;       use MicroBit.Buttons;
with MicroBit.TimeHighspeed; use MicroBit.TimeHighspeed;
use MicroBit;

package body Car.Sensor is

   ---------------------------------------------------------------------
   -- WIRING: two HC-SR04 distance sensors, both pointing forward
   --
   --   Seen from the FRONT of the car (sensors pointing at you), the car's
   --   left is on your right:
   --
   --          car's RIGHT              car's LEFT
   --        (( ))   (( ))            (( ))   (( ))
   --         Trig P16                 Trig P14
   --         Echo P13                 Echo P15
   --
   --   Sensor       | Trig -> micro:bit pin | Echo -> micro:bit pin
   --   -------------+-----------------------+----------------------
   --   Left  front  | P14                   | P15
   --   Right front  | P16                   | P13
   --
   -- Trig: micro:bit -> sensor. A 10 us pulse means "measure now".
   -- Echo: sensor -> micro:bit. High for 58 us per cm to the obstacle.
   ---------------------------------------------------------------------
   Left_Trig_Pin  : GPIO_Point renames MB_P14;
   Left_Echo_Pin  : GPIO_Point renames MB_P15;
   Right_Trig_Pin : GPIO_Point renames MB_P16;
   Right_Echo_Pin : GPIO_Point renames MB_P13;

   -- Not MicroBit.Ultrasonic: its wait loops never leave when the deadline
   -- passes, so a missing echo froze every task. This gives up instead.
   -- Worst case 3 + 24 = 27 ms. Returns 0 when there is no echo.
   function Read_Distance (Trig : in out GPIO_Point;
                           Echo : GPIO_Point) return Distance_cm is
      Start_Deadline : constant Time := Clock + Milliseconds (3);
      Echo_Start     : Time;
      Cm             : Integer;
   begin
      Trig.Set;
      Delay_Us (10);
      Trig.Clear;

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
      -- Two reads take at most 2 x 27 = 54 ms, so the period must be longer.
      Period : constant Time_Span := Milliseconds (100);
      Next   : Time := Clock;
      D      : Distances;
   begin
      loop
         -- One after the other, never together: both point the same way, so
         -- each would hear the other's ping.
         D (Left)  := Read_Distance (Left_Trig_Pin, Left_Echo_Pin);
         D (Right) := Read_Distance (Right_Trig_Pin, Right_Echo_Pin);
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
   Input : constant GPIO_Configuration :=
     (Mode         => Mode_In,
      Resistors    => No_Pull,
      Input_Buffer => Input_Buffer_Connect,
      Sense        => Sense_Disabled,
      others       => <>);
begin
   Left_Trig_Pin.Configure_IO (Output);
   Right_Trig_Pin.Configure_IO (Output);
   Left_Trig_Pin.Clear;
   Right_Trig_Pin.Clear;
   Left_Echo_Pin.Configure_IO (Input);
   Right_Echo_Pin.Configure_IO (Input);
end Car.Sensor;
