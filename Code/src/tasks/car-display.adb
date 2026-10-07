with Ada.Real_Time; use Ada.Real_Time;
with MicroBit.DisplayRT;
with MicroBit.DisplayRT.Symbols;

package body Car.Display is

   task body Display_Task is
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
   end Display_Task;

end Car.Display;
