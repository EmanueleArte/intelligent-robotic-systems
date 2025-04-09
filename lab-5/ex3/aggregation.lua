MAX_VELOCITY = 15
PSmax = 0.99
PWmin = 0.005
alpha = 0.1
beta = 0.05
MAXRANGE = 30 -- [cm]
N_STEPS = 20
PROX_THRESHOLD = 0.9
VEL_THRESHOLD = 0.01
HALT_THRESHOLD = 0.1

status = 0 -- [0: moving, 1: stopped]

function calc_PS()
    return math.min(PSmax, S + alpha * N + DS)
end

function calc_PW()
    return math.max(PWmin, W - beta * N - DW)
end

function halt()
    spot = 0
    ground = robot.motor_ground
	for i=1,4 do
		if ground[i].value < HALT_THRESHOLD then
			spot = spot + 1
		end
	end

    if spot == 4 then
        DS = 0.2
        DW = 0.3
    else
        DS = 0
        DW = 0
    end
end

-- Obstacle avoidance perceptual schema
function obstacle_avoidance_ps()
    prox = false
    sum = 0
    max = 0
    max_i = 0

    for i=1,#robot.proximity do
        if robot.proximity[i].value > PROX_THRESHOLD then
            if (i >= 19 and i <= 24) or (i >= 1 and i <= 6) then
                if robot.proximity[i].value > max then
                    max = robot.proximity[i].value
                    max_i = i
                end
                sum = sum + robot.proximity[i].value
            end
        end
    end

    if sum > 0 then
        prox = true
    end

    function adjust(angle)
        if angle < 0 then
            return angle + math.pi
        else
            return angle - math.pi
        end
    end

    if prox == true then
        return {length = max, angle = adjust(robot.proximity[max_i].angle)}
    end

    return {length = 0, angle = 0}
end

function random_rotate()
    random_rotation = robot.random.uniform(-MAX_VELOCITY, MAX_VELOCITY)
    robot.wheels.set_velocity(random_rotation, -random_rotation)
end

function calc_wheel_velocity(v, w)
    return {v_left = v + w*(-L/2), v_right = v + w*(L/2)}
end

function set_robot_velocity(vector, stop)
    if stop then
        robot.wheels.set_velocity(0, 0)
        return
    end
    -- If the vector is too small, go straight
    if vector.length <= VEL_THRESHOLD then
        if n_steps < N_STEPS then
            robot.wheels.set_velocity(MAX_VELOCITY, MAX_VELOCITY)
        elseif n_steps < N_STEPS + N_STEPS/4 then
            random_rotate()
        else
            n_steps = 0
        end
        return
    end
    -- Calculate the velocity of the wheels from the vector
    wheels_v = calc_wheel_velocity(vector.length, vector.angle)
    left_v = math.min(MAX_VELOCITY, math.max(-MAX_VELOCITY, wheels_v.v_left * MAX_VELOCITY))
    right_v = math.min(MAX_VELOCITY, math.max(-MAX_VELOCITY, wheels_v.v_right * MAX_VELOCITY))
    -- Mantain the ratio between the two wheels
    if math.abs(wheels_v.v_left) < math.abs(wheels_v.v_right) then
        left_v = left_v * math.abs(wheels_v.v_left / wheels_v.v_right)
    else
        right_v = right_v * math.abs(wheels_v.v_right / wheels_v.v_left)
    end
    robot.wheels.set_velocity(left_v, right_v)
end

-- Count the number of stopped robots sensed close to the robot
function CountRAB()
    number_robot_sensed = 0
    for i = 1, #robot.range_and_bearing do
    -- for each robot seen, check if it is close enough.
        if robot.range_and_bearing[i].range < MAXRANGE and robot.range_and_bearing[i].data[1]==1 then
            number_robot_sensed = number_robot_sensed + 1
        end
    end
    return number_robot_sensed
end


function init()
	W = 0.1
    S = 0.01
    N = 0
    n_steps = 0
    L = robot.wheels.axis_length
    DS = 0
    DW = 0
    robot.leds.set_all_colors("yellow")
end


function step()
	oa_vector = obstacle_avoidance_ps()
    N = CountRAB()
    halt()

    ps = calc_PS()
    pw = calc_PW()

    t = robot.random.uniform()
    if status == 0 then
        if t <= ps then
            status = 1
        end
    else
        if t <= pw then
            status = 0
        end
    end

    if status == 0 then
        robot.range_and_bearing.set_data(1,0)
        set_robot_velocity(oa_vector, false)
        robot.leds.set_all_colors("yellow")
    else
        robot.range_and_bearing.set_data(1,1)
        set_robot_velocity(oa_vector, true)
        robot.leds.set_all_colors("red")
    end

    n_steps = n_steps + 1
end


function reset()

end


function destroy()

end
