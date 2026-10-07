-- Withed only so their tasks start.
with Car.Sensor;  pragma Unreferenced (Car.Sensor);
with Car.Motor;   pragma Unreferenced (Car.Motor);
with Car.Display; pragma Unreferenced (Car.Display);
-- USN PROJECT TEMPLATE INTELLIGENT REAL-TIME SYSTEMS
-- Project name: [Circuit Sisters]
-- Project members: [Tiril Blekken, Yeojin Song, Marielle Langmoen]

-- All the work happens in the tasks in car-sensor, car-motor and car-display.
-- They start by themselves before Main runs.

-- Open a View > Cross Platforms > Serial Ports to see Put_Line output. Set the baud rate to 115.200
procedure Main with Priority => 0 is
begin
   loop
      null; -- Main must never finish, or the micro:bit restarts
   end loop;
end Main;
