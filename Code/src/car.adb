with Ada.Real_Time; use Ada.Real_Time;
with MicroBit.Ultrasonic;
with MicroBit.Buttons;     use MicroBit.Buttons;
with MicroBit.MotorDriver; use MicroBit.MotorDriver;
with MicroBit.DisplayRT;
with MicroBit.DisplayRT.Symbols;
with MicroBit.Console;     use MicroBit.Console;
use MicroBit;

package body Car is

   
   package Front_Sensor is new Ultrasonic (MB_P16, MB_P0);

   Full_Speed : constant Speeds := (4095, 4095, 4095, 4095);

   

   task body Sensor is
      Period : constant Time_Span := Milliseconds (60);
      Next   : Time := Clock;
   begin
      loop
         
         State.Set_Distance (Front_Sensor.Read);

         
         if MicroBit.Buttons.State (Button_A) = Pressed then
            State.Set_Driving (True);
         elsif MicroBit.Buttons.State (Button_B) = Pressed then
            State.Set_Driving (False);
         end if;

         Next := Next + Period;
         delay until Next;
      end loop;
   end Sensor;

   

   task body Motor is
      Period      : constant Time_Span := Milliseconds (60);
      Next        : Time := Clock;
      Distance    : Distance_cm;
      Brake_Ticks : Natural := 0; 
   begin
      loop
         Distance := State.Get_Distance;

         if not State.Is_Driving then
            State.Set_Mode (Stopped);
            MotorDriver.Drive (Stop);

         
         elsif Distance >= 2 and Distance < Stop_Distance then
            if State.Get_Mode /= Avoiding then
               Put_Line ("Obstacle at" & Distance'Image & " cm: stop and turn");
               State.Set_Mode (Avoiding);
               Brake_Ticks := 5; 
            end if;

            
            if Brake_Ticks > 0 then
               Brake_Ticks := Brake_Ticks - 1;
               MotorDriver.Drive (Stop);
            else
               
               MotorDriver.Drive (Rotating_Right, Full_Speed);
            end if;

         else
            State.Set_Mode (Forward);
            MotorDriver.Drive (Forward, Full_Speed);
         end if;

         Next := Next + Period;
         delay until Next;
      end loop;
   end Motor;

  

   task body Display is
      Period : constant Time_Span := Milliseconds (200);
      Next   : Time := Clock;
      Shown  : Modes := Avoiding; 
      Mode   : Modes;
   begin
      loop
         Mode := State.Get_Mode;

         
         if Mode /= Shown then
            MicroBit.DisplayRT.Clear;
            case Mode is
               when Stopped | Forward => MicroBit.DisplayRT.Symbols.Smile;
               when Avoiding          => MicroBit.DisplayRT.Symbols.Frown;
            end case;
            Shown := Mode;
         end if;

         Next := Next + Period;
         delay until Next;
      end loop;
   end Display;

  

   protected body State is
      procedure Set_Distance (D : Distance_cm) is
      begin
         Distance := D;
      end Set_Distance;

      function Get_Distance return Distance_cm is (Distance);

      procedure Set_Driving (On : Boolean) is
      begin
         Driving := On;
      end Set_Driving;

      function Is_Driving return Boolean is (Driving);

      procedure Set_Mode (M : Modes) is
      begin
         Mode := M;
      end Set_Mode;

      function Get_Mode return Modes is (Mode);
   end State;

end Car;
