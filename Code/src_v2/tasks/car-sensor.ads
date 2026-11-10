-- Reads the two distance sensors and the buttons. Period 100 ms.

package Car.Sensor is

   task Sensor_Task
     with Priority => 4;

end Car.Sensor;
