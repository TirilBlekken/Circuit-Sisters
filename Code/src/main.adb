with Car;
pragma Unreferenced (Car); -- withed only so its tasks start
-- USN PROJECT TEMPLATE INTELLIGENT REAL-TIME SYSTEMS
-- Project name: [Circuit Sisters]
-- Project members: [Tiril Blekken, Yeojin Song, Marielle Langmoen]

-- All the work happens in the tasks of package Car (car.ads / car.adb).
-- They start by themselves before Main runs.

-- Open a View > Cross Platforms > Serial Ports to see Put_Line output. Set the baud rate to 115.200
procedure Main with Priority => 0 is
begin
   loop
      null; -- Main must never finish, or the micro:bit restarts
   end loop;
end Main;
