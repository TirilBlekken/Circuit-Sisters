-- Motor_Think_Task decides what to do, Motor_Act_Task drives the wheels.
-- Both period 100 ms. Think has the higher priority, so when both are
-- released together it runs first and Act uses this period's command.
package Car.Motor is

   task Motor_Think_Task with Priority => 3;
   task Motor_Act_Task   with Priority => 2;

end Car.Motor;
