local M, MT = {}, {}

local getmetatable = _G.getmetatable
local setmetatable = _G.setmetatable
local assert = _G.assert
local rawget = _G.rawget
local pairs = _G.pairs
local type = _G.type

local function inherit(child, parent)
	assert(type(parent) == 'table', 'Parent class must be a table')
	assert(type(child) == 'table', 'Child class must be a table')

	for key, val in pairs(parent) do
		if not child[key] then
			child[key] = val
		end
	end
end

local function instance_of(self, class)
	assert(type(self) == 'table', 'Object must be a table')
	assert(type(class) == 'table', 'Class must be a table')

	local cls = getmetatable(self)

	while cls do
		if cls == class then
			return true
		end

		cls = rawget(cls, '_super')
	end

	return false
end

local function class_of(self, object)
	if type(self) == 'table' and rawget(self, 'instance_of') then
		return self.instance_of(object, self)
	end

	return false
end

local function new_object(class, ...)
	assert(type(class) == 'table', 'Class must be a table')

	local object = setmetatable({}, class)
	object._class = class

	if rawget(class, 'init') then
		class.init(object, ...)
	end

	return object
end

local function new_class(super)
	local class = {}

	if super then
		inherit(class, super)
		class._super = super
	end

	class.__index = class
	class.instance_of = instance_of
	class.class_of = class_of
	class.new = new_object

	return class
end

function MT.__call(_, ...)
	return new_class(...)
end

setmetatable(M, MT)

return M
