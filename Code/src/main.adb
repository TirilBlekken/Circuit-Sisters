
with MicroBit.MotorDriver; use MicroBit.MotorDriver;
with MicroBit.Buttons; use MicroBit.Buttons;
with MicroBit.Console; use MicroBit.Console;
use MicroBit;
-- USN PROJECT TEMPLATE INTELLIGENT REAL-TIME SYSTEMS
-- Project name: [Circuit Sisters]
-- Project members: [Tiril Blekken, Yeojin Song, Marielle Langmoen]



--This is a project template for the MicroBit v2, built against the embedded-nrf52833
--runtime (a Ravenscar/Jorvik-style profile) so we have a language-supported real-time
--OS for embedded targets. The runtime ships with the gnat_arm_elf toolchain that Alire
--installs, so there is nothing to copy by hand.

--Check out the many examples in the ADL for the MicroBit v2 to see:
--  1) How the various drivers can be used like the accelerometer,speaker  or wireless communication via radio
--  2) How ADA features like the Math library and Bounded_Vectors (Containers) can be used
--  3) How to structure your Ada tasks with a protected object to synchronize data or with entries to synchronize flow
--  4) How to perform a execution time analysis
--  5) How to integrate your Ada project with a Unity project over USB

-- Open a View > Cross Platforms > Serial Ports to see Put_Line output. Set the baud rate to 115.200
procedure Main with Priority => 0 is

begin
   Put_Line ("A for starting, B for stopping");
   loop
      if State (Button_A) = Pressed then
         Put_Line ("Driving forward");
         MotorDriver.Drive(Forward, (2000, 2000, 2000, 2000));
      elsif State (Button_B) = Pressed then
         Put_Line ("Stop");
         MotorDriver.Drive(Stop);
      end if;
      delay 0.5;
   end loop;
end Main;

    