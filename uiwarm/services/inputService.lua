local inputService = {}

local holdStatus

local hold = {
    state = false,
    time = 0,
    onDragStartTime = 6,
    drag = false,
    regTime = 0
} --mouse

hold.update = function(self)
    if self.state then
        self.time = self.time + 1
    else
        self.time = 0
        holdStatus = nil
    end
    self.drag = self.time >= self.onDragStartTime

    if self.drag then
        if self.regTime == 0 then
            self.regTime = self.time
            holdStatus = "onDragStart"
        else
            holdStatus = "onDrag"
        end
    end
    if not self.drag then
        if self.regTime ~= 0 then
            self.regTime = 0
            holdStatus = "onDragEnd"
        end
    end
end

local registerClick = function()
    hold.state = true
end

local registerRelease = function()
    hold.state = false
end

local isHold = function()
    return holdStatus
end

local update = function()
    hold:update()
end

inputService.registerClick = registerClick
inputService.registerRelease = registerRelease
inputService.isHold = isHold
inputService.update = update

return inputService
