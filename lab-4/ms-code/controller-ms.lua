local vector = require "vector"

MAX_VELOCITY = 15
VEL_THRESHOLD = 0.01
LIGHT_THRESHOLD = 0.1
PROX_THRESHOLD = 0.05
LIGHT_IMPORTANCE = 5
PROX_IMPORTANCE = 1
LIGHT_REACHED = 0.2
LIGHT_X = 2
LIGHT_Y = 0
MIN_RADIUS = 4.7

first_time_light = 0
steps_to_light = 0
light_reached = false


function init()
    robot.wheels.set_velocity(MAX_VELOCITY,MAX_VELOCITY)
    robot.leds.set_all_colors("black")
    L = robot.wheels.axis_length
end

function distance(x1, y1, x2, y2)
    return math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
end

function calc_wheel_velocity(v, w)
    return {v_left = v + w*(-L/2), v_right = v + w*(L/2)}
end

-- Photonaxis perceptual schema
function phototaxis_ps()
    light = false
    sum = 0
    max = 0
    max_i = 0

    -- Check if the light is detected and what sensor is detecting it with the highest value
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
        -- [[ Fixed distance from light source to cover for testing purposes ]]
		if first_time_light == 0 and distance(robot.positioning.position.x, robot.positioning.position.y, LIGHT_X, LIGHT_Y) <= MIN_RADIUS then
			first_time_light = 1
		end
    end

    -- If the light is detected, calculate the vector to move towards it
    if light == true then
        return {length = max * LIGHT_IMPORTANCE, angle = robot.light[max_i].angle}
    end

    return {length = 0, angle = 0}
end

-- Obstacle avoidance perceptual schema
function obstacle_avoidance_ps()
    prox = false
    sum = 0
    max = 0
    max_i = 0

    -- Check if an obstacle is detected and what sensor is detecting it with the highest value
    for i=1,#robot.proximity do
        if robot.proximity[i].value > PROX_THRESHOLD then
            if (i >= 20 and i <= 24) or (i >= 1 and i <= 5) then
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

    -- If an obstacle is detected, calculate the vector to move away from it
    if prox == true then
        return {length = (1 - max) * PROX_IMPORTANCE, angle = -robot.proximity[max_i].angle}
    end

    return {length = 0, angle = 0}
end

function set_robot_velocity(vector)
    -- If the vector is too small, generate a new random vector
    if vector.length <= VEL_THRESHOLD then
        vector.length = robot.random.uniform(VEL_THRESHOLD, LIGHT_IMPORTANCE + PROX_IMPORTANCE)
        vector.angle = robot.random.uniform(-math.pi, math.pi)
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


function step()
    phototaxis_v = phototaxis_ps()
    obstacle_avoidance_v = obstacle_avoidance_ps()

    res_v = {length = 0, angle = 0}
    -- Sum the vectors from the two perceptual schemas if they are valid
    if phototaxis_v.length > 0 or obstacle_avoidance_v.length > 0 then
        res_v = vector.vec2_polar_sum(phototaxis_v, obstacle_avoidance_v)
    end

    set_robot_velocity(res_v)

    -- Increase number of steps necessary to reach the light for testing purposes
	if first_time_light > 0 and light_reached == false then
		steps_to_light = steps_to_light + 1
	end
    if distance(robot.positioning.position.x, robot.positioning.position.y, LIGHT_X, LIGHT_Y) < LIGHT_REACHED and first_time_light > 0 then
		log("Steps necessary to reach light: " .. steps_to_light .. " with distance: " .. MIN_RADIUS)
		first_time_light = -1
	end
end


function reset()
    robot.wheels.set_velocity(MAX_VELOCITY,MAX_VELOCITY)
    robot.leds.set_all_colors("black")
end


function destroy()
   -- Inserisci qui il tuo codice
end