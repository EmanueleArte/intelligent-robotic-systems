-- Definisci la funzione min
function min(a, b)
    if a < b then
        return a
    else
        return b
    end
end

-- Put your global variables here

UNSTUCK_STEPS = 5
MAX_VELOCITY = 15
LIGHT_THRESHOLD = 0.05
PROX_THRESHOLD = 0.1

n_steps = 0
random_rotation = 0
n_ignore = 0
multiplier = 1

--[[ This function is executed every time you press the 'execute'
     button ]]
function init()
	left_v = MAX_VELOCITY
	right_v = MAX_VELOCITY
	robot.wheels.set_velocity(left_v,right_v)
	n_steps = UNSTUCK_STEPS
	n_ignore = 5
	robot.leds.set_all_colors("black")
end



--[[ This function is executed at each time step
     It must contain the logic of your controller ]]
function step()
	left_prox = 0
	right_prox = 0

	-- Unstuck
	if n_steps < UNSTUCK_STEPS then
		robot.wheels.set_velocity(-MAX_VELOCITY,0)
		n_steps = n_steps + 1
		random_rotation = robot.random.uniform_int(UNSTUCK_STEPS,UNSTUCK_STEPS * 3)
		return
	end

	for i=1,#robot.proximity do
		--[[ Sum readings for left and right proximity sensors ]]
		if robot.proximity[i].value > PROX_THRESHOLD + min(multiplier, 0.6) then
			if i >= 20 and i <= 24 then
				right_prox = right_prox + robot.proximity[i].value
			elseif i >= 1 and i <= 5 then
				left_prox = left_prox + robot.proximity[i].value
			end
		end
	end

	stuck = 0
	-- Action based on left proximity readings
	if left_prox > 0 then
		robot.leds.set_all_colors("red")
		right_v = -left_prox
		stuck = stuck + 1
		multiplier = 0.3
		n_ignore = 0
	end

	-- Action based on right proximity readings
	if right_prox > 0 then
		robot.leds.set_all_colors("red")
		left_v = -right_prox
		stuck = stuck + 1
		multiplier = 0.3
		n_ignore = 0
	end

	-- If stuck becuase of both proximity sensors detect obstacles
	if stuck >= 2 then
		n_steps = 0
		multiplier = 0
	end

	-- Go straight if no obstacles detected
	if stuck == 0 then
		-- Phototaxis
		light = false
		sum = 0
		max = 0
		max_i = 0
		for i=1,#robot.light do
			if robot.light[i].value > LIGHT_THRESHOLD then
				if robot.light[i].value > max then
					max = robot.light[i].value
					max_i = i
				end
				sum = sum + robot.light[i].value
			end
		end
		if sum > 0 then
			light = true
		end

		multiplier = multiplier + 0.1

		if light == true and n_ignore > UNSTUCK_STEPS then
			robot.leds.set_all_colors("yellow")
			-- [[ Check if light in front is increasing or decreasing and move accordingly ]]
			if max_i == 1 or max_i == 24 then
				left_v = min(MAX_VELOCITY,MAX_VELOCITY * multiplier)
				right_v = min(MAX_VELOCITY,MAX_VELOCITY * multiplier)
			-- [[ If the light is decreasing, steer towards the light ]]
			elseif max_i > 1 and max_i < 13 then --[[ Go left]]
				left_v = -max * MAX_VELOCITY
			elseif max_i >= 13 and max_i < 24 then --[[ Go right]]
				left_v = MAX_VELOCITY
				right_v = -max * MAX_VELOCITY
			end
		else
			robot.leds.set_all_colors("black")
			left_v = min(MAX_VELOCITY,MAX_VELOCITY * multiplier)
			right_v = min(MAX_VELOCITY,MAX_VELOCITY * multiplier)
		end
	end

	robot.wheels.set_velocity(left_v,right_v)
	n_ignore = n_ignore + 1

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
	n_ignore = 5
	robot.leds.set_all_colors("black")
end



--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
   -- put your code here
end
