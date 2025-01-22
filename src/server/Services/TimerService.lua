local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Signal = require(Knit.Util.Signal)

local TimerService = Knit.CreateService {
    Name = "TimerService",
    Client = { TimerUpdated = Knit.CreateSignal() },
}

-- Configuration
local DURATION = 30.0

-- Internal State
local timer = 0.0
local isTimerOn = false
local isTimeUp = false
local timerTask = nil -- Holds the active task for the timer loop

-- Signals
TimerService.OnTimeUp = Signal.new()

-- Helper Functions
local function resetTimer()
    timer = DURATION
    isTimerOn = false
    isTimeUp = false
end

local function timeUp()
    isTimerOn = false
    isTimeUp = true
    print("Timer has reached 0. Time is up!")
    TimerService.OnTimeUp:Fire()
    TimerService.Client.TimerUpdated:FireAll(timer, isTimeUp)
end

local function startTimerLoop()
    while isTimerOn and timer > 0 do
        task.wait(1)
        timer -= 1
        TimerService.Client.TimerUpdated:FireAll(timer, false)

        if timer <= 0 then
            timeUp()
        end
    end
end

-- Public Methods
function TimerService:StartTimer()
    if isTimerOn then
        warn("Timer is already running!")
        return
    end

    resetTimer()
    isTimerOn = true
    print("Timer started with duration: " .. tostring(DURATION))

    timerTask = task.spawn(startTimerLoop)
end

function TimerService:ContinueTimer()
    if isTimerOn then
        warn("Timer is already running!")
        return
    end

    if isTimeUp then
        warn("Cannot continue: Timer is already up!")
        return
    end

    isTimerOn = true
    print("Timer continued at: " .. tostring(timer))

    timerTask = task.spawn(startTimerLoop)
end

function TimerService:StopTimer()
    if not isTimerOn then
        warn("Timer is not running!")
        return
    end

    isTimerOn = false
    print("Timer stopped at: " .. tostring(timer))
end

function TimerService:IsTimeUp()
    return isTimeUp
end

function TimerService:GetRemainingTime()
    return timer
end

-- Client Method Example
function TimerService.Client:GetTimer(player)
    return timer
end

return TimerService
