-- Utility functions
function min(a, b)
    if a < b then
        return a
    else
        return b
    end
end

function distance(x1, y1, x2, y2)
    return math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
end

-- Global variables
UNSTUCK_STEPS = 5
MAX_VELOCITY = 15
LIGHT_THRESHOLD = 0.01
PROX_THRESHOLD = 0.05
HALT_THRESHOLD = 0.1
LIGHT_X = 0
LIGHT_Y = 0

n_steps = 0
n_ignore = 0
multiplier = 1

first_time_light = 0
steps_to_light = 0

function init()
    left_v = MAX_VELOCITY
    right_v = MAX_VELOCITY
    robot.wheels.set_velocity(left_v,right_v)
    n_steps = UNSTUCK_STEPS
    n_ignore = UNSTUCK_STEPS
    robot.leds.set_all_colors("black")
end

-- Halt compentency
function halt(suppress)
    if suppress == true then
        return suppress
    end
    spot = 0
    ground = robot.motor_ground
	for i=1,4 do
		if ground[i].value < HALT_THRESHOLD then
			spot = spot + 1
		end
	end

    if spot == 4 then
        log("halt")
        robot.leds.set_all_colors("green")
        left_v = 0
        right_v = 0
        return true
    end

    return suppress
end

-- Phototaxis compentency
function phototaxis(suppress)
    if suppress == true or n_ignore < UNSTUCK_STEPS then
        return suppress
    end
    log("phototaxis")
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
        if first_time_light == 0 then
            first_time_light = distance(robot.positioning.position.x, robot.positioning.position.y, LIGHT_X, LIGHT_Y)
        end
    end

    if light == true then
        robot.leds.set_all_colors("yellow")
        if max_i == 1 or max_i == 24 then
            left_v = min(MAX_VELOCITY,MAX_VELOCITY * multiplier)
            right_v = min(MAX_VELOCITY,MAX_VELOCITY * multiplier)
        elseif max_i > 1 and max_i < 13 then
            left_v = -max * MAX_VELOCITY
        elseif max_i >= 13 and max_i < 24 then
            left_v = MAX_VELOCITY
            right_v = -max * MAX_VELOCITY
        end
        return suppress, true
    end

    return suppress
end

-- Unstuck compentency
function unstuck(suppress)
    if suppress == true then
        return suppress
    end
    if n_steps < UNSTUCK_STEPS then
        log("unstuck")
		robot.wheels.set_velocity(-MAX_VELOCITY,0)
		n_steps = n_steps + 1
        return true
	end
    return suppress
end

-- Collision avoidance compentency
function avoid_obstacles(suppress)
    if suppress == true then
        return suppress
    end
    left_prox = 0
    right_prox = 0
    stuck = 0

    for i=1,#robot.proximity do
        if robot.proximity[i].value > PROX_THRESHOLD + min(multiplier, 0.6) then
            if i >= 20 and i <= 24 then
                right_prox = right_prox + robot.proximity[i].value
            elseif i >= 1 and i <= 5 then
                left_prox = left_prox + robot.proximity[i].value
            end
        end
    end

    function set_values()
        n_ignore = 0
        multiplier = 0.2
        suppress = true
    end

    if left_prox > 0 then
        log("avoid obstacles left")
        robot.leds.set_all_colors("red")
        right_v = -left_prox
        set_values()
    elseif right_prox > 0 then
        log("avoid obstacles right")
        robot.leds.set_all_colors("red")
        left_v = -right_prox
        set_values()
    end

    -- If stuck becuase of both proximity sensors detect obstacles
	if stuck >= 2 then
		n_steps = 0
	end

    return suppress
end

-- Go straight compentency
function go_straight(suppress)
    if suppress == true then
        return suppress
    end
    left_v = min(MAX_VELOCITY,MAX_VELOCITY * multiplier)
    right_v = min(MAX_VELOCITY,MAX_VELOCITY * multiplier)
    return suppress
end

-- Apply movement
function move()
    robot.wheels.set_velocity(left_v, right_v)
end

function step()
    suppress = false

    suppress = halt(suppress) -- [[ Level 4 ]]
    suppress, suppress_0 = phototaxis(suppress) -- [[ Level 3 ]]
    suppress = unstuck(suppress) -- [[ Level 2 ]]
    suppress = avoid_obstacles(suppress) -- [[ Level 1 ]]
    suppress = go_straight(suppress or suppress_0) -- [[ Level 0 ]]
    move()

    n_ignore = n_ignore + 1
    multiplier = multiplier + 0.1
end

-- Funzione di reset
function reset()
    left_v = robot.random.uniform(0,MAX_VELOCITY)
    right_v = robot.random.uniform(0,MAX_VELOCITY)
    robot.wheels.set_velocity(left_v,right_v)
    n_steps = UNSTUCK_STEPS
    n_ignore = UNSTUCK_STEPS
    robot.leds.set_all_colors("black")
end

-- Funzione di distruzione
function destroy()
   -- Inserisci qui il tuo codice
end