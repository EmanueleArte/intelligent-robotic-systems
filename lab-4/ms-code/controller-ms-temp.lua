MAX_VELOCITY = 15
VEL_THRESHOLD = 0.05
LIGHT_THRESHOLD = 0.1
PROX_THRESHOLD = 0.05
HALT_THRESHOLD = 0.1
LIGHT_IMPORTANCE = 5
PROX_IMPORTANCE = 1

function init()
    robot.wheels.set_velocity(MAX_VELOCITY,MAX_VELOCITY)
    robot.leds.set_all_colors("black")
    L = robot.wheels.axis_length
end

function calc_wheel_velocity(v, w)
    return {v_left = v + w*(-L/2), v_right = v + w*(L/2)}
end

-- Photonaxis perceptual schema
function phototaxis_ps()

    max = 0
    max_i = 0

    for i=1,#robot.light do
        if robot.light[i].value > LIGHT_THRESHOLD then
            if robot.light[i].value > max then
                max = robot.light[i].value
                max_i = i
            end
        end
    end

    if max > 0 then
        return {length = max, angle = robot.light[max_i].angle}
    end

    return {length = 0, angle = 0}
end

-- Obstacle avoidance perceptual schema
function obstacle_avoidance_ps()

end

function set_robot_velocity(vector)
    if vector.length <= VEL_THRESHOLD then
        robot.wheels.set_velocity(MAX_VELOCITY,MAX_VELOCITY)
    else
        wheels_v = calc_wheel_velocity(vector.length, vector.angle)
        left_v = math.min(MAX_VELOCITY, wheels_v.v_left * MAX_VELOCITY)
        right_v = math.min(MAX_VELOCITY, wheels_v.v_right * MAX_VELOCITY)
        log("wheels: " .. left_v .. " " .. right_v)
        robot.wheels.set_velocity(left_v, right_v)
    end
end

function step()
    phototaxis_v = phototaxis_ps()

    set_robot_velocity(phototaxis_v)

end

function reset()
    first_time_light = 0
    steps_to_light = 0
    light_reached = false
end

function destroy()
    -- put your code here
end