-- Put your global variables here

MOVE_STEPS = 15
MAX_VELOCITY = 5
LIGHT_THRESHOLD = 0

n_steps = 0
last_light = 0

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

	--[[ Check if close to light
	(note that the light threshold depends on both sensor and actuator characteristics) ]]
	light = false
	sum = 0
	max = 0
	max_i = 0
	for i=1,#robot.light do
		if robot.light[i].value > max then
			max = robot.light[i].value
			max_i = i
		end
		sum = sum + robot.light[i].value
	end
	if sum > LIGHT_THRESHOLD then
		light = true
	end

	if light == true then
		robot.leds.set_all_colors("yellow")
		-- [[ Check if light in front is increasing or decreasing and move accordingly ]]
		if max_i == 1 or max_i == 24 then
			left_v = MAX_VELOCITY
			right_v = MAX_VELOCITY
		-- [[ If the light is decreasing, steer towards the light ]]
		elseif max_i > 1 or max_i < 13 then --[[ Go left]]
			left_v = -MAX_VELOCITY
			right_v = MAX_VELOCITY
		elseif max_i > 13 or max_i < 24 then --[[ Go right]]
			left_v = MAX_VELOCITY
			right_v = -MAX_VELOCITY
		end
		last_light = light_front
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
