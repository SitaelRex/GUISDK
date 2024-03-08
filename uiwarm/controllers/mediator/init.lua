local staticInstance = {}

local topics = {}

local topicExist = function(topicName)
    return topics[topicName]
end

local createTopic = function(topicName)
    topics[topicName] = { queue = {}, subscribers = {} }
end

local subscribeToTopic = function(topic, func)
    topics[topic].subscribers[#topics[topic].subscribers + 1] = func
end

local invokeSubscribers = function(topic)
    for dataIndex = 1, #topics[topic].queue do
        for subscriberIndex = 1, #topics[topic].subscribers do
            topics[topic].subscribers[subscriberIndex](topics[topic].queue[dataIndex])
        end
    end
    topics[topic].queue = {} --пока не сохраняем сообщения
end

local sendData = function(topic, data)
    topics[topic].queue[#topics[topic].queue + 1] = data or "emptyData"
end

local send = function(self, topic, data)
    if not topicExist(topic) then
        createTopic(topic)
    end
    sendData(topic, data)
    invokeSubscribers(topic)
end

local subscribe = function(self, topic, invokeOnRecieveMethod)
    if not topicExist(topic) then
        createTopic(topic)
    end
    subscribeToTopic(topic, invokeOnRecieveMethod)
end

staticInstance.send = send
staticInstance.subscribe = subscribe


return staticInstance
