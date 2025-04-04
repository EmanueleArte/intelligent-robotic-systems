MAX_VELOCITY = 15
PsMAX = 0.99
PwMIN = 0.005
alpha = 0.1
beta = 0.05
MAX_BEARING_RANGE = 30 -- cm
N_STEPS = 20
PROX_THRESHOLD = 0
VEL_THRESHOLD = 0.01
L = robot.wheels.axis_length

function calc_Ps()
    return math.min(PsMAX, S + alpha * N)
end

function calc_Pw()
    return math.max(PwMIN, W - beta * N)
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

    if prox == true then
        return {length = (1 - max), angle = -robot.proximity[max_i].angle}
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

function set_robot_velocity(vector)
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


function init()
	W = 0.1
    S = 0.01
    N = 0
    n_steps = 0
end


function step()
	oa_vector = obstacle_avoidance_ps()

    set_robot_velocity(oa_vector)

    n_steps = n_steps + 1
end


function reset()

end


function destroy()

end
