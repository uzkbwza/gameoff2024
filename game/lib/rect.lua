---@diagnostic disable: lowercase-global
Rect = Object:extend()

function Rect:new(x, y, width, height)
    self.x = x or 0
    self.y = y or 0
    self.width = width or 0
    self.height = height or 0
end

function Rect.centered(x, y, width, height)
	return Rect(x - width / 2, y - height / 2, width, height)
end

function Rect:center_to(x, y)
	self.x = x - self.width / 2
	self.y = y - self.height / 2
	return self
end

-- Define addition for rect position shift
function Rect.__add(a, b)
    return Rect(a.x + b.x, a.y + b.y, a.width, a.height)
end

-- Define subtraction for rect position shift
function Rect.__sub(a, b)
    return Rect(a.x - b.x, a.y - b.y, a.width, a.height)
end

-- Scaling by scalar
function Rect.__mul(a, b)
    if type(b) == "number" then
        return Rect(a.x, a.y, a.width * b, a.height * b)
    else
        error("Rect can only be multiplied by a scalar.")
    end
end

function Rect.__div(a, b)
    if type(b) == "number" then
        return Rect(a.x, a.y, a.width / b, a.height / b)
    else
        error("Rect can only be divided by a scalar.")
    end
end

function Rect.__eq(a, b)
    return a.x == b.x and a.y == b.y and a.width == b.width and a.height == b.height
end

function Rect:area()
    return self.width * self.height
end

function Rect:contains(point)
    return point.x >= self.x and point.x <= self.x + self.width and
           point.y >= self.y and point.y <= self.y + self.height
end

function Rect:intersects(other)
	return self.x < other.x + other.width and
		   self.x + self.width > other.x and
		   self.y < other.y + other.height and
		   self.y + self.height > other.y
end

function Rect:move(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
    return self
end

function Rect:scale(factor)
    self.width = self.width * factor
    self.height = self.height * factor
    return self
end

function Rect:clone()
    return Rect(self.x, self.y, self.width, self.height)
end

function Rect:__tostring()
    return "Rect(x=" .. self.x .. ", y=" .. self.y .. ", width=" .. self.width .. ", height=" .. self.height .. ")"
end
