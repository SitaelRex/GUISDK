local stateMachine = {}

local setState = function(self, stateName)

end

local definestateMachine = function(self, elementRef)
    local result = {}

    result.stateMachines = {

    }
    return result
end

local completeBuilder = function(smBuilder)
    local smName = smBuilder.smName
    local states = smBuilder.states
    local triggers = smBuilder.triggers
end

local intersect = function(t, v)
    for k, tv in pairs(t) do
        if tv == v then return true end
    end
    return false
end

stateMachine.defStateMachine = function(self, smName, states, triggers)
    assert(type(states) == "table", "states must be a table")
    assert(type(triggers) == "table", "triggers must be a table")
    local result = {}
    result.states = states
    result.currentState = result.states[1]
    result.triggers = {}
    local element = self.elementRef
    local uiApi = self.uiApiRef.a

    for _, trigger in pairs(triggers) do
        local name = trigger.varName
        local startValue = trigger.varValue
        local transitionFrom = trigger.transition[1]
        local transitionTo = trigger.transition[2]
        local condition = trigger.condition -- always ==
        local emitValue = trigger.emitOnValue
        local callback = trigger.callback

        local triggerInfo = {
            name = name,
            startValue = startValue,
            transitionFrom = transitionFrom,
            transitionTo = transitionTo,
            condition = condition,
            emitValue = emitValue,
            callback = callback
        }
        result.triggers[name] = triggerInfo

        local triggerVariable = {
            value = startValue,
            get = function(self)
                return self.value
            end,
            set = function(self, value)
                print("sm", transitionFrom, result.currentState)
                self.value = value

                if intersect(transitionFrom, result.currentState) then
                    if condition == "equals" and self.value == emitValue then
                        result.currentState = transitionTo
                        self.value = startValue
                        result.triggers[name].callback(element, uiApi)
                    end
                end
            end,
        }

        element.variables:set(name, triggerVariable)
    end

    --user-friendly переключение стейта
    result.transitTo = function(self, stateName)
        local currentState = self.currentState
        local triggers = self.triggers
        for triggerName, trigger in pairs(triggers) do
            local fromStates = trigger.transitionFrom
            local toState = trigger.transitionTo
            if intersect(fromStates, currentState) and toState == stateName then
                local variableName = trigger.name
                local emitValue = trigger.emitValue
                element.variables:set(triggerName, emitValue)
            end
        end
    end

    self.stateMachines[smName] = result
end

setmetatable(stateMachine, { __call = definestateMachine })
return stateMachine
