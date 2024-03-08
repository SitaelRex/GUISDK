local trigger = function(name)
    local triggerBuilder = {
        varName = name,
        startValue = 0,
        transition = {},
        condition = "equals",
        emitValue = 1,
        callback = function() end
    }

    triggerBuilder.setStartValue = function(self, value)
        self.varValue = value
        return self
    end

    triggerBuilder.from = function(self, ...)
        self.transition[1] = { ... }
        return self
    end

    triggerBuilder.to = function(self, to)
        self.transition[2] = to
        return self
    end

    triggerBuilder.setCondition = function(self, condition)
        self.condition = condition
        return self
    end

    triggerBuilder.emitOn = function(self, value)
        self.emitValue = value
        return self
    end

    triggerBuilder.defCallback = function(self, func, params)
        self.callback = function(self, uiApi)
           return func(self, params, uiApi)
        end
        return self
    end

    triggerBuilder.complete = function(self)
        return self
    end

    return triggerBuilder
end

local stateMachine = function(name)
    local stateMachineBuilder = {}
    stateMachineBuilder = { name = name, states = {}, triggers = {} }

    stateMachineBuilder.addState = function(self, name)
        self.states[#self.states + 1] = name
        return self
    end

    stateMachineBuilder.addTrigger = function(self, trigger)
        self.triggers[#self.triggers + 1] = trigger
        return self
    end
    stateMachineBuilder.complete = function(self)
        return self.name, self.states, self.triggers
    end
    return stateMachineBuilder
end


return { stateMachine = stateMachine, trigger = trigger }
