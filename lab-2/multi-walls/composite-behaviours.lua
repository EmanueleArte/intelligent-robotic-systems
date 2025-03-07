-- Definisci la funzione min
function min(a, b)
    if a < b then
        return a
    else
        return b
    end
end

-- Put your global variables here

UNSTUCK_STEPS = 10
MAX_VELOCITY = 15
LIGHT_THRESHOLD = 0
PROX_THRESHOLD = 0.1
HISTORY_LENGTH = 50 -- Lunghezza della storia per rilevare il blocco

n_steps = 0
random_rotation = 0
speed = 0
multiplier = 1
history = {} -- Storia delle velocità e dei sensori
history_snapshot = 0

--[[ This function is executed every time you press the 'execute'
     button ]]
function init()
    left_v = MAX_VELOCITY
    right_v = MAX_VELOCITY
    robot.wheels.set_velocity(left_v,right_v)
    n_steps = UNSTUCK_STEPS
    speed = MAX_VELOCITY
    robot.leds.set_all_colors("black")
    history = {}
end

--[[ This function is executed at each time step
     It must contain the logic of your controller ]]
function step()
    left_prox = 0
    right_prox = 0

	-- Unstuck
    if n_steps < UNSTUCK_STEPS then
        robot.wheels.set_velocity(-MAX_VELOCITY, -MAX_VELOCITY)
        n_steps = n_steps + 1
        random_rotation = robot.random.uniform_int(UNSTUCK_STEPS, UNSTUCK_STEPS * 3)
        return
    end
    if n_steps < UNSTUCK_STEPS + random_rotation then
        robot.wheels.set_velocity(-MAX_VELOCITY, 0)
        n_steps = n_steps + 1
        return
    end

    -- Aggiungi lo stato corrente alla storia
	table.insert(history, {robot.wheels.distance_left, robot.wheels.distance_right})
	if #history > HISTORY_LENGTH then
		table.remove(history, 1)
	end

    -- Controlla se il robot è bloccato
    local stuck = false
	if #history == HISTORY_LENGTH then
		local sum = 0
		for i = 1, #history do
			sum = history[i][1] + history[i][2]
		end
		if history_snapshot >= sum - 0.2 and history_snapshot <= sum + 0.2 and sum ~= MAX_VELOCITY / 5 then
			stuck = true
			log("Stuck: " .. sum .. " " .. history_snapshot)
		end
		history_snapshot = sum
		history = {}
	end

    -- Se il robot è bloccato, attiva la routine di sblocco
    if stuck then
        robot.wheels.set_velocity(-MAX_VELOCITY, -MAX_VELOCITY)
        n_steps = n_steps + 1
        if n_steps > UNSTUCK_STEPS then
            random_rotation = robot.random.uniform_int(UNSTUCK_STEPS, UNSTUCK_STEPS * 3)
            n_steps = 0
        end
        return
    end

    for i = 1, #robot.proximity do
        --[[ Sum readings for left and right proximity sensors ]]
        if robot.proximity[i].value > PROX_THRESHOLD + min(multiplier, 0.6) then
            if i >= 19 and i <= 24 then
                left_prox = left_prox + robot.proximity[i].value
            elseif i >= 1 and i <= 6 then
                right_prox = right_prox + robot.proximity[i].value
            end
        end
    end

    stuck = 0
    -- Action based on left proximity readings
    if left_prox > 0 then
        robot.leds.set_all_colors("red")
        left_v = -left_prox * 2
        -- right_v = 0
        stuck = stuck + 1
        multiplier = 0.3
    end

    -- Action based on right proximity readings
    if right_prox > 0 then
        robot.leds.set_all_colors("red")
        -- left_v = 0
        right_v = -right_prox * 2
        stuck = stuck + 1
        multiplier = 0.3
    end

    -- If stuck because of both proximity sensors detect obstacles
    if stuck >= 2 then
        n_steps = 0
        multiplier = 0
    end

    -- Go straight if no obstacles detected
    if left_prox == 0 and right_prox == 0 then
        -- Phototaxis
        light = false
        sum = 0
        max = 0
        max_i = 0
        for i = 1, #robot.light do
            if robot.light[i].value > max then
                max = robot.light[i].value
                max_i = i
            end
            sum = sum + robot.light[i].value
        end
        if sum > LIGHT_THRESHOLD then
            light = true
        end

        multiplier = multiplier + 0.1

        if light == true then
            robot.leds.set_all_colors("yellow")
            -- [[ Check if light in front is increasing or decreasing and move accordingly ]]
            if max_i == 1 or max_i == 24 then
                left_v = min(MAX_VELOCITY, MAX_VELOCITY * multiplier)
                right_v = min(MAX_VELOCITY, MAX_VELOCITY * multiplier)
            -- [[ If the light is decreasing, steer towards the light ]]
            elseif max_i > 1 and max_i < 13 then --[[ Go left]]
                left_v = -max * MAX_VELOCITY
            elseif max_i >= 13 and max_i < 24 then --[[ Go right]]
                left_v = MAX_VELOCITY
                right_v = -max * MAX_VELOCITY
            end
        else
            robot.leds.set_all_colors("black")
            left_v = min(MAX_VELOCITY, MAX_VELOCITY * multiplier)
            right_v = min(MAX_VELOCITY, MAX_VELOCITY * multiplier)
        end
    end

    robot.wheels.set_velocity(left_v, right_v)
end

--[[ This function is executed every time you press the 'reset'
     button in the GUI. It is supposed to restore the state
     of the controller to whatever it was right after init() was
     called. The state of sensors and actuators is reset
     automatically by ARGoS. ]]
function reset()
    left_v = robot.random.uniform(0, MAX_VELOCITY)
    right_v = robot.random.uniform(0, MAX_VELOCITY)
    robot.wheels.set_velocity(left_v, right_v)
    n_steps = 0
    robot.leds.set_all_colors("black")
    history = {}
end

--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
   -- put your code here
end
