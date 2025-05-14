UNSTUCK_STEPS = 10
MAX_VELOCITY = 5

n_steps = 0

function init()
	left_v = MAX_VELOCITY
	right_v = MAX_VELOCITY
	robot.wheels.set_velocity(left_v,right_v)
	n_steps = UNSTUCK_STEPS
	robot.leds.set_all_colors("black")
end


function step()
	left_prox = 0
	right_prox = 0

	-- Rotate to unstuck
	if n_steps < UNSTUCK_STEPS then
		n_steps = n_steps + 1
		return
	end

	for i=1,#robot.proximity do
		--[[ Sum readings for left and right proximity sensors ]]
		if i >= 19 and i <= 24 then
			left_prox = left_prox + robot.proximity[i].value
		elseif i >= 1 and i <= 6 then
			right_prox = right_prox + robot.proximity[i].value
		end
	end

	stuck = 0
	-- Action based on left proximity readings
	if left_prox > 0 then
		robot.leds.set_all_colors("red")
		left_v = -left_prox
		stuck = stuck + 1
	end

	-- Action based on right proximity readings
	if right_prox > 0 then
		robot.leds.set_all_colors("red")
		right_v = -right_prox
		stuck = stuck + 1
	end

	-- If stuck becuase of both proximity sensors detect obstacles
	if stuck >= 2 then
		left_v = -MAX_VELOCITY
		right_v = MAX_VELOCITY
		n_steps = 0
	end

	-- Go straight if no obstacles detected
	if left_prox == 0 and right_prox == 0 then
		robot.leds.set_all_colors("black")
		left_v = MAX_VELOCITY
		right_v = MAX_VELOCITY
	end

	robot.wheels.set_velocity(left_v,right_v)

end


function reset()
	left_v = robot.random.uniform(0,MAX_VELOCITY)
	right_v = robot.random.uniform(0,MAX_VELOCITY)
	robot.wheels.set_velocity(left_v,right_v)
	n_steps = 0
	robot.leds.set_all_colors("black")
end


function destroy()
   -- put your code here
end
