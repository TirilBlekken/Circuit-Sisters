with Ada.Execution_Time;
use type Ada.Execution_Time.CPU_Time;
with Ada.Real_Time;        use Ada.Real_Time;
with MicroBit.MotorDriver; use MicroBit.MotorDriver;
with MicroBit.Console;     use MicroBit.Console;
use MicroBit;


-- Motor control for the car
package body Car.Motor is
   -- the speed to each wheel, why two? feature modifications??:)))
   Drive_Speed : constant Speeds :=
     (rf => 4095, rb => 4095, lf => 4095, lb => 4095);
   Turn_Speed  : constant Speeds :=
     (rf => 4095, rb => 4095, lf => 4095, lb => 4095);

   -- What Think has decided and Act should do. Direction and speed in one
   -- call, so Act never gets a new direction together with an old speed
   protected Command is
      procedure Set (Direction : Directions; Speed : Speeds);
      procedure Get (Direction : out Directions; Speed : out Speeds);
   private
      Current_Direction : Directions := Stop;
      Current_Speed     : Speeds := Drive_Speed;
   end Command;

   protected body Command is
      procedure Set (Direction : Directions; Speed : Speeds) is
      begin
         Current_Direction := Direction;
         Current_Speed := Speed;
      end Set;

      procedure Get (Direction : out Directions; Speed : out Speeds) is
      begin
         Direction := Current_Direction;
         Speed := Current_Speed;
      end Get;
   end Command;
   -- we had this:
   --function Room (D : Distance_cm) return Distance_cm
   --is (if D < 2 then Distance_cm'Last else D);

   task body Motor_Think_Task is
      Period      : constant Time_Span := Milliseconds (100);
      Next        : Time := Clock;
      D           : Distances;
      Brake_Ticks : Natural := 0;
      Turn        : Directions := Rotating_Right;
      Last_Mode   : Modes := Avoiding;

      -- Measuring C (execution time) for the response time analysis, and uses the cpu time package to measure the time it takes to run the task.
      Start_C : Ada.Execution_Time.CPU_Time;
      Used_C  : Time_Span;
      Max_C   : Time_Span := Time_Span_Zero; -- the largest C seen so far
      Rounds  : Natural := 0; -- print Max_C every 10 rounds = 1000 ms
   
   
   begin
   --THINK task, the brain of the car, deciding what to do based on modes and distances
      loop
      -- starts measuring
         Start_C := Ada.Execution_Time.Clock;
         D := State.Get_Distances;

      -- if the car is not driving, it should stop
         if not State.Is_Driving then
            State.Set_Mode (Stopped);
            Command.Set (Stop, Drive_Speed);

      -- if the car is driving, it should check if there is an obstacle in front of it, and if there is, it should turn away from it
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
      -- obstacle detected, so the car should stop and turn away from it, and it should do this for 3 ticks, which is 300 ms
               State.Set_Mode (Avoiding);
               Brake_Ticks := 3;

            end if;
      -- if the car is avoiding an obstacle, it should turn away from it for 3 ticks, which is 300 ms, and then it should go forward again
            if Brake_Ticks > 0 then
               Brake_Ticks := Brake_Ticks - 1;
               Command.Set (Stop, Drive_Speed);
            else
               Command.Set (Turn, Turn_Speed);
            end if;

         else
            State.Set_Mode (Forward);
            Command.Set (Forward, Drive_Speed);
         end if;

         if State.Get_Mode /= Last_Mode then
            Last_Mode := State.Get_Mode;
            Log.Put_Line ("Mode: " & Last_Mode'Image);
         end if;

         -- Print C regulary, every 10th round, if not, the first rounds are usually before the serial monitor is connected, and then the first print is lost. 

         Rounds := Rounds + 1;
         if Rounds >= 10 then
            Rounds := 0;
            Log.Put_Line ("Motor think max C:" & Integer'Image (Max_C / Microseconds (1)) & " us");
         end if;

         -- C for this round: CPU time used since Start_C. Keep the largest;
         -- that is the WCET to use in the analysis.
         Used_C := Ada.Execution_Time.Clock - Start_C;
         if Used_C > Max_C then
            Max_C := Used_C;
         end if;


         -- the task should run every 100 ms, so it should wait until the next tick before running again
         Next := Next + Period;
         delay until Next;
      end loop;
   end Motor_Think_Task;

   task body Motor_Act_Task is
      Period    : constant Time_Span := Milliseconds (100);
      Next      : Time := Clock;
      Direction : Directions;
      Speed     : Speeds;
      -- Measuring C (execution time) for the response time analysis.
      Start_C : Ada.Execution_Time.CPU_Time;
      Used_C  : Time_Span;
      Max_C   : Time_Span := Time_Span_Zero; -- the largest C seen so far
      Rounds  : Natural := 0; -- print Max_C every 10 rounds = 1000 ms





   -- ACT task, which takes the decisions from the THINK task and executes them, by sending the commands to the motor driver
   begin
      loop
         Start_C := Ada.Execution_Time.Clock;

         Command.Get (Direction, Speed);
         MotorDriver.Drive (Direction, Speed);

         -- Printed before C is measured, for the same reason as in Think.
         Rounds := Rounds + 1;
         if Rounds >= 10 then
            Rounds := 0;
            Log.Put_Line ("Motor act max C:" & Integer'Image (Max_C / Microseconds (1)) & " us");
         end if;

         Used_C := Ada.Execution_Time.Clock - Start_C;
         if Used_C > Max_C then
            Max_C := Used_C;
         end if;

         Next := Next + Period;
         delay until Next;
      end loop;
   end Motor_Act_Task;

end Car.Motor;
