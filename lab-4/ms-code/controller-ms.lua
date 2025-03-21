local vector = require "vector"

-- Global variables
MAX_VELOCITY = 15
VEL_THRESHOLD = 0.05
LIGHT_THRESHOLD = 0.1
PROX_THRESHOLD = 0.05
HALT_THRESHOLD = 0.1
LIGHT_IMPORTANCE = 5
PROX_IMPORTANCE = 1
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
        log("light: " .. max .. " " .. max_i)
        -- [[ Fixed distance from light source to cover for testing purposes ]]
		if first_time_light == 0 and distance(robot.positioning.position.x, robot.positioning.position.y, LIGHT_X, LIGHT_Y) <= MIN_RADIUS then
			first_time_light = 1
		end
    end

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

    if prox == true then
        return {length = (1 - max) * PROX_IMPORTANCE, angle = -robot.proximity[max_i].angle}
    end

    return {length = 0, angle = 0}
end

function set_robot_velocity(vector)
    if vector.length <= VEL_THRESHOLD then
        robot.wheels.set_velocity(MAX_VELOCITY,MAX_VELOCITY)
    else
        wheels_v = calc_wheel_velocity(vector.length, vector.angle)
        log("wheels: " .. wheels_v.v_left .. " " .. wheels_v.v_right)
        left_v = math.min(MAX_VELOCITY, wheels_v.v_left * MAX_VELOCITY)
        right_v = math.min(MAX_VELOCITY, wheels_v.v_right * MAX_VELOCITY)
        robot.wheels.set_velocity(left_v, right_v)
    end
end

function step()
    phototaxis_v = phototaxis_ps()
    obstacle_avoidance_v = obstacle_avoidance_ps()

    res_v = {length = 0, angle = 0}
    if phototaxis_v.length > 0 or obstacle_avoidance_v.length > 0 then
        res_v = vector.vec2_polar_sum(phototaxis_v, obstacle_avoidance_v)
    end

    set_robot_velocity(res_v)

    -- Increase number of steps necessary to reach the light for testing purposes
	if first_time_light > 0 and light_reached == false then
		steps_to_light = steps_to_light + 1
	end
end

-- Funzione di reset
function reset()
    robot.wheels.set_velocity(MAX_VELOCITY,MAX_VELOCITY)
    robot.leds.set_all_colors("black")
end

-- Funzione di distruzione
function destroy()
   -- Inserisci qui il tuo codice
end