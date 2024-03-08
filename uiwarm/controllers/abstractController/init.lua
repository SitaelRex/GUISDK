local setMediator = function(self, mediator)
    self.mediator = mediator
end

local send = function(self, topicName, data)
    self.mediator:send(topicName, data)
end

local subscribe = function(self, topicName, func)
    self.mediator:subscribe(topicName, func)
end

local configureSubscriptions = function(self)
    for subscriptionName, invokeOnMethod in pairs(self.subscriptions) do
        self:subscribe(subscriptionName, invokeOnMethod)
    end
end


local abstractController = function(self)
    local result = {}
    result.setMediator = setMediator
    result.send = send
    result.subscribe = subscribe
    result.subscriptions = {}
    result.configureSubscriptions = configureSubscriptions
    return result
end

return abstractController
