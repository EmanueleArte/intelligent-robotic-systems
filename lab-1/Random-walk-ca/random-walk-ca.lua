-- Put your global variables here

MOVE_STEPS = 15
MAX_VELOCITY = 5
LIGHT_THRESHOLD = 1.5

n_steps = 0


--[[ This function is executed every time you press the 'execute'
     button ]]
function init()
	left_v = robot.random.uniform(0,MAX_VELOCITY)
	right_v = robot.random.uniform(0,MAX_VELOCITY)
	robot.wheels.set_velocity(left_v,right_v)
	n_steps = 0
	robot.leds.set_all_colors("black")
end



--[[ This function is executed at each time step
     It must contain the logic of your controller ]]
function step()
	n_steps = n_steps + 1
	if n_steps % MOVE_STEPS == 0 then
		left_v = robot.random.uniform(0,MAX_VELOCITY)
		right_v = robot.random.uniform(0,MAX_VELOCITY)
		right_v = 0
	end

	-- Search for the reading with the highest value
	value = -1 -- highest value found so far
	idx = -1   -- index of the highest value
	for i=1,#robot.proximity do
		if value < robot.proximity[i].value then
			idx = i
			value = robot.proximity[i].value
		end
	end
	-- log("robot max proximity sensor: " .. idx .. "," .. value)

	proximity_front = robot.proximity[1].value + robot.proximity[24].value
	log("robot proximity front: " .. proximity_front)
	if proximity_front > 0 then
		left_v = MAX_VELOCITY
		right_v = 0
	end

	if proximity_front > 0 then
		robot.leds.set_all_colors("red")
	else
		robot.leds.set_all_colors("black")
	end

	robot.wheels.set_velocity(left_v,right_v)

end



--[[ This function is executed every time you press the 'reset'
     button in the GUI. It is supposed to restore the state
     of the controller to whatever it was right after init() was
     called. The state of sensors and actuators is reset
     automatically by ARGoS. ]]
function reset()
	left_v = robot.random.uniform(0,MAX_VELOCITY)
	right_v = robot.random.uniform(0,MAX_VELOCITY)
	robot.wheels.set_velocity(left_v,right_v)
	n_steps = 0
	robot.leds.set_all_colors("black")
end



--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
   -- put your code here
end
