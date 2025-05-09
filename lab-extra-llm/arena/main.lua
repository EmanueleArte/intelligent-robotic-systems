MAX_SPEED = 10
PROX_THRESHOLD = 0.1

function evaluate()
    local sum = 0
    for i=1,#robot.motor_ground do
        sum = sum + robot.motor_ground[i].value
    end

    Ml = robot.wheels.velocity_left / MAX_SPEED
    Mr = robot.wheels.velocity_right / MAX_SPEED
    return (sum / 4) * (1 - (math.abs(Ml - Mr)) / 2) * math.max(0, (Ml + Mr) / 2)
end


function init()
end


function step()
    -- Read sensor values
    local left_ground = robot.motor_ground[1].value
    local right_ground = robot.motor_ground[2].value

    local base_speed = MAX_SPEED / 2
    local adjustment = MAX_SPEED / 2

    -- Obstacle Avoidance
    local obstacle_detected = false
    local left_speed = MAX_SPEED
    local right_speed = MAX_SPEED
    local left_prox = 0
    local right_prox = 0
    for i=1,#robot.proximity do
		--[[ Sum readings for left and right proximity sensors ]]
		if robot.proximity[i].value > PROX_THRESHOLD then
			if i >= 19 and i <= 24 then
				left_prox = left_prox + robot.proximity[i].value
			elseif i >= 1 and i <= 6 then
				right_prox = right_prox + robot.proximity[i].value
			end
		end
	end

	-- Action based on left proximity readings
	if left_prox > 0 then
		left_speed = -MAX_SPEED
        obstacle_detected = true
	end

	-- Action based on right proximity readings
	if right_prox > 0 then
		right_speed = -MAX_SPEED
        obstacle_detected = true
	end

    if obstacle_detected then
        robot.wheels.set_velocity(left_speed, right_speed)
    else
        -- Line Following
        if left_ground > right_ground then
            robot.wheels.set_velocity(base_speed - adjustment, base_speed + adjustment)
        elseif right_ground > left_ground then
            robot.wheels.set_velocity(base_speed + adjustment, base_speed - adjustment)
        else
            robot.wheels.set_velocity(MAX_SPEED, MAX_SPEED)
        end
    end

    log("Evaluation: " .. evaluate())
end
