with Ada.Real_Time;        use Ada.Real_Time;
with MicroBit.MotorDriver; use MicroBit.MotorDriver;
with MicroBit.Console;     use MicroBit.Console;
use MicroBit;

package body Car.Motor is

   Drive_Speed : constant Speeds :=
     (rf => 4095, rb => 4095, lf => 4095, lb => 4095);
   Turn_Speed  : constant Speeds :=
     (rf => 4095, rb => 4095, lf => 4095, lb => 4095);

   function Room (D : Distance_cm) return Distance_cm
   is (if D < 2 then Distance_cm'Last else D);

   task body Motor_Task is
      Period      : constant Time_Span := Milliseconds (100);
      Next        : Time := Clock;
      D           : Distances;
      Brake_Ticks : Natural := 0;
      Turn        : Directions := Rotating_Right;
      Last_Mode   : Modes := Avoiding;
   begin
      loop
         D := State.Get_Distances;

         if not State.Is_Driving then
            State.Set_Mode (Stopped);
            MotorDriver.Drive (Stop);

         elsif Room (D (Left)) < Stop_Distance
           or else Room (D (Right)) < Stop_Distance
         then
            if State.Get_Mode /= Avoiding then

               if Room (D (Left)) > Room (D (Right)) then
                  Turn := Rotating_Left;
               else
                  Turn := Rotating_Right;
               end if;
               Put_Line
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
            Put_Line ("Mode: " & Last_Mode'Image);
         end if;

         Next := Next + Period;
         delay until Next;
      end loop;
   end Motor_Task;

end Car.Motor;
